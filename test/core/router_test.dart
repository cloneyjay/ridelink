import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridelink/core/auth/auth_api.dart';
import 'package:ridelink/core/auth/session.dart';
import 'package:ridelink/core/auth/session_manager.dart';
import 'package:ridelink/core/config/app_config.dart';
import 'package:ridelink/core/routing/app_router.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import 'package:ridelink/theme/app_theme.dart';

import '../support/fakes.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('sessionRedirect', () {
    test('unknown always goes to splash', () {
      expect(
        sessionRedirect(const SessionUnknown(), AppRoutes.home),
        AppRoutes.splash,
      );
      expect(sessionRedirect(const SessionUnknown(), AppRoutes.splash), isNull);
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
      expect(
        sessionRedirect(const SignedOut(), '${AppRoutes.auth}/reset'),
        isNull,
      );
    });

    test('signed in leaves splash and auth for home', () {
      final signedIn = SignedIn(Session.fromJson(sessionJson()));
      expect(sessionRedirect(signedIn, AppRoutes.splash), AppRoutes.home);
      expect(sessionRedirect(signedIn, AppRoutes.auth), AppRoutes.home);
      expect(sessionRedirect(signedIn, AppRoutes.home), isNull);
    });
  });

  testWidgets(
    'router follows session changes: splash -> auth -> home -> auth',
    (tester) async {
      final adapter = FakeAdapter((o) => jsonResponse(204, const {}));
      final session = SessionManager(
        storage: FakeTokenStorage(),
        authApi: AuthApi(
          AppConfig(apiBaseUrl: Uri.parse('http://test.local')),
          adapter: adapter,
        ),
      );
      final router = buildRouter(session);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(
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
}
