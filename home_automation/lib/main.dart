import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/firebase_options.dart';
import 'package:home_automation/routes/app.routes.dart';
import 'package:home_automation/styles/theams.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:home_automation/features/settings/presentation/pages/settings.page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Configure Realtime Database
    FirebaseDatabase database = FirebaseDatabase.instance;
    database.setLoggingEnabled(true);
    database.databaseURL = "https://home-automation-78d43-default-rtdb.asia-southeast1.firebasedatabase.app";
    
    print("Firebase initialized successfully");
  } catch (e) {
    print("Error initializing Firebase: $e");
  }
  
  runApp(const ProviderScope(child: HomeAutomationApp()));
}

class HomeAutomationApp extends ConsumerWidget {
  const HomeAutomationApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    
    return MaterialApp.router(
      theme: HomeAutomationTheam.light,
      darkTheme: HomeAutomationTheam.dark,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      routeInformationProvider: AppRoutes.router.routeInformationProvider,
      routeInformationParser: AppRoutes.router.routeInformationParser,
      routerDelegate: AppRoutes.router.routerDelegate,

    );
  }
}

// C:\Users\Augustine\Desktop\S9 Project\home_automation\lib\main.dart



