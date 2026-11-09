import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'screens/splash_screen.dart';
import 'services/alarm_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Non-blocking background initialization for immediate UI & splash screen rendering
  _initServicesAsync();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const YfcApp(),
    ),
  );
}

Future<void> _initServicesAsync() async {
  try {
    await Firebase.initializeApp();
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  } catch (e) {
    debugPrint("[Firebase Init Error] $e");
  }

  // Initialize FCM Push & Local Notification Banners
  try {
    await NotificationService.initialize();
  } catch (e) {
    debugPrint("[NotificationService Init Error] $e");
  }

  // Initialize Native Alarm & High Priority Notification Engine
  try {
    await AlarmService().initialize();
  } catch (e) {
    debugPrint("[AlarmService Init Error] $e");
  }
}

class YfcApp extends StatelessWidget {
  const YfcApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return MaterialApp(
      title: 'YFC Fellowship',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appState.themeMode,
      home: const SplashScreen(),
    );
  }
}
