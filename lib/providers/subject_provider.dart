import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/subject.dart';
import '../repositories/firebase_repository.dart';
import '../repositories/local_repository.dart';
import '../core/services/connectivity_service.dart';
import '../core/constants/app_constants.dart';

/// Offline-first subject list. Reads/writes hit Hive immediately (so the UI
/// never blocks on network); Firestore is synced opportunistically whenever
/// connectivity is available. Conflicts are resolved by comparing
/// [Subject.updatedAt] and keeping the newer record.
class SubjectProvider extends ChangeNotifier {
  SubjectProvider() {
    _loadFromCache();
    _connectivitySub = ConnectivityService.instance.onStatusChange.listen((online) {
      if (online) syncWithRemote();
    });
  }

  final _uuid = const Uuid();
  List<Subject> _subjects = [];
  bool isLoading = false;
  String searchQuery = '';
  StreamSubscription<bool>? _connectivitySub;
  StreamSubscription<List<Subject>>? _remoteSub;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  List<Subject> get subjects {
    if (searchQuery.isEmpty) return List.unmodifiable(_subjects);
    final q = searchQuery.toLowerCase();
    return _subjects
        .where((s) =>
            s.name.toLowerCase().contains(q) ||
            s.code.toLowerCase().contains(q) ||
            s.faculty.toLowerCase().contains(q))
        .toList();
  }

  List<Subject> get belowTargetSubjects =>
      _subjects.where((s) => s.isBelowTarget && s.total > 0).toList();

  double get overallPercentage {
    final totalAttended = _subjects.fold<int>(0, (sum, s) => sum + s.attended);
    final totalClasses = _subjects.fold<int>(0, (sum, s) => sum + s.total);
    if (totalClasses == 0) return 0;
    return (totalAttended / totalClasses) * 100;
  }

  Subject? bestSubject() {
    final withClasses = _subjects.where((s) => s.total > 0).toList();
    if (withClasses.isEmpty) return null;
    withClasses.sort((a, b) => b.percentage.compareTo(a.percentage));
    return withClasses.first;
  }

