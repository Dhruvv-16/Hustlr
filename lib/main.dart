import 'dart:async';
import 'dart:ui';


import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:firebase_core/firebase_core.dart'; // enable after adding google-services.json
import 'package:hive_flutter/hive_flutter.dart';

import 'core/router/app_router.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';

import 'package:provider/provider.dart';
import 'services/mock_data_service.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/claims/claims_bloc.dart';
import 'services/api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    // Always log errors regardless of build mode.
    debugPrint('Uncaught app error: $error\n$stack');
    // Return true to mark the error as handled — prevents the browser from
    // swallowing the entire Flutter view and rendering a blank white screen.
    return true;
  };

  // Firebase (messaging)
  // TODO: Add google-services.json / GoogleService-Info.plist before enabling
  // await Firebase.initializeApp();

  // Ensure storage layers are ready before providers that read Hive/Prefs are built.
  await _initializeAppServices();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final provider = LocaleProvider();
            unawaited(provider.loadSavedLocale());
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(appBox: Hive.box('appData')),
        ),
        ChangeNotifierProvider(create: (_) => MockDataService()),
      ],
      child: BlocProvider<ClaimsBloc>(
        create: (_) => ClaimsBloc(
          apiService: ApiService.instance,
          supabase: null,
        ),
        child: const ShieldGigApp(),
      ),
    ),
  );
}

Future<void> _initializeAppServices() async {
  await Hive.initFlutter();
  if (!Hive.isBoxOpen('appData')) {
    await Hive.openBox('appData');
  }

  await StorageService.init();
}

class ShieldGigApp extends StatelessWidget {
  const ShieldGigApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final themeMode = context.watch<ThemeProvider>().themeMode;

    return MaterialApp.router(
      title: 'Hustlr',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: appRouter,
    );
  }
}
