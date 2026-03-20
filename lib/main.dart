import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart'; // enable after adding google-services.json

import 'core/router/app_router.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';

import 'package:provider/provider.dart';
import 'services/mock_data_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local storage must be ready before the router reads auth state
  await StorageService.init();

  // Firebase (messaging)
  // TODO: Add google-services.json / GoogleService-Info.plist before enabling
  // await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MockDataService()),
      ],
      child: const ShieldGigApp(),
    ),
  );
}

class ShieldGigApp extends StatelessWidget {
  const ShieldGigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Hustlr',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
