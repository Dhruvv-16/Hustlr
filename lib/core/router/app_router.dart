import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/onboarding_complete_screen.dart';
import '../../features/onboarding/onboarding_carousel_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/dashboard/iss_detail_screen.dart';
import '../../features/dashboard/trigger_status_screen.dart';
import '../../features/policy/policy_screen.dart';
import '../../features/policy/shadow_policy_screen.dart';
import '../../features/policy/premium_breakdown_screen.dart';
import '../../features/policy/plans_screen.dart';
import '../../features/policy/payment_screen.dart';
import '../../features/policy/compound_triggers_screen.dart';
import '../../features/claims/claims_screen.dart';
import '../../features/claims/claim_detail_screen.dart';
import '../../features/claims/manual_evidence_screen.dart';
import '../../features/claims/claim_submitted_screen.dart';
import '../../features/claims/auto_explanation_screen.dart';
import '../../features/wallet/wallet_screen.dart';
import '../../features/wallet/analytics_dashboard_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/support/support_screen.dart';
import '../../features/admin/admin_dashboard_screen.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import '../services/storage_service.dart';

// ─── Route names (type-safe) ─────────────────────────────────────────────────
class AppRoutes {
  static const splash      = '/';
  static const login       = '/login';
  static const otp         = '/otp';
  static const onboarding  = '/onboarding';
  static const onboardingComplete = '/onboarding/complete';
  static const carousel    = '/carousel';
  static const dashboard   = '/dashboard';
  static const issDetail   = '/dashboard/iss';
  static const triggerStatus = '/dashboard/triggers';
  static const policy      = '/policy';
  static const shadowPolicy= '/policy/shadow';
  static const premiumBreakdown = '/policy/premium';
  static const plans       = '/policy/plans';
  static const payment     = '/policy/payment';
  static const compoundTriggers = '/policy/compound';
  static const claims      = '/claims';
  static const manualEvidence = '/claims/evidence';
  static const claimSubmitted = '/claims/submitted';
  static const autoExplanation = '/claims/explanation';
  static const claimDetail = '/claims/:id';
  static const wallet      = '/wallet';
  static const analytics   = '/wallet/analytics';
  static const profile     = '/profile';
  static const support     = '/support';
  static const admin       = '/admin';
}

// ─── Initial Route Logic ─────────────────────────────────────────────────────
String _getInitialRoute() {
  if (!Hive.isBoxOpen('appData')) return AppRoutes.splash;
  final box = Hive.box('appData');
  final isLoggedIn = box.get('isLoggedIn', defaultValue: false);
  final onboardingComplete = box.get('onboardingComplete', defaultValue: false);

  if (!isLoggedIn) {
    return AppRoutes.login;
  } else if (!onboardingComplete) {
    return AppRoutes.carousel;
  } else {
    return AppRoutes.dashboard;
  }
}

// ─── Router ──────────────────────────────────────────────────────────────────
final GoRouter appRouter = GoRouter(
  initialLocation: _getInitialRoute(),
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
        return OTPScreen(phone: phone);
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
          path: AppRoutes.plans,
          builder: (_, __) => const PlansScreen(),
        ),
        GoRoute(
          path: AppRoutes.payment,
          builder: (_, __) => const PaymentScreen(),
        ),
        GoRoute(
          path: AppRoutes.claims,
          builder: (_, __) => const ClaimsScreen(),
        ),
        GoRoute(
          path: '/claims/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return ClaimDetailScreen(claimId: id);
          },
        ),
        // Phase 2 nested routes (not in nav bar but shell)
        GoRoute(
          path: AppRoutes.issDetail,
          builder: (_, __) => const ISSDetailScreen(),
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
          builder: (context, state) {
            final type = state.uri.queryParameters['type'] ?? 'Other';
            return ManualEvidenceScreen(disruptionType: type);
          },
        ),
        GoRoute(
          path: AppRoutes.claimSubmitted,
          builder: (_, __) => const ClaimSubmittedScreen(),
        ),
        GoRoute(
          path: AppRoutes.autoExplanation,
          builder: (_, __) => const AutoExplanationScreen(),
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
          path: AppRoutes.profile,
          builder: (_, __) => const ProfileScreen(),
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
  ],
);


