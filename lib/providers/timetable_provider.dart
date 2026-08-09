import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/timetable_entry.dart';
import '../repositories/firebase_repository.dart';
import '../repositories/local_repository.dart';
import '../core/services/connectivity_service.dart';
import '../core/utils/date_utils.dart';

class TimetableProvider extends ChangeNotifier {
  TimetableProvider() {
    _entries = LocalRepository.instance.getTimetableEntries();
    _connectivitySub = ConnectivityService.instance.onStatusChange.listen((online) {
      if (online) syncWithRemote();
    });
    syncWithRemote();
  }

  final _uuid = const Uuid();
  List<TimetableEntry> _entries = [];
  StreamSubscription<bool>? _connectivitySub;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  List<TimetableEntry> get entries => List.unmodifiable(_entries);

  List<TimetableEntry> forDay(Weekday day) {
    final list = _entries.where((e) => e.day == day).toList();
    list.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    return list;
  }

  List<TimetableEntry> todayEntries() => forDay(WeekdayX.fromDateTime(DateTime.now()));

  TimetableEntry? currentOngoing() {
    final now = DateTime.now();
    for (final e in todayEntries()) {
      if (e.isOngoingAt(now)) return e;
    }
    return null;
  }

  TimetableEntry? nextUpcomingToday() {
    final now = DateTime.now();
    final upcoming = todayEntries().where((e) => e.isUpcomingToday(now)).toList()
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  Future<void> addEntry({
    required Weekday day,
    required String subjectId,
    required String startTime,
    required String endTime,
    required String room,
  }) async {
    final entry = TimetableEntry(
      id: _uuid.v4(),
      day: day,
      subjectId: subjectId,
      startTime: startTime,
      endTime: endTime,
      room: room,
    );
    _entries = [..._entries, entry];
    notifyListeners();
    await _persist(entry);
  }

  Future<void> updateEntry(TimetableEntry entry) async {
    _entries = _entries.map((e) => e.id == entry.id ? entry : e).toList();
    notifyListeners();
    await _persist(entry);
  }

  Future<void> deleteEntry(String id) async {
    _entries = _entries.where((e) => e.id != id).toList();
    notifyListeners();
    await LocalRepository.instance.deleteTimetableEntry(id);
    final uid = _uid;
    if (uid != null && await ConnectivityService.instance.checkNow()) {
      await FirebaseRepository.instance.deleteTimetableEntry(uid, id);
    }
  }

  Future<void> _persist(TimetableEntry entry) async {
    await LocalRepository.instance.putTimetableEntry(entry);
    final uid = _uid;
    if (uid == null) return;
    if (await ConnectivityService.instance.checkNow()) {
      await FirebaseRepository.instance.upsertTimetableEntry(uid, entry);
    } else {
      await LocalRepository.instance.queueForSync('timetable', entry.id, entry.toJson());
    }
  }

  Future<void> syncWithRemote() async {
    final uid = _uid;
    if (uid == null) return;
    if (!await ConnectivityService.instance.checkNow()) return;
    try {
      final remote = await FirebaseRepository.instance.fetchTimetable(uid);
      final ids = {for (final e in _entries) e.id: e};
      for (final r in remote) {
        ids[r.id] = r;
        await LocalRepository.instance.putTimetableEntry(r);
      }
      _entries = ids.values.toList();
      notifyListeners();
      for (final local in _entries) {
        final existsRemotely = remote.any((r) => r.id == local.id);
        if (!existsRemotely) {
          await FirebaseRepository.instance.upsertTimetableEntry(uid, local);
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
