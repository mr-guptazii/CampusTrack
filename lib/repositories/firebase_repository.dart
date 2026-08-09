import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/subject.dart';
import '../models/attendance_record.dart';
import '../models/timetable_entry.dart';
import '../models/user_model.dart';

/// All Firestore reads/writes live here, scoped to the signed-in user.
/// Firestore layout:
///   users/{uid}
///   subjects/{uid}/items/{subjectId}
///   attendance/{uid}/records/{recordId}
///   timetable/{uid}/entries/{entryId}
class FirebaseRepository {
  FirebaseRepository._();
  static final FirebaseRepository instance = FirebaseRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------- User profile ----------------

  Future<void> upsertUser(UserModel user) =>
      _db.doc(FirestorePaths.userDoc(user.uid)).set(user.toJson(), SetOptions(merge: true));

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.doc(FirestorePaths.userDoc(uid)).get();
    if (!doc.exists) return null;
    return UserModel.fromJson(doc.data()!);
  }

  Stream<UserModel?> watchUser(String uid) => _db
      .doc(FirestorePaths.userDoc(uid))
      .snapshots()
      .map((d) => d.exists ? UserModel.fromJson(d.data()!) : null);

  // ---------------- Subjects ----------------

  CollectionReference<Map<String, dynamic>> _subjectsCol(String uid) =>
      _db.collection(FirestorePaths.subjects(uid));

  Stream<List<Subject>> watchSubjects(String uid) => _subjectsCol(uid)
      .snapshots()
      .map((snap) => snap.docs.map((d) => Subject.fromJson(d.data())).toList());

  Future<List<Subject>> fetchSubjects(String uid) async {
    final snap = await _subjectsCol(uid).get();
    return snap.docs.map((d) => Subject.fromJson(d.data())).toList();
  }

  Future<void> upsertSubject(String uid, Subject subject) =>
      _subjectsCol(uid).doc(subject.id).set(subject.toJson(), SetOptions(merge: true));

  Future<void> deleteSubject(String uid, String subjectId) =>
      _subjectsCol(uid).doc(subjectId).delete();

  // ---------------- Attendance ----------------

  CollectionReference<Map<String, dynamic>> _attendanceCol(String uid) =>
      _db.collection(FirestorePaths.attendance(uid));

  Stream<List<AttendanceRecord>> watchAttendance(String uid) => _attendanceCol(uid)
      .snapshots()
      .map((snap) => snap.docs.map((d) => AttendanceRecord.fromJson(d.data())).toList());

  Future<List<AttendanceRecord>> fetchAttendance(String uid) async {
    final snap = await _attendanceCol(uid).get();
    return snap.docs.map((d) => AttendanceRecord.fromJson(d.data())).toList();
  }

  Future<void> upsertAttendance(String uid, AttendanceRecord record) => _attendanceCol(uid)
      .doc(record.id)
      .set(record.copyWith(synced: true).toJson(), SetOptions(merge: true));

  Future<void> deleteAttendance(String uid, String recordId) =>
      _attendanceCol(uid).doc(recordId).delete();

  // ---------------- Timetable ----------------

  CollectionReference<Map<String, dynamic>> _timetableCol(String uid) =>
      _db.collection(FirestorePaths.timetable(uid));

  Stream<List<TimetableEntry>> watchTimetable(String uid) => _timetableCol(uid)
      .snapshots()
      .map((snap) => snap.docs.map((d) => TimetableEntry.fromJson(d.data())).toList());

  Future<List<TimetableEntry>> fetchTimetable(String uid) async {
    final snap = await _timetableCol(uid).get();
    return snap.docs.map((d) => TimetableEntry.fromJson(d.data())).toList();
  }

  Future<void> upsertTimetableEntry(String uid, TimetableEntry entry) =>
      _timetableCol(uid).doc(entry.id).set(entry.toJson(), SetOptions(merge: true));

  Future<void> deleteTimetableEntry(String uid, String entryId) =>
      _timetableCol(uid).doc(entryId).delete();

  // ---------------- Full backup ----------------

  Future<void> backupAll({
    required String uid,
    required List<Subject> subjects,
    required List<AttendanceRecord> attendance,
    required List<TimetableEntry> timetable,
  }) async {
    final batch = _db.batch();
    for (final s in subjects) {
      batch.set(_subjectsCol(uid).doc(s.id), s.toJson(), SetOptions(merge: true));
    }
    for (final a in attendance) {
      batch.set(_attendanceCol(uid).doc(a.id), a.copyWith(synced: true).toJson(),
          SetOptions(merge: true));
    }
    for (final t in timetable) {
      batch.set(_timetableCol(uid).doc(t.id), t.toJson(), SetOptions(merge: true));
    }
    await batch.commit();
  }
}
