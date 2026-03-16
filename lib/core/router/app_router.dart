import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/onboarding_complete_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/policy/policy_screen.dart';
import '../../features/policy/plans_screen.dart';
import '../../features/policy/payment_screen.dart';
import '../../features/claims/claims_screen.dart';
import '../../features/claims/claim_detail_screen.dart';
import '../../features/wallet/wallet_screen.dart';
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
  static const dashboard   = '/dashboard';
  static const policy      = '/policy';
  static const plans       = '/policy/plans';
  static const payment     = '/policy/payment';
  static const claims      = '/claims';
  static const claimDetail = '/claims/:id';
  static const wallet      = '/wallet';
  static const profile     = '/profile';
  static const support     = '/support';
  static const admin       = '/admin';
}

// ─── Router ──────────────────────────────────────────────────────────────────
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  redirect: _authRedirect,
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
        GoRoute(
          path: AppRoutes.wallet,
          builder: (_, __) => const WalletScreen(),
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

// ─── Auth redirect logic ─────────────────────────────────────────────────────
String? _authRedirect(BuildContext context, GoRouterState state) {
  final path = state.uri.path;
  final loggedIn   = StorageService.isLoggedIn;
  final onboarded  = StorageService.isOnboarded;

  // Public routes – always accessible
  const publicRoutes = [
    AppRoutes.splash,
    AppRoutes.login,
    AppRoutes.otp,
  ];
  if (publicRoutes.contains(path)) return null;

  if (!loggedIn) return AppRoutes.login;
  if (!onboarded && path != AppRoutes.onboarding) {
    return AppRoutes.onboarding;
  }
  if (onboarded && path == AppRoutes.onboarding) {
    return AppRoutes.dashboard;
  }
  return null;
}
