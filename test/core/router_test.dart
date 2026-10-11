import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridelink/core/auth/auth_api.dart';
import 'package:ridelink/core/auth/session.dart';
import 'package:ridelink/core/auth/session_manager.dart';
import 'package:ridelink/core/config/app_config.dart';
import 'package:ridelink/core/providers.dart';
import 'package:ridelink/core/routing/app_router.dart';
import 'package:ridelink/core/routing/rider_intent.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import 'package:ridelink/theme/app_theme.dart';

import '../support/auth_harness.dart';
import '../support/fakes.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('sessionRedirect', () {
    test('unknown and offline always go to splash', () {
      for (final state in const [SessionUnknown(), SessionOffline()]) {
        expect(sessionRedirect(state, AppRoutes.home), AppRoutes.splash);
        expect(sessionRedirect(state, AppRoutes.auth), AppRoutes.splash);
        expect(sessionRedirect(state, AppRoutes.splash), isNull);
      }
    });

    test('signed out goes to auth and stays within auth', () {
      expect(
        sessionRedirect(const SignedOut(), AppRoutes.splash),
        AppRoutes.auth,
      );
      expect(
        sessionRedirect(const SignedOut(), AppRoutes.home),
        AppRoutes.auth,
      );
      expect(sessionRedirect(const SignedOut(), AppRoutes.auth), isNull);
      expect(sessionRedirect(const SignedOut(), AppRoutes.signUp), isNull);
      expect(
        sessionRedirect(const SignedOut(), AppRoutes.resetPassword),
        isNull,
      );
    });

    test('signed in leaves splash and auth for home', () {
      final signedIn = SignedIn(Session.fromJson(sessionJson()));
      expect(sessionRedirect(signedIn, AppRoutes.splash), AppRoutes.home);
      expect(sessionRedirect(signedIn, AppRoutes.auth), AppRoutes.home);
      expect(sessionRedirect(signedIn, AppRoutes.verifyEmail), AppRoutes.home);
      expect(sessionRedirect(signedIn, AppRoutes.home), isNull);
    });

    test('signed in with rider intent goes to rider onboarding', () {
      final signedIn = SignedIn(Session.fromJson(sessionJson()));
      expect(
        sessionRedirect(signedIn, AppRoutes.auth, riderIntent: true),
        AppRoutes.riderOnboarding,
      );
      expect(
        sessionRedirect(signedIn, AppRoutes.riderOnboarding, riderIntent: true),
        isNull,
      );
    });
  });

  Widget appFor(SessionManager session, RiderIntent intent, AppConfig config) {
    final router = buildRouter(session, intent);
    addTearDown(router.dispose);
    return ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        sessionManagerProvider.overrideWithValue(session),
        riderIntentProvider.overrideWithValue(intent),
        googleAuthProvider.overrideWithValue(
          FakeGoogleAuth(isConfigured: false),
        ),
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
    );
  }

  testWidgets(
    'router follows session changes: splash -> auth -> home -> auth',
    (tester) async {
      final config = AppConfig(apiBaseUrl: Uri.parse('http://test.local'));
      final session = SessionManager(
        storage: FakeTokenStorage(),
        authApi: AuthApi(
          config,
          adapter: FakeAdapter((o) => jsonResponse(204, const {})),
        ),
      );

      await tester.pumpWidget(appFor(session, RiderIntent(), config));
      await tester.pump();
      expect(find.byKey(const Key('screen.splash')), findsOneWidget);

      await tester.runAsync(session.restore);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('screen.auth')), findsOneWidget);

      await tester.runAsync(
        () => session.setSession(Session.fromJson(sessionJson())),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('screen.home')), findsOneWidget);

      await tester.runAsync(session.signOut);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('screen.auth')), findsOneWidget);
    },
  );

  testWidgets(
    'offline at launch keeps the session, shows Retry, and Retry signs in',
    (tester) async {
      var online = false;
      final config = AppConfig(apiBaseUrl: Uri.parse('http://test.local'));
      final storage = FakeTokenStorage('stored-refresh');
      final session = SessionManager(
        storage: storage,
        authApi: AuthApi(
          config,
          adapter: FakeAdapter((o) {
            if (!online) throw const SocketException('offline');
            return jsonResponse(200, sessionJson());
          }),
        ),
      );

      await tester.pumpWidget(appFor(session, RiderIntent(), config));
      await tester.runAsync(session.restore);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('splash.offline')), findsOneWidget);
      expect(find.byKey(const Key('screen.auth')), findsNothing);
      expect(storage.refreshToken, 'stored-refresh');

      online = true;
      await tester.tap(find.byKey(const Key('splash.retry')));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();

      expect(session.state, isA<SignedIn>());
      expect(find.byKey(const Key('screen.home')), findsOneWidget);
    },
  );
}
