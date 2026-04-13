import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/claim.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/auth/step_up_auth_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/onboarding_complete_screen.dart';
import '../../features/onboarding/onboarding_carousel_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/dashboard/trigger_status_screen.dart';
import '../../features/policy/policy_screen.dart';
import '../../features/policy/shadow_policy_screen.dart';
import '../../features/policy/premium_breakdown_screen.dart';
import '../../features/policy/payment_screen.dart';
import '../../features/policy/compound_triggers_screen.dart';
import '../../features/claims/claims_screen.dart';
import '../../features/claims/claim_detail_screen.dart';
import '../../features/claims/manual_evidence_screen.dart';
import '../../features/claims/claim_submitted_screen.dart';
import '../../features/claims/auto_explanation_screen.dart';
import '../../features/claims/appeal_claim_screen.dart';
import '../../features/wallet/wallet_screen.dart';
import '../../features/wallet/analytics_dashboard_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/api_status_screen.dart';
import '../../features/support/support_screen.dart';
import '../../features/admin/admin_dashboard_screen.dart';
import '../../features/admin/ml_tester_screen.dart';
import '../../features/ml_live/ml_live_screen.dart';
import '../../screens/notifications_screen.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import '../services/storage_service.dart';

// ─── Route names (type-safe) ─────────────────────────────────────────────────
class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const otp = '/otp';
  static const onboarding = '/onboarding';
  static const onboardingComplete = '/onboarding/complete';
  static const carousel = '/carousel';
  static const dashboard = '/dashboard';
  static const triggerStatus = '/dashboard/triggers';
  static const policy = '/policy';
  static const shadowPolicy = '/policy/shadow';
  static const premiumBreakdown = '/policy/premium';
  static const payment = '/policy/payment';
  static const compoundTriggers = '/policy/compound';
  static const claims = '/claims';
  static const manualEvidence = '/claims/evidence';
  static const claimSubmitted = '/claims/submitted';
  static const autoExplanation = '/claims/explanation';
  static const claimDetail = '/claims/:id';
  static const wallet = '/wallet';
  static const analytics = '/wallet/analytics';
  static const notifications = '/notifications';
  static const profile = '/profile';
  static const apiStatus = '/profile/api-status';
  static const support = '/support';
  static const admin = '/admin';
  static const mlTester = '/admin/ml-tester';
  static const mlLive = '/ml-live';
  static const stepUpAuth = '/step-up-auth';
}

// ─── Initial Route Logic ─────────────────────────────────────────────────────
Future<String> _getInitialRoute() async {
  if (!Hive.isBoxOpen('appData')) return AppRoutes.splash;
  final isComplete = await StorageService.instance.isOnboardingComplete();
  final userId = await StorageService.instance.getUserId();
  final box = Hive.box('appData');
  final isLoggedIn = box.get('isLoggedIn', defaultValue: false) as bool;

  if (!isLoggedIn) {
    return AppRoutes.login;
  }
  if (isComplete && userId != null) {
    return AppRoutes.dashboard;
  }
  return AppRoutes.carousel;
}

