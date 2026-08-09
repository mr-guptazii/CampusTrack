import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/attendance_record.dart';
import '../repositories/firebase_repository.dart';
import '../repositories/local_repository.dart';
import '../core/services/connectivity_service.dart';
import '../core/utils/date_utils.dart';
import 'subject_provider.dart';

/// Marks attendance and keeps AttendanceRecord history. Whenever a record is
/// created/edited/removed it also applies the corresponding delta to the
/// linked [SubjectProvider] subject's attended/total counts, so percentages
/// stay in sync without a separate recompute pass.
class AttendanceProvider extends ChangeNotifier {
  AttendanceProvider();

  final _uuid = const Uuid();
  List<AttendanceRecord> _records = [];
  SubjectProvider? _subjectProvider;
  StreamSubscription<bool>? _connectivitySub;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  List<AttendanceRecord> get records => List.unmodifiable(_records);

  void attachSubjectProvider(SubjectProvider provider) {
    _subjectProvider = provider;
  }

  Future<void> init() async {
    _records = LocalRepository.instance.getAttendanceRecords();
    notifyListeners();
    _connectivitySub ??= ConnectivityService.instance.onStatusChange.listen((online) {
      if (online) syncWithRemote();
    });
    await syncWithRemote();
  }

  List<AttendanceRecord> forSubject(String subjectId) =>
      _records.where((r) => r.subjectId == subjectId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  List<AttendanceRecord> forDate(DateTime date) => _records
      .where((r) => AppDateUtils.isSameDay(r.date, date))
      .toList();

  /// Attendance trend for the last [days] days: date -> percentage that day
  /// (based on cumulative attended/total up to and including that day).
  Map<DateTime, double> lastNDaysTrend(int days) {
    final dates = AppDateUtils.lastNDays(days);
    final sorted = [..._records]..sort((a, b) => a.date.compareTo(b.date));
    final Map<DateTime, double> result = {};
    for (final day in dates) {
      final upToDay = sorted.where((r) =>
          r.date.isBefore(day.add(const Duration(days: 1))) && r.status.countsTowardsTotal);
      final total = upToDay.length;
      final attended = upToDay.where((r) => r.status.countsAsAttended).length;
      result[day] = total == 0 ? 0 : (attended / total) * 100;
    }
    return result;
  }

  int currentStreak() {
    final sorted = [..._records]..sort((a, b) => b.date.compareTo(a.date));
    int streak = 0;
    DateTime? cursor;
    for (final r in sorted) {
      if (!r.status.countsAsAttended) break;
      final day = AppDateUtils.startOfDay(r.date);
      if (cursor == null || cursor.difference(day).inDays <= 1) {
        streak++;
        cursor = day;
      } else {
        break;
      }
    }
    return streak;
  }

  Map<AttendanceStatus, int> statusBreakdown() {
    final map = {for (final s in AttendanceStatus.values) s: 0};
    for (final r in _records) {
      map[r.status] = (map[r.status] ?? 0) + 1;
    }
    return map;
  }

  Future<void> markAttendance({
    required String subjectId,
    required DateTime date,
    required AttendanceStatus status,
    String? note,
    String? existingRecordId,
  }) async {
    // If a record already exists for this subject+date, replace it and undo
    // its previous delta first.
    final existing = existingRecordId != null
        ? _records.where((r) => r.id == existingRecordId).firstOrNull
        : _records.where((r) => r.subjectId == subjectId && AppDateUtils.isSameDay(r.date, date)).firstOrNull;

    if (existing != null) {
      await _revertDelta(existing);
      _records = _records.where((r) => r.id != existing.id).toList();
    }

    final record = AttendanceRecord(
      id: existing?.id ?? _uuid.v4(),
      subjectId: subjectId,
      date: date,
      status: status,
      timestamp: DateTime.now(),
      note: note,
    );
    _records = [..._records, record];
    notifyListeners();

    await _applyDelta(record);
    await _persist(record);
  }

  Future<void> deleteRecord(String recordId) async {
    final record = _records.where((r) => r.id == recordId).firstOrNull;
    if (record == null) return;
    await _revertDelta(record);
    _records = _records.where((r) => r.id != recordId).toList();
    notifyListeners();
    await LocalRepository.instance.deleteAttendanceRecord(recordId);
    final uid = _uid;
    if (uid != null && await ConnectivityService.instance.checkNow()) {
      await FirebaseRepository.instance.deleteAttendance(uid, recordId);
    }
  }

  Future<void> _applyDelta(AttendanceRecord record) async {
    if (!record.status.countsTowardsTotal) return;
    await _subjectProvider?.applyAttendanceDelta(
      record.subjectId,
      attendedDelta: record.status.countsAsAttended ? 1 : 0,
      totalDelta: 1,
    );
  }

  Future<void> _revertDelta(AttendanceRecord record) async {
    if (!record.status.countsTowardsTotal) return;
    await _subjectProvider?.applyAttendanceDelta(
      record.subjectId,
      attendedDelta: record.status.countsAsAttended ? -1 : 0,
      totalDelta: -1,
    );
  }

  Future<void> _persist(AttendanceRecord record) async {
    await LocalRepository.instance.putAttendanceRecord(record);
    final uid = _uid;
    if (uid == null) return;
    if (await ConnectivityService.instance.checkNow()) {
      await FirebaseRepository.instance.upsertAttendance(uid, record);
    } else {
      await LocalRepository.instance.queueForSync('attendance', record.id, record.toJson());
    }
  }

  Future<void> syncWithRemote() async {
    final uid = _uid;
    if (uid == null) return;
    if (!await ConnectivityService.instance.checkNow()) return;
    try {
      final remote = await FirebaseRepository.instance.fetchAttendance(uid);
      final byId = {for (final r in _records) r.id: r};
      for (final r in remote) {
        final localVersion = byId[r.id];
        if (localVersion == null || r.timestamp.isAfter(localVersion.timestamp)) {
          byId[r.id] = r;
          await LocalRepository.instance.putAttendanceRecord(r);
        }
      }
      _records = byId.values.toList();
      notifyListeners();

      for (final local in _records) {
        final existsRemotely = remote.any((r) => r.id == local.id);
        if (!existsRemotely) {
          await FirebaseRepository.instance.upsertAttendance(uid, local);
        }
      }
    } catch (_) {
      // keep local cache
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
