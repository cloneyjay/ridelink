import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/reset_password_screen.dart';
import '../../features/auth/sign_in_screen.dart';
import '../../features/auth/sign_up_screen.dart';
import '../../features/auth/verify_email_screen.dart';
import '../../features/home/home_placeholder_screen.dart';
import '../../features/rider/rider_onboarding_placeholder_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../auth/session.dart';
import '../auth/session_manager.dart';
import '../providers.dart';
import 'rider_intent.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const auth = '/auth';
  static const signUp = '/auth/signup';
  static const verifyEmail = '/auth/verify';
  static const forgotPassword = '/auth/forgot';
  static const resetPassword = '/auth/reset';
  static const home = '/home';
  static const riderOnboarding = '/rider/onboarding';

  /// [codeSent] is false when arriving from a sign-in on an unconfirmed email.
  static String verifyEmailFor(String email, {required bool codeSent}) => Uri(
    path: verifyEmail,
    queryParameters: {'email': email, 'sent': codeSent ? '1' : '0'},
  ).toString();

  static String resetPasswordFor(String email) =>
      Uri(path: resetPassword, queryParameters: {'email': email}).toString();
}

/// unknown/offline -> splash, signed out -> auth, signed in -> home (or rider onboarding).
String? sessionRedirect(
  SessionState state,
  String location, {
  bool riderIntent = false,
}) {
  switch (state) {
    case SessionUnknown():
    case SessionOffline():
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    case SignedOut():
      return location.startsWith(AppRoutes.auth) ? null : AppRoutes.auth;
    case SignedIn():
      final onEntry =
          location == AppRoutes.splash || location.startsWith(AppRoutes.auth);
      if (!onEntry) return null;
      return riderIntent ? AppRoutes.riderOnboarding : AppRoutes.home;
  }
}

GoRouter buildRouter(
  SessionManager session,
  RiderIntent riderIntent, {
  String initialLocation = AppRoutes.splash,
}) => GoRouter(
  initialLocation: initialLocation,
  refreshListenable: Listenable.merge([session, riderIntent]),
  redirect: (context, state) => sessionRedirect(
    session.state,
    state.matchedLocation,
    riderIntent: riderIntent.active,
  ),
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.auth,
      builder: (context, state) => const SignInScreen(),
      routes: [
        GoRoute(
          path: 'signup',
          builder: (context, state) => const SignUpScreen(),
        ),
        GoRoute(
          path: 'verify',
          builder: (context, state) => VerifyEmailScreen(
            email: state.uri.queryParameters['email'] ?? '',
            codeSent: state.uri.queryParameters['sent'] != '0',
          ),
        ),
        GoRoute(
          path: 'forgot',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: 'reset',
          builder: (context, state) => ResetPasswordScreen(
            email: state.uri.queryParameters['email'] ?? '',
          ),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomePlaceholderScreen(),
    ),
    GoRoute(
      path: AppRoutes.riderOnboarding,
      builder: (context, state) => const RiderOnboardingPlaceholderScreen(),
    ),
  ],
);

final routerProvider = Provider<GoRouter>((ref) {
  final router = buildRouter(
    ref.watch(sessionManagerProvider),
    ref.watch(riderIntentProvider),
  );
  ref.onDispose(router.dispose);
  return router;
});
