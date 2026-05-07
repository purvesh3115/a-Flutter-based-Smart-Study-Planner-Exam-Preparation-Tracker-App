import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/subject.dart';
import 'models/topic.dart';
import 'models/study_session.dart';
import 'providers/study_provider.dart';
import 'providers/connectivity_provider.dart';
import 'theme/app_theme.dart';
import 'screens/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  
  // Register Adapters
  Hive.registerAdapter(SubjectAdapter());
  Hive.registerAdapter(TopicAdapter());
  Hive.registerAdapter(StudySessionAdapter());

  // Open Boxes
  await Hive.openBox<Subject>('subjects');
  await Hive.openBox<Topic>('topics');
  await Hive.openBox<StudySession>('sessions');

  final studyProvider = StudyProvider();
  await studyProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: studyProvider),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      child: const StudyPlannerApp(),
    ),
  );
}

class StudyPlannerApp extends StatelessWidget {
  const StudyPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Study Planner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainLayout(),
    );
  }
}
