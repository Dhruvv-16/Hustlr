import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
// import 'package:firebase_core/firebase_core.dart'; // enable after adding google-services.json

import 'core/router/app_router.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

import 'package:provider/provider.dart';
import 'services/mock_data_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  final appBox = await Hive.openBox('appData');

  // Local storage must be ready before the router reads auth state
  await StorageService.init();

  // Firebase (messaging)
  // TODO: Add google-services.json / GoogleService-Info.plist before enabling
  // await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MockDataService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider(appBox: appBox)),
      ],
      child: const HustlrApp(),
    ),
  );
}

class HustlrApp extends StatelessWidget {
  const HustlrApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp.router(
      title: 'Hustlr',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.themeMode,
      routerConfig: appRouter,
    );
  }
}
