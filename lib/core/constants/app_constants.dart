// App-wide constants: colours, Hive box names, Firestore paths, defaults.
import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2563EB);
  static const Color accent = Color(0xFF06B6D4);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFEF4444);
}

class HiveBoxes {
  static const String subjects = 'subjects_box';
  static const String attendance = 'attendance_box';
  static const String timetable = 'timetable_box';
  static const String settings = 'settings_box';
  static const String pendingSync = 'pending_sync_box';
}

class FirestorePaths {
  static String userDoc(String uid) => 'users/$uid';
  static String subjects(String uid) => 'subjects/$uid/items';
  static String attendance(String uid) => 'attendance/$uid/records';
  static String timetable(String uid) => 'timetable/$uid/entries';
}

class AppDefaults {
  static const double targetPercentage = 75.0;
  static const int minSdkWarningDays = 30;
  static const String appName = 'CampusTrack';
}

class SubjectIcons {
  /// Icon choices offered when creating/editing a subject.
  static const Map<String, IconData> options = {
    'book': Icons.menu_book_rounded,
    'science': Icons.science_rounded,
    'code': Icons.code_rounded,
    'calculate': Icons.calculate_rounded,
    'language': Icons.language_rounded,
    'biotech': Icons.biotech_rounded,
    'architecture': Icons.architecture_rounded,
    'psychology': Icons.psychology_rounded,
    'public': Icons.public_rounded,
    'brush': Icons.brush_rounded,
  };
}

class SubjectColors {
  static const List<int> options = [
    0xFF2563EB,
    0xFF06B6D4,
    0xFF10B981,
    0xFFF59E0B,
    0xFFEF4444,
    0xFF8B5CF6,
    0xFFEC4899,
    0xFF14B8A6,
  ];
}
