import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/reset_password_screen.dart';
import '../../features/auth/sign_in_screen.dart';
import '../../features/auth/sign_up_screen.dart';
import '../../features/auth/verify_email_screen.dart';
import '../../features/booking/booking_routes.dart';
import '../../features/booking/data/booking_models.dart';
import '../../features/booking/edit_route_screen.dart';
import '../../features/booking/new_order_screen.dart';
import '../../features/booking/offer_waiting_screen.dart';
import '../../features/booking/quote_screen.dart';
import '../../features/booking/rider_list_screen.dart';
import '../../features/booking/rider_profile_screen.dart';
import '../../features/evidence/evidence_record_screen.dart';
import '../../features/home/sender_home_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/orders/order_detail_screen.dart';
import '../../features/orders/order_history_screen.dart';
import '../../features/payments/payment_methods_screen.dart';
import '../../features/profile/delete_account_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/restrictions/account_status_screen.dart';
import '../../features/restrictions/settle_balance_screen.dart';
import '../../features/rider/home/rider_home_screen.dart';
import '../../features/rider/onboarding/documents_screen.dart';
import '../../features/rider/onboarding/rider_onboarding_screen.dart';
import '../../features/rider/onboarding/verification_status_screen.dart';
import '../../features/rider/settings/rider_settings_screen.dart';
import '../../features/tracking/tracking_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../auth/session.dart';
import '../auth/session_manager.dart';
import '../mode/app_mode.dart';
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
  static const riderHome = '/rider';
  static const riderDocuments = '/rider/documents';
  static const riderVerification = '/rider/verification';
  static const riderSettings = '/rider/settings';
  static const riderPaymentMethods = '/rider/payment-methods';
  static const newOrder = '/home/new';
  static const history = '/history';
  static const notifications = '/notifications';
  static const profile = '/profile';
  static const deleteAccount = '/profile/delete';
  static const settleBalance = '/balance';
  static const accountStatus = '/account/status';

  /// Order history for one side (sender: GET /orders, rider: GET /riders/me/orders).
  static String historyFor(AppMode side) => side == AppMode.rider
      ? Uri(path: history, queryParameters: {'as': 'rider'}).toString()
      : history;
  static String orderDetailFor(String orderId, {bool asRider = false}) => Uri(
    path: '/orders/$orderId',
    queryParameters: asRider ? {'as': 'rider'} : null,
  ).toString();
  static String evidenceFor(String orderId) => '/orders/$orderId/evidence';

  static String newOrderFor(ServiceType service) => Uri(
    path: newOrder,
    queryParameters: {'service': service.wire},
  ).toString();
  static String ridersFor(String orderId) => '/home/orders/$orderId/riders';
  static String riderProfileFor(String orderId) =>
      '/home/orders/$orderId/riders/profile';
  static String quoteFor(String orderId) =>
      '/home/orders/$orderId/riders/quote';
  static String editRouteFor(String orderId) => '/home/orders/$orderId/route';
  static String waitingFor(String orderId) => '/home/orders/$orderId/waiting';
  static String trackingFor(String orderId) => '/home/orders/$orderId/tracking';

  /// [codeSent] is false when arriving from a sign-in on an unconfirmed email.
  static String verifyEmailFor(String email, {required bool codeSent}) => Uri(
    path: verifyEmail,
    queryParameters: {'email': email, 'sent': codeSent ? '1' : '0'},
  ).toString();

  static String resetPasswordFor(String email) =>
      Uri(path: resetPassword, queryParameters: {'email': email}).toString();
}

/// unknown/offline -> splash, signed out -> auth, signed in -> the last-used side
/// (or rider onboarding after "Join as a boda boda rider").
String? sessionRedirect(
  SessionState state,
  String location, {
  bool riderIntent = false,
  AppMode mode = AppMode.sender,
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
      if (riderIntent) return AppRoutes.riderOnboarding;
      return mode == AppMode.rider ? AppRoutes.riderHome : AppRoutes.home;
  }
}

