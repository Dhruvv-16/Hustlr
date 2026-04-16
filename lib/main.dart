import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // import for kIsWeb and defaultTargetPlatform
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart'; // enable after adding google-services.json
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'services/api_service.dart';
import 'services/location_service.dart';
import 'services/mock_data_service.dart';
import 'services/api_health_service.dart';
import 'services/background_heartbeat_service.dart';
import 'services/notification_service.dart';
import 'widgets/restart_widget.dart';
import 'blocs/user/user_bloc.dart';
import 'blocs/policy/policy_bloc.dart';
import 'blocs/claims/claims_bloc.dart';
import 'blocs/claims/claims_event.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


/// Background message handler - runs in isolate when app is terminated or backgrounded
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
  // Firebase automatically displays notification for background messages
  // No need to show notification here - it's handled by Firebase
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Add this Error Trap to stop the flood and reveal the real bug
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print("🚨 REAL ERROR CAUGHT: ${details.exception}");
    print("🚨 STACKTRACE: ${details.stack}");
  };

  await Hive.initFlutter();
  final appBox = await Hive.openBox('appData');

  // Local storage must be ready before the router reads auth state
  await StorageService.init();
  await ApiService.instance.restoreSessionTokenFromStorage();

  final localeProvider = LocaleProvider();
  await localeProvider.loadSavedLocale();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  final hasSupabaseConfig = supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseAnonKey.contains('YOUR_');

  if (hasSupabaseConfig) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
    } catch (e) {
      print('Supabase initialization skipped: $e');
    }
  } else {
    print(
        'Supabase initialization skipped: missing SUPABASE_URL / SUPABASE_ANON_KEY');
  }

  // Firebase (messaging & cross platform)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Set up background message handler BEFORE initialize
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Initialize notification service (handles foreground messages and taps)
    await NotificationService.initialize();
    
    // Request notification permission (required for Android 13+, iOS 10+)
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      String? token = await FirebaseMessaging.instance.getToken();
      print("FCM TOKEN: $token");
    }
  } catch (e) {
    print("Firebase initialization error: $e");
  }

  final claimsBloc = ClaimsBloc(
    apiService: ApiService.instance,
    supabase: hasSupabaseConfig ? Supabase.instance.client : null,
  );

  // Demo bridge: long-press disruption triggers flow through ClaimsBloc
  // so both the MockDataService path AND the BLoC path stay in sync.
  final mockService = MockDataService();
  mockService.onClaimApproved = (claim) {
    claimsBloc.add(ClaimStatusUpdated(claim));
  };

  // Start API health monitoring (auto-refreshes every 60s)
  ApiHealthService.instance.startAutoRefresh();
  await BackgroundHeartbeatService.initialize();

  runApp(
    RestartWidget(
      child: MultiBlocProvider(
        providers: [
          // Lazily initialized. Dispatch LoadUser/LoadPolicy/WatchClaims after
          // OTP login succeeds (in the auth screen) using:
          //   context.read<UserBloc>().add(LoadUser(userId));
          //   context.read<PolicyBloc>().add(LoadPolicy(userId));
          //   context.read<ClaimsBloc>().add(WatchClaims(userId));
          BlocProvider<UserBloc>(
            create: (_) => UserBloc(apiService: ApiService.instance),
          ),
          BlocProvider<PolicyBloc>(
            create: (_) => PolicyBloc(apiService: ApiService.instance),
          ),
          BlocProvider<ClaimsBloc>.value(value: claimsBloc),
        ],
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: LocationService.instance),
            ChangeNotifierProvider.value(value: mockService),
            ChangeNotifierProvider(create: (_) => ThemeProvider(appBox: appBox)),
            ChangeNotifierProvider.value(value: localeProvider),
          ],
          child: const HustlrApp(),
        ),
      ),
    ),
  );
}

class HustlrApp extends StatefulWidget {
  const HustlrApp({super.key});

  @override
  State<HustlrApp> createState() => _HustlrAppState();
}

class _HustlrAppState extends State<HustlrApp> {
  @override
  void initState() {
    super.initState();
    // Set up notification tap handler
    NotificationService.setNotificationTapCallback((payload) async {
      final route = payload['route'] ?? payload['type'];
      print('Notification tapped - Route: $route, Payload: $payload');

      // Use GoRouter for navigation
      if (mounted && route != null) {
        _handleNotificationNavigation(route, payload);
      }
    });
  }

  void _handleNotificationNavigation(String route, Map<String, dynamic> payload) {
    // Use the global appRouter directly to avoid context-related lookup errors
    // (the current context is above the MaterialApp.router in the tree)
    
    // Map notification routes to app routes
    if (route == 'dashboard' || route == 'home') {
      appRouter.go('/dashboard');
    } else if (route == 'wallet' || route == 'wallet_credited') {
      appRouter.go('/wallet');
    } else if (route == 'claims' || route == 'claim_approved' || route == 'claim_created') {
      appRouter.go('/claims');
    } else if (route == 'policy' || route == 'premium_deducted') {
      appRouter.go('/policy');
    } else if (route == 'disruption' || route == 'disruption_alert') {
      appRouter.go('/disruptions');
    }
  }

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

