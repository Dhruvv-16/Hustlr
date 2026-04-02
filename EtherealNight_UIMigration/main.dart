import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
// import 'package:firebase_core/firebase_core.dart'; // enable after adding google-services.json

import 'core/router/app_router.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

import 'package:provider/provider.dart';
import 'services/mock_data_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  final appBox = await Hive.openBox('appData');

  // Local storage must be ready before the router reads auth state
  await StorageService.init();

  final localeProvider = LocaleProvider();
  await localeProvider.loadSavedLocale();

  // Firebase (messaging)
  // TODO: Add google-services.json / GoogleService-Info.plist before enabling
  // await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MockDataService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider(appBox: appBox)),
        ChangeNotifierProvider.value(value: localeProvider),
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
    final localeProvider = Provider.of<LocaleProvider>(context);
    
    return MaterialApp.router(
      title: 'Hustlr',
      debugShowCheckedModeBanner: false,
      locale: localeProvider.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ta'),
        Locale('hi'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.themeMode,
      routerConfig: appRouter,
    );
  }
}