GoRouter buildRouter(
  SessionManager session,
  RiderIntent riderIntent, {
  String initialLocation = AppRoutes.splash,
  AppModeController? mode,
}) => GoRouter(
  initialLocation: initialLocation,
  refreshListenable: Listenable.merge([session, riderIntent]),
  redirect: (context, state) => sessionRedirect(
    session.state,
    state.matchedLocation,
    riderIntent: riderIntent.active,
    mode: mode?.mode ?? AppMode.sender,
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
      builder: (context, state) => const SenderHomeScreen(),
      routes: [
        GoRoute(
          path: 'new',
          builder: (context, state) => NewOrderScreen(
            service:
                ServiceType.fromWire(state.uri.queryParameters['service']) ??
                ServiceType.delivery,
          ),
        ),
        GoRoute(
          path: 'orders/:id/riders',
          builder: (context, state) {
            final args = state.extra is RiderListArgs
                ? state.extra! as RiderListArgs
                : null;
            return RiderListScreen(
              orderId: state.pathParameters['id']!,
              initialOrder: args?.order,
              notice: args?.notice,
            );
          },
          routes: [
            GoRoute(
              path: 'profile',
              redirect: (context, state) => state.extra is RiderChoice
                  ? null
                  : AppRoutes.ridersFor(state.pathParameters['id']!),
              builder: (context, state) =>
                  RiderProfileScreen(choice: state.extra! as RiderChoice),
            ),
            GoRoute(
              path: 'quote',
              redirect: (context, state) => state.extra is RiderChoice
                  ? null
                  : AppRoutes.ridersFor(state.pathParameters['id']!),
              builder: (context, state) =>
                  QuoteScreen(choice: state.extra! as RiderChoice),
            ),
          ],
        ),
        GoRoute(
          path: 'orders/:id/route',
          redirect: (context, state) => state.extra is Order
              ? null
              : AppRoutes.ridersFor(state.pathParameters['id']!),
          builder: (context, state) =>
              EditRouteScreen(order: state.extra! as Order),
        ),
        GoRoute(
          path: 'orders/:id/waiting',
          redirect: (context, state) => state.extra is PendingOffer
              ? null
              : AppRoutes.ridersFor(state.pathParameters['id']!),
          builder: (context, state) =>
              OfferWaitingScreen(pending: state.extra! as PendingOffer),
        ),
        GoRoute(
          path: 'orders/:id/tracking',
          builder: (context, state) => TrackingScreen(
            orderId: state.pathParameters['id']!,
            args: state.extra is TrackingArgs
                ? state.extra! as TrackingArgs
                : null,
          ),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.history,
      builder: (context, state) => OrderHistoryScreen(
        side: state.uri.queryParameters['as'] == 'rider'
            ? AppMode.rider
            : AppMode.sender,
      ),
    ),
    GoRoute(
      path: '/orders/:id',
      builder: (context, state) => OrderDetailScreen(
        orderId: state.pathParameters['id']!,
        asRider: state.uri.queryParameters['as'] == 'rider',
      ),
      routes: [
        GoRoute(
          path: 'evidence',
          builder: (context, state) =>
              EvidenceRecordScreen(orderId: state.pathParameters['id']!),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.notifications,
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => const ProfileScreen(),
      routes: [
        GoRoute(
          path: 'delete',
          builder: (context, state) => const DeleteAccountScreen(),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.settleBalance,
      builder: (context, state) => const SettleBalanceScreen(),
    ),
    GoRoute(
      path: AppRoutes.accountStatus,
      builder: (context, state) => const AccountStatusScreen(),
    ),
    GoRoute(
      path: AppRoutes.riderHome,
      builder: (context, state) => const RiderHomeScreen(),
      routes: [
        GoRoute(
          path: 'onboarding',
          builder: (context, state) => const RiderOnboardingScreen(),
        ),
        GoRoute(
          path: 'documents',
          builder: (context, state) => const DocumentsScreen(),
        ),
        GoRoute(
          path: 'verification',
          builder: (context, state) => const VerificationStatusScreen(),
        ),
        GoRoute(
          path: 'settings',
          builder: (context, state) => const RiderSettingsScreen(),
        ),
        GoRoute(
          path: 'payment-methods',
          builder: (context, state) => const PaymentMethodsScreen(),
        ),
      ],
    ),
  ],
);

final routerProvider = Provider<GoRouter>((ref) {
  final router = buildRouter(
    ref.watch(sessionManagerProvider),
    ref.watch(riderIntentProvider),
    mode: ref.watch(appModeProvider),
  );
  ref.onDispose(router.dispose);
  return router;
});