  Subject? worstSubject() {
    final withClasses = _subjects.where((s) => s.total > 0).toList();
    if (withClasses.isEmpty) return null;
    withClasses.sort((a, b) => a.percentage.compareTo(b.percentage));
    return withClasses.first;
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void _loadFromCache() {
    _subjects = LocalRepository.instance.getSubjects();
    notifyListeners();
    syncWithRemote();
  }

  void startListening() {
    final uid = _uid;
    if (uid == null) return;
    _remoteSub?.cancel();
    _remoteSub = FirebaseRepository.instance.watchSubjects(uid).listen(_mergeRemote);
  }

  void stopListening() {
    _remoteSub?.cancel();
    _remoteSub = null;
  }

  Future<void> syncWithRemote() async {
    final uid = _uid;
    if (uid == null) return;
    if (!await ConnectivityService.instance.checkNow()) return;
    try {
      final remote = await FirebaseRepository.instance.fetchSubjects(uid);
      await _mergeRemote(remote);
      // push any local-only subjects up
      for (final local in _subjects) {
        final existsRemotely = remote.any((r) => r.id == local.id);
        if (!existsRemotely) {
          await FirebaseRepository.instance.upsertSubject(uid, local);
        }
      }
    } catch (_) {
      // stay on cached data if network fails
    }
  }

  Future<void> _mergeRemote(List<Subject> remote) async {
    final byId = {for (final s in _subjects) s.id: s};
    for (final r in remote) {
      final localVersion = byId[r.id];
      if (localVersion == null || r.updatedAt.isAfter(localVersion.updatedAt)) {
        byId[r.id] = r;
        await LocalRepository.instance.putSubject(r);
      }
    }
    _subjects = byId.values.toList()..sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  Future<void> addSubject({
    required String name,
    required String code,
    required String faculty,
    required double targetPercentage,
    required int colorValue,
    required String icon,
  }) async {
    final subject = Subject(
      id: _uuid.v4(),
      name: name,
      code: code,
      faculty: faculty,
      attended: 0,
      total: 0,
      targetPercentage: targetPercentage,
      colorValue: colorValue,
      icon: icon,
      updatedAt: DateTime.now(),
    );
    _subjects = [..._subjects, subject]..sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
    await _persist(subject);
  }

  Future<void> updateSubject(Subject subject) async {
    final updated = subject.copyWith(updatedAt: DateTime.now());
    _subjects = _subjects.map((s) => s.id == updated.id ? updated : s).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
    await _persist(updated);
  }

  /// Applies an attended/total delta after an attendance mark, without
  /// bumping the "edited by user" semantics beyond updating updatedAt.
  Future<void> applyAttendanceDelta(String subjectId, {required int attendedDelta, required int totalDelta}) async {
    final index = _subjects.indexWhere((s) => s.id == subjectId);
    if (index == -1) return;
    final current = _subjects[index];
    final updated = current.copyWith(
      attended: (current.attended + attendedDelta).clamp(0, 1 << 30),
      total: (current.total + totalDelta).clamp(0, 1 << 30),
      updatedAt: DateTime.now(),
    );
    _subjects = [..._subjects]..[index] = updated;
    notifyListeners();
    await _persist(updated);
  }

  Future<void> deleteSubject(String id) async {
    _subjects = _subjects.where((s) => s.id != id).toList();
    notifyListeners();
    await LocalRepository.instance.deleteSubject(id);
    final uid = _uid;
    if (uid != null) {
      if (await ConnectivityService.instance.checkNow()) {
        await FirebaseRepository.instance.deleteSubject(uid, id);
      } else {
        await LocalRepository.instance.queueForSync('subject_delete', id, {'id': id});
      }
    }
  }

  Future<void> _persist(Subject subject) async {
    await LocalRepository.instance.putSubject(subject);
    final uid = _uid;
    if (uid == null) return;
    if (await ConnectivityService.instance.checkNow()) {
      await FirebaseRepository.instance.upsertSubject(uid, subject);
    } else {
      await LocalRepository.instance.queueForSync('subject', subject.id, subject.toJson());
    }
  }

  /// Seeds realistic demo subjects for first-time users so the dashboard,
  /// analytics and bunk calculator aren't empty on first launch.
  Future<void> seedDemoDataIfEmpty() async {
    if (_subjects.isNotEmpty) return;
    final now = DateTime.now();
    final demo = [
      Subject(id: _uuid.v4(), name: 'Data Structures', code: 'CS201', faculty: 'Dr. R. Sharma', attended: 21, total: 26, targetPercentage: 75, colorValue: SubjectColors.options[0], icon: 'code', updatedAt: now),
      Subject(id: _uuid.v4(), name: 'DBMS', code: 'CS202', faculty: 'Prof. A. Verma', attended: 17, total: 24, targetPercentage: 75, colorValue: SubjectColors.options[1], icon: 'science', updatedAt: now),
      Subject(id: _uuid.v4(), name: 'Operating Systems', code: 'CS203', faculty: 'Dr. K. Iyer', attended: 14, total: 22, targetPercentage: 75, colorValue: SubjectColors.options[2], icon: 'architecture', updatedAt: now),
      Subject(id: _uuid.v4(), name: 'Computer Networks', code: 'CS204', faculty: 'Prof. S. Nair', attended: 18, total: 25, targetPercentage: 75, colorValue: SubjectColors.options[3], icon: 'public', updatedAt: now),
      Subject(id: _uuid.v4(), name: 'Mathematics', code: 'MA201', faculty: 'Dr. P. Menon', attended: 23, total: 27, targetPercentage: 75, colorValue: SubjectColors.options[4], icon: 'calculate', updatedAt: now),
    ];
    _subjects = demo;
    notifyListeners();
    for (final s in demo) {
      await _persist(s);
    }
  }

  Subject? byId(String id) {
    try {
      return _subjects.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _remoteSub?.cancel();
    super.dispose();
  }
}
