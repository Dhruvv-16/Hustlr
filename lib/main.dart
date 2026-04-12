import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // import for kIsWeb and defaultTargetPlatform
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart'; // enable after adding google-services.json
import 'package:firebase_messaging/firebase_messaging.dart';

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
import 'services/notification_service.dart';
import 'blocs/user/user_bloc.dart';
import 'blocs/policy/policy_bloc.dart';
import 'blocs/claims/claims_bloc.dart';
import 'blocs/claims/claims_event.dart';
import 'models/claim.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  final appBox = await Hive.openBox('appData');

  // Local storage must be ready before the router reads auth state
  await StorageService.init();

  final localeProvider = LocaleProvider();
  await localeProvider.loadSavedLocale();

  // Supabase initialization with placeholders for environment keys
  await Supabase.initialize(
    url: 'https://vmoihldysiswqzseyypn.supabase.co',
    anonKey: 'YOUR_SUPABASE_ANON_KEY', // Placeholder to be replaced
  );

  // Firebase (messaging & cross platform)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    NotificationService.initialize();

    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      String? token = await FirebaseMessaging.instance.getToken();
      print("FCM TOKEN: $token");
    }
  } catch (e) {
    print("Firebase initialization error: $e");
  }

  final claimsBloc = ClaimsBloc(
    apiService: ApiService.instance,
    supabase: Supabase.instance.client,
  );

  // Demo bridge: long-press disruption triggers flow through ClaimsBloc
  // so both the MockDataService path AND the BLoC path stay in sync.
  final mockService = MockDataService();
  mockService.onClaimApproved = (claim) {
    claimsBloc.add(ClaimStatusUpdated(claim));
  };

  // Start API health monitoring (auto-refreshes every 60s)
  ApiHealthService.instance.startAutoRefresh();

  runApp(
    MultiBlocProvider(
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