// ─── Router ──────────────────────────────────────────────────────────────────
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  redirect: (context, state) async {
    if (state.uri.toString() == AppRoutes.splash) {
      final isOnboarded = await StorageService.instance.isOnboardingComplete();
      final userId = await StorageService.instance.getUserId();
      if (!Hive.isBoxOpen('appData')) return null;
      final box = Hive.box('appData');
      final isLoggedIn = box.get('isLoggedIn', defaultValue: false) as bool;

      if (!isLoggedIn) return AppRoutes.login;
      if (isOnboarded && userId != null) return AppRoutes.dashboard;
      return AppRoutes.carousel;
    }
    return null;
  },
  routes: [
    // ── Public ──────────────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.splash,
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.otp,
      builder: (context, state) {
        final phone = state.uri.queryParameters['phone'] ?? '';
        final verificationId = state.uri.queryParameters['verificationId'] ?? '';
        return OTPScreen(phone: phone, verificationId: verificationId);
      },
    ),
    GoRoute(
      path: AppRoutes.carousel,
      builder: (_, __) => const OnboardingCarouselScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (_, __) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboardingComplete,
      builder: (_, __) => const OnboardingCompleteScreen(),
    ),

    // ── Shell with BottomNavBar ──────────────────────────────────────────────
    ShellRoute(
      builder: (context, state, child) =>
          ScaffoldWithNav(child: child, location: state.uri.toString()),
      routes: [
        GoRoute(
          path: AppRoutes.dashboard,
          builder: (_, __) => const DashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.policy,
          builder: (_, __) => const PolicyScreen(),
        ),
        GoRoute(
          path: AppRoutes.payment,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return PaymentScreen(checkoutData: extra);
          },
        ),
        GoRoute(
          path: AppRoutes.claims,
          builder: (_, __) => const ClaimsScreen(),
        ),

        GoRoute(
          path: AppRoutes.triggerStatus,
          builder: (_, __) => const TriggerStatusScreen(),
        ),
        GoRoute(
          path: AppRoutes.shadowPolicy,
          builder: (_, __) => const ShadowPolicyScreen(),
        ),
        GoRoute(
          path: AppRoutes.premiumBreakdown,
          builder: (_, __) => const PremiumBreakdownScreen(),
        ),
        GoRoute(
          path: AppRoutes.compoundTriggers,
          builder: (_, __) => const CompoundTriggersScreen(),
        ),
        GoRoute(
          path: AppRoutes.manualEvidence,
          builder: (_, __) => const ManualEvidenceScreen(),
        ),
        GoRoute(
          path: AppRoutes.claimSubmitted,
          builder: (context, state) {
            final extra = state.extra;
            Map<String, dynamic>? claimData;
            List<String>? imagePaths;
            if (extra is Map<String, dynamic>) {
              // New format: {'claim': {...}, 'imagePaths': [...]}
              if (extra.containsKey('claim')) {
                claimData = extra['claim'] as Map<String, dynamic>?;
                imagePaths = (extra['imagePaths'] as List?)?.cast<String>();
              } else {
                // Old format: the claim map directly
                claimData = extra;
              }
            }
            return ClaimSubmittedScreen(claimData: claimData, imagePaths: imagePaths);
          },
        ),
        GoRoute(
          path: AppRoutes.autoExplanation,
          builder: (context, state) {
            final extra = state.extra;
            final Map<String, dynamic>? payload =
                extra is Map<String, dynamic> ? extra : null;
            return AutoExplanationScreen(extra: payload);
          },
        ),
        GoRoute(
          path: '/claims/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return ClaimDetailScreen(claimId: id);
          },
        ),
        GoRoute(
          path: '/claims/:id/appeal',
          builder: (context, state) {
            final claim = state.extra as Claim;
            return AppealClaimScreen(rejectedClaim: claim);
          },
        ),
        GoRoute(
          path: AppRoutes.wallet,
          builder: (_, __) => const WalletScreen(),
        ),
        GoRoute(
          path: AppRoutes.analytics,
          builder: (_, __) => const AnalyticsDashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.notifications,
          builder: (_, __) => const NotificationsScreen(),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (_, __) => const ProfileScreen(),
        ),
        GoRoute(
          path: AppRoutes.apiStatus,
          builder: (_, __) => const ApiStatusScreen(),
        ),
        GoRoute(
          path: AppRoutes.support,
          builder: (_, __) => const SupportScreen(),
        ),
      ],
    ),

    // ── Admin ────────────────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.admin,
      builder: (_, __) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.mlTester,
      builder: (_, __) => const MlTesterScreen(),
    ),
    GoRoute(
      path: AppRoutes.mlLive,
      builder: (_, __) => const MLLiveScreen(),
    ),

    // ── Step-Up Biometric Auth ───────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.stepUpAuth,
      builder: (context, state) {
        final reason = state.uri.queryParameters['reason'];
        return StepUpAuthScreen(triggerReason: reason);
      },
    ),
  ],
);
