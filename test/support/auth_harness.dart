import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ridelink/core/auth/auth_api.dart';
import 'package:ridelink/core/auth/session_manager.dart';
import 'package:ridelink/core/config/app_config.dart';
import 'package:ridelink/core/map/ridelink_map.dart';
import 'package:ridelink/core/navigation/url_opener.dart';
import 'package:ridelink/core/providers.dart';
import 'package:ridelink/core/routing/app_router.dart';
import 'package:ridelink/core/routing/rider_intent.dart';
import 'package:ridelink/features/auth/google_auth.dart';
import 'package:ridelink/features/legal/legal_repository.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import 'package:ridelink/theme/app_theme.dart';

import 'beta_fakes.dart';
import 'fakes.dart';

class FakeGoogleAuth implements GoogleAuth {
  FakeGoogleAuth({this.isConfigured = true, this.result, this.error});

  @override
  final bool isConfigured;
  GoogleCredential? result;
  Object? error;
  int calls = 0;

  @override
  Future<GoogleCredential?> signIn() async {
    calls++;
    if (error != null) throw error!;
    return result;
  }
}

class AuthHarness {
  AuthHarness({
    required this.adapter,
    required this.storage,
    required this.session,
    required this.intent,
    required this.router,
    required this.google,
    required this.legal,
    required this.urls,
  });

  final FakeAdapter adapter;
  final FakeTokenStorage storage;
  final SessionManager session;
  final RiderIntent intent;
  final GoRouter router;
  final FakeGoogleAuth google;
  final FakeLegalRepository legal;
  final FakeUrlOpener urls;

  int count(String path) =>
      adapter.requests.where((r) => r.uri.path == '/v1/$path').length;

  Map<String, dynamic> lastBody(String path) =>
      (adapter.requests.lastWhere((r) => r.uri.path == '/v1/$path').data as Map)
          .cast<String, dynamic>();
}

/// Pumps the real router signed out at [initialLocation], with HTTP served by [handler].
Future<AuthHarness> pumpAuthApp(
  WidgetTester tester, {
  required FakeHandler handler,
  String initialLocation = AppRoutes.auth,
  FakeGoogleAuth? google,
  FakeLegalRepository? legal,
}) async {
  final config = AppConfig(apiBaseUrl: Uri.parse('http://test.local'));
  final adapter = FakeAdapter(handler);
  final storage = FakeTokenStorage();
  final authApi = AuthApi(config, adapter: adapter);
  final session = SessionManager(
    storage: storage,
    authApi: authApi,
    timer: InertTimer.new,
  );
  await session.restore();
  final intent = RiderIntent();
  final router = buildRouter(session, intent, initialLocation: initialLocation);
  final googleAuth = google ?? FakeGoogleAuth(isConfigured: false);
  final legalRepo = legal ?? FakeLegalRepository();
  final urls = FakeUrlOpener();
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        authApiProvider.overrideWithValue(authApi),
        mapEngineProvider.overrideWithValue(null),
        sessionManagerProvider.overrideWithValue(session),
        googleAuthProvider.overrideWithValue(googleAuth),
        riderIntentProvider.overrideWithValue(intent),
        legalRepositoryProvider.overrideWithValue(legalRepo),
        urlOpenerProvider.overrideWithValue(urls),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();

  return AuthHarness(
    adapter: adapter,
    storage: storage,
    session: session,
    intent: intent,
    router: router,
    google: googleAuth,
    legal: legalRepo,
    urls: urls,
  );
}

/// Lets fake HTTP round-trips and resulting rebuilds/navigation complete without
/// waiting out running countdown timers (which pumpAndSettle would).
Future<void> settleIo(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Taps the screen's primary button and lets the request and navigation finish.
Future<void> tapSubmit(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('auth.submit')));
  await tester.tap(find.byKey(const Key('auth.submit')));
  await tester.pumpAndSettle();
}

Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

AppLocalizations l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Scaffold).first));
