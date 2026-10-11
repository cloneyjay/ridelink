import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_placeholder_screen.dart';
import '../../features/home/home_placeholder_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../auth/session.dart';
import '../auth/session_manager.dart';
import '../providers.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const auth = '/auth';
  static const home = '/home';
}

/// Session-driven redirect: unknown -> splash, signed out -> auth, signed in -> home.
String? sessionRedirect(SessionState state, String location) {
  switch (state) {
    case SessionUnknown():
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    case SignedOut():
      return location.startsWith(AppRoutes.auth) ? null : AppRoutes.auth;
    case SignedIn():
      return location == AppRoutes.splash || location.startsWith(AppRoutes.auth)
          ? AppRoutes.home
          : null;
  }
}

GoRouter buildRouter(SessionManager session) => GoRouter(
  initialLocation: AppRoutes.splash,
  refreshListenable: session,
  redirect: (context, state) =>
      sessionRedirect(session.state, state.matchedLocation),
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.auth,
      builder: (context, state) => const AuthPlaceholderScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomePlaceholderScreen(),
    ),
  ],
);

final routerProvider = Provider<GoRouter>((ref) {
  final router = buildRouter(ref.watch(sessionManagerProvider));
  ref.onDispose(router.dispose);
  return router;
});
