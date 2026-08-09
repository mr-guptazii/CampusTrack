import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/app_constants.dart';
import '../models/subject.dart';
import '../models/attendance_record.dart';
import '../models/timetable_entry.dart';

/// All Hive access lives here. Data is stored as plain Maps (via each
/// model's toJson/fromJson) rather than generated TypeAdapters, so the
/// project needs no build_runner step to compile.
class LocalRepository {
  LocalRepository._();
  static final LocalRepository instance = LocalRepository._();

  Box get _subjectsBox => Hive.box(HiveBoxes.subjects);
  Box get _attendanceBox => Hive.box(HiveBoxes.attendance);
  Box get _timetableBox => Hive.box(HiveBoxes.timetable);
  Box get _settingsBox => Hive.box(HiveBoxes.settings);
  Box get _pendingSyncBox => Hive.box(HiveBoxes.pendingSync);

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(HiveBoxes.subjects);
    await Hive.openBox(HiveBoxes.attendance);
    await Hive.openBox(HiveBoxes.timetable);
    await Hive.openBox(HiveBoxes.settings);
    await Hive.openBox(HiveBoxes.pendingSync);
  }

  // ---------------- Subjects ----------------

  List<Subject> getSubjects() => _subjectsBox.values
      .map((e) => Subject.fromJson(Map<dynamic, dynamic>.from(e as Map)))
      .toList();

  Future<void> putSubject(Subject subject) =>
      _subjectsBox.put(subject.id, subject.toJson());

  Future<void> deleteSubject(String id) => _subjectsBox.delete(id);

  Future<void> clearSubjects() => _subjectsBox.clear();

  // ---------------- Attendance ----------------

  List<AttendanceRecord> getAttendanceRecords() => _attendanceBox.values
      .map((e) => AttendanceRecord.fromJson(Map<dynamic, dynamic>.from(e as Map)))
      .toList();

  List<AttendanceRecord> getAttendanceForSubject(String subjectId) =>
      getAttendanceRecords().where((r) => r.subjectId == subjectId).toList();

  Future<void> putAttendanceRecord(AttendanceRecord record) =>
      _attendanceBox.put(record.id, record.toJson());

  Future<void> deleteAttendanceRecord(String id) => _attendanceBox.delete(id);

  Future<void> clearAttendance() => _attendanceBox.clear();

  // ---------------- Timetable ----------------

  List<TimetableEntry> getTimetableEntries() => _timetableBox.values
      .map((e) => TimetableEntry.fromJson(Map<dynamic, dynamic>.from(e as Map)))
      .toList();

  Future<void> putTimetableEntry(TimetableEntry entry) =>
      _timetableBox.put(entry.id, entry.toJson());

  Future<void> deleteTimetableEntry(String id) => _timetableBox.delete(id);

  Future<void> clearTimetable() => _timetableBox.clear();

  // ---------------- Settings (key-value) ----------------

  T? getSetting<T>(String key, {T? fallback}) =>
      _settingsBox.get(key, defaultValue: fallback) as T?;

  Future<void> putSetting(String key, dynamic value) =>
      _settingsBox.put(key, value);

  // ---------------- Pending sync queue ----------------
  // Tracks locally-mutated entity ids (per collection) that still need to be
  // pushed to Firestore. Keyed as "collection:id" -> map payload.

  Future<void> queueForSync(String collection, String id, Map<String, dynamic> payload) =>
      _pendingSyncBox.put('$collection:$id', {'collection': collection, 'id': id, 'payload': payload});

  Future<void> removeFromSyncQueue(String collection, String id) =>
      _pendingSyncBox.delete('$collection:$id');

  List<Map> getPendingSyncItems() =>
      _pendingSyncBox.values.map((e) => Map<dynamic, dynamic>.from(e as Map)).toList();

  Future<void> clearAll() async {
    await _subjectsBox.clear();
    await _attendanceBox.clear();
    await _timetableBox.clear();
    await _pendingSyncBox.clear();
  }
}
