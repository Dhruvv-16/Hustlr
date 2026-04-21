import 'dart:async';
import 'dart:ui';


import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
import 'blocs/policy/policy_bloc.dart';
import 'services/api_service.dart';
import 'services/shift_tracking_service.dart';
import 'services/notification_service.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.showBackgroundNotification(message);
}

void main() async {
  // Catch Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter error: ${details.exception}');
  };

  // Catch unhandled async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Async error: $error');
    return true;
  };
  
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Add fallback error widget
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text('Something went wrong.', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 16),
                  Text(details.exception.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      );
    };

    // Firebase (messaging + push)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Ensure storage layers are ready before providers that read Hive/Prefs are built.
    await _initializeAppServices();
    await NotificationService.initialize();

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
        child: MultiBlocProvider(
          providers: [
            BlocProvider<ClaimsBloc>(
              create: (_) => ClaimsBloc(
                apiService: ApiService.instance,
                supabase: null,
              ),
            ),
            BlocProvider<PolicyBloc>(
              create: (_) => PolicyBloc(apiService: ApiService.instance),
            ),
          ],
          child: const ShieldGigApp(),
        ),
      ),
    );
  }, (error, stack) {
    debugPrint('runZonedGuarded caught error: $error\n$stack');
  });
}

Future<void> _initializeAppServices() async {
  await Hive.initFlutter();
  if (!Hive.isBoxOpen('appData')) {
    await Hive.openBox('appData');
  }

  await StorageService.init();

  // Ensure we restore active shift status if the app was backgrounded or killed
  // This prevents the "Go Online" prompt from reappearing incorrectly.
  await ShiftTrackingService.instance.restoreActiveShiftOnLaunch();
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
