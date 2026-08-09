import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'app.dart';
import 'repositories/local_repository.dart';
import 'core/services/notification_service.dart';
import 'providers/auth_provider.dart';
import 'providers/subject_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/timetable_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await LocalRepository.init();
  await NotificationService.instance.init();

  runApp(const CampusTrackBootstrap());
}

/// Wires up all app-level providers before handing off to [CampusTrackApp].
class CampusTrackBootstrap extends StatelessWidget {
  const CampusTrackBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SubjectProvider()),
        ChangeNotifierProxyProvider<SubjectProvider, AttendanceProvider>(
          create: (_) => AttendanceProvider(),
          update: (_, subjectProvider, attendanceProvider) {
            final provider = attendanceProvider ?? AttendanceProvider();
            provider.attachSubjectProvider(subjectProvider);
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => TimetableProvider()),
      ],
      child: const CampusTrackApp(),
    );
  }
}
