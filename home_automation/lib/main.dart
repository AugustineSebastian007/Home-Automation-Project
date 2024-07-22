import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/firebase_options.dart';
import 'package:home_automation/routes/app.routes.dart';
import 'package:home_automation/styles/flicky_icons_icons.dart';
import 'package:home_automation/styles/theams.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    const ProviderScope(child: HomeAutomationApp())
  );
}

class HomeAutomationApp extends StatelessWidget {
  const HomeAutomationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: HomeAutomationTheam.light,
      darkTheme: HomeAutomationTheam.dark,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      routeInformationProvider: AppRoutes.router.routeInformationProvider,
      routeInformationParser: AppRoutes.router.routeInformationParser,
      routerDelegate: AppRoutes.router.routerDelegate,

    );
  }
}