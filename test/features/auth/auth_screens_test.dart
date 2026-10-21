import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridelink/core/auth/session.dart';
import 'package:ridelink/core/routing/app_router.dart';
import 'package:ridelink/features/auth/google_auth.dart';

import '../../support/auth_harness.dart';
import '../../support/fakes.dart';

Finder byKey(String key) => find.byKey(Key(key));

Future<void> fillSignIn(
  WidgetTester tester,
  String email,
  String password,
) async {
  await tester.enterText(byKey('auth.email'), email);
  await tester.enterText(byKey('auth.password'), password);
}

Future<void> fillSignUp(
  WidgetTester tester, {
  String password = 'correcthorsebattery',
  bool agree = true,
}) async {
  await tester.enterText(byKey('auth.firstName'), 'Moses');
  await tester.enterText(byKey('auth.lastName'), 'Otieno');
  await tester.enterText(byKey('auth.email'), 'moses@example.com');
  await tester.enterText(byKey('auth.password'), password);
  if (agree) await tickTerms(tester);
}

Future<void> tickTerms(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(byKey('signUp.legal.checkbox'));
  await tester.tap(byKey('signUp.legal.checkbox'));
  await tester.pump();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('Sign in', () {
    testWidgets('empty form shows validation errors and sends nothing', (
      tester,
    ) async {
      final h = await pumpAuthApp(tester, handler: routeHandler({}));
      final l = l10n(tester);

      await tapSubmit(tester);

      expect(find.text(l.errorEmailInvalid), findsOneWidget);
      expect(find.text(l.errorPasswordRequired), findsOneWidget);
      expect(h.adapter.requests, isEmpty);
    });

    testWidgets('success stores the session and lands on home', (tester) async {
      final h = await pumpAuthApp(
        tester,
        handler: routeHandler({
          'auth/signin': (o) => jsonResponse(200, sessionJson()),
        }),
      );

      await fillSignIn(tester, ' moses@example.com ', 'any-password');
      await tapSubmit(tester);

      expect(h.lastBody('auth/signin'), {
        'email': 'moses@example.com',
        'password': 'any-password',
      });
      expect(h.session.state, isA<SignedIn>());
      expect(h.storage.refreshToken, 'refresh-1');
      expect(byKey('screen.home'), findsOneWidget);
    });

    testWidgets('401 shows the wrong-credentials message', (tester) async {
      await pumpAuthApp(
        tester,
        handler: routeHandler({
          'auth/signin': (o) =>
              jsonResponse(401, {'error': 'email or password is incorrect'}),
        }),
      );
      final l = l10n(tester);

      await fillSignIn(tester, 'moses@example.com', 'wrong');
      await tapSubmit(tester);

      expect(find.text(l.errorWrongCredentials), findsOneWidget);
      expect(byKey('screen.auth'), findsOneWidget);
    });

    testWidgets(
      '403 email_not_confirmed opens the code screen with resend available',
      (tester) async {
        await pumpAuthApp(
          tester,
          handler: routeHandler({
            'auth/signin': (o) =>
                jsonResponse(403, {'error': 'email_not_confirmed'}),
          }),
        );
        final l = l10n(tester);

        await fillSignIn(tester, 'moses@example.com', 'any-password');
        await tapSubmit(tester);

        expect(byKey('screen.verifyEmail'), findsOneWidget);
        expect(
          find.text(l.verifyNotConfirmed('moses@example.com')),
          findsOneWidget,
        );
        final resend = tester.widget<TextButton>(byKey('auth.resend'));
        expect(resend.onPressed, isNotNull);
      },
    );

    testWidgets('429 and network failures show friendly messages', (
      tester,
    ) async {
      var calls = 0;
      await pumpAuthApp(
        tester,
        handler: routeHandler({
          'auth/signin': (o) {
            calls++;
            if (calls == 1) return jsonResponse(429, {'error': 'slow down'});
            throw const SocketException('offline');
          },
        }),
      );
      final l = l10n(tester);
      await fillSignIn(tester, 'moses@example.com', 'any-password');

      await tapSubmit(tester);
      expect(find.text(l.errorTooManyAttempts), findsOneWidget);

      await tapSubmit(tester);
      expect(find.text(l.errorNetwork), findsOneWidget);
    });

    testWidgets('Google button is hidden when no client id is configured', (
      tester,
    ) async {
      await pumpAuthApp(tester, handler: routeHandler({}));
      expect(byKey('auth.google'), findsNothing);
    });

    testWidgets('Google sign-in sends the ID token and raw nonce', (
      tester,
    ) async {
      final google = FakeGoogleAuth(
        result: const GoogleCredential(
          idToken: 'id-token',
          rawNonce: 'raw-nonce',
        ),
      );
      final h = await pumpAuthApp(
        tester,
        google: google,
        handler: routeHandler({
          'auth/google': (o) => jsonResponse(200, sessionJson()),
        }),
      );

      await tapKey(tester, 'auth.google');

      expect(h.lastBody('auth/google'), {
        'id_token': 'id-token',
        'nonce': 'raw-nonce',
      });
      expect(byKey('screen.home'), findsOneWidget);
    });

    testWidgets(
      'cancelled Google sign-in does nothing; failure shows an error',
      (tester) async {
        final google = FakeGoogleAuth();
        final h = await pumpAuthApp(
          tester,
          google: google,
          handler: routeHandler({}),
        );
        final l = l10n(tester);

        await tapKey(tester, 'auth.google');
        expect(h.count('auth/google'), 0);
        expect(byKey('auth.error'), findsNothing);

        google.error = const GoogleAuthFailure('boom');
        await tapKey(tester, 'auth.google');
        expect(find.text(l.errorGoogleFailed), findsOneWidget);
      },
    );
  });

  group('Sign up', () {
    testWidgets(
      'live hint follows the 15-character rule; short password is rejected',
      (tester) async {
        final h = await pumpAuthApp(
          tester,
          initialLocation: AppRoutes.signUp,
          handler: routeHandler({}),
        );
        final l = l10n(tester);
        Icon hintIcon() => tester.widget<Icon>(
          find.descendant(
            of: byKey('auth.password.hint'),
            matching: find.byType(Icon),
          ),
        );

        await tester.enterText(byKey('auth.password'), 'a' * 14);
        await tester.pump();
        expect(hintIcon().icon, Icons.radio_button_unchecked);

        await fillSignUp(tester, password: 'a' * 14);
        await tapSubmit(tester);
        expect(find.text(l.errorPasswordTooShort), findsOneWidget);
        expect(h.adapter.requests, isEmpty);

        await tester.enterText(byKey('auth.password'), 'a' * 15);
        await tester.pump();
        expect(hintIcon().icon, Icons.check_circle);
      },
    );

    testWidgets('400 is shown localized by its error code', (tester) async {
      await pumpAuthApp(
        tester,
        initialLocation: AppRoutes.signUp,
        handler: routeHandler({
          'auth/signup': (o) => jsonResponse(400, {
            'error': 'this password has appeared in a data breach; choose a different one',
            'code': 'password_breached',
          }),
        }),
      );

      await fillSignUp(tester);
      await tapSubmit(tester);

      expect(find.text(l10n(tester).errCodePasswordBreached), findsOneWidget);
    });

    testWidgets(
      'success posts trimmed details and opens the code screen, resend locked',
      (tester) async {
        final h = await pumpAuthApp(
          tester,
          initialLocation: AppRoutes.signUp,
          handler: routeHandler({'auth/signup': (o) => emptyResponse(202)}),
        );
        final l = l10n(tester);

        await tester.enterText(byKey('auth.firstName'), '  Moses ');
        await tester.enterText(byKey('auth.lastName'), 'Otieno');
        await tester.enterText(byKey('auth.email'), 'moses@example.com');
        await tester.enterText(byKey('auth.password'), 'correcthorsebattery');
        await tickTerms(tester);
        await tester.ensureVisible(byKey('auth.submit'));
        await tester.tap(byKey('auth.submit'));
        await settleIo(tester);

        expect(h.lastBody('auth/signup'), {
          'email': 'moses@example.com',
          'first_name': 'Moses',
          'last_name': 'Otieno',
          'password': 'correcthorsebattery',
          'accepted_terms_version': '2026-10-01',
          'accepted_privacy_version': '2026-10-02',
        });
        expect(byKey('screen.verifyEmail'), findsOneWidget);
        expect(find.text(l.verifySentTo('moses@example.com')), findsOneWidget);
        expect(
          tester.widget<TextButton>(byKey('auth.resend')).onPressed,
          isNull,
        );
      },
    );
  });

  group('Email code', () {
    testWidgets('resend unlocks after 60 seconds, sends, and locks again', (
      tester,
    ) async {
      final h = await pumpAuthApp(
        tester,
        initialLocation: AppRoutes.verifyEmailFor(
          'moses@example.com',
          codeSent: true,
        ),
        handler: routeHandler({
          'auth/signup/resend': (o) => emptyResponse(202),
        }),
      );
      final l = l10n(tester);
      TextButton resend() => tester.widget<TextButton>(byKey('auth.resend'));

      expect(find.text(l.resendIn(60)), findsOneWidget);
      expect(resend().onPressed, isNull);

      await tester.pump(const Duration(seconds: 59));
      expect(find.text(l.resendIn(1)), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(resend().onPressed, isNotNull);

      await tester.ensureVisible(byKey('auth.resend'));
      await tester.tap(byKey('auth.resend'));
      await settleIo(tester);
      expect(h.lastBody('auth/signup/resend'), {'email': 'moses@example.com'});
      expect(find.text(l.codeResent), findsOneWidget);
      expect(resend().onPressed, isNull);

      await tester.pump(const Duration(seconds: 61));
    });

    testWidgets(
      'pasted code with spaces auto-submits; wrong code shows an error',
      (tester) async {
        final h = await pumpAuthApp(
          tester,
          initialLocation: AppRoutes.verifyEmailFor(
            'moses@example.com',
            codeSent: true,
          ),
          handler: routeHandler({
            'auth/signup/verify': (o) =>
                jsonResponse(401, {'error': 'invalid or expired code'}),
          }),
        );
        final l = l10n(tester);

        await tester.enterText(byKey('auth.code'), '123 456');
        await settleIo(tester);

        expect(h.lastBody('auth/signup/verify'), {
          'email': 'moses@example.com',
          'code': '123456',
        });
        expect(find.text(l.errorInvalidCode), findsOneWidget);
        await tester.pump(const Duration(seconds: 61));
      },
    );

    testWidgets('correct code signs in and lands on home', (tester) async {
      final h = await pumpAuthApp(
        tester,
        initialLocation: AppRoutes.verifyEmailFor(
          'moses@example.com',
          codeSent: false,
        ),
        handler: routeHandler({
          'auth/signup/verify': (o) => jsonResponse(200, sessionJson()),
        }),
      );

      await tester.enterText(byKey('auth.code'), '123456');
      await tester.pumpAndSettle();

      expect(h.session.state, isA<SignedIn>());
      expect(byKey('screen.home'), findsOneWidget);
    });
  });

  group('Password reset', () {
    testWidgets('forgot -> reset -> signed in on home', (tester) async {
      final h = await pumpAuthApp(
        tester,
        handler: routeHandler({
          'auth/password/forgot': (o) => emptyResponse(202),
          'auth/password/reset': (o) => jsonResponse(200, sessionJson()),
        }),
      );
      final l = l10n(tester);

      await tapKey(tester, 'auth.forgot');
      expect(byKey('screen.forgotPassword'), findsOneWidget);
      await tester.enterText(byKey('auth.email'), 'moses@example.com');
      await tester.ensureVisible(byKey('auth.submit'));
      await tester.tap(byKey('auth.submit'));
      await settleIo(tester);

      expect(byKey('screen.resetPassword'), findsOneWidget);
      expect(find.text(l.resetSentTo('moses@example.com')), findsOneWidget);

      await tester.enterText(byKey('auth.code'), '654321');
      await tester.enterText(
        byKey('auth.password'),
        'a brand new long password',
      );
      await tester.ensureVisible(byKey('auth.submit'));
      await tester.tap(byKey('auth.submit'));
      await settleIo(tester);

      expect(h.lastBody('auth/password/reset'), {
        'email': 'moses@example.com',
        'code': '654321',
        'new_password': 'a brand new long password',
      });
      expect(byKey('screen.home'), findsOneWidget);
    });

    testWidgets('bad reset code shows the invalid-code message', (
      tester,
    ) async {
      await pumpAuthApp(
        tester,
        initialLocation: AppRoutes.resetPasswordFor('moses@example.com'),
        handler: routeHandler({
          'auth/password/reset': (o) =>
              jsonResponse(401, {'error': 'invalid or expired code'}),
        }),
      );
      final l = l10n(tester);

      await tester.enterText(byKey('auth.code'), '654321');
      await tester.enterText(
        byKey('auth.password'),
        'a brand new long password',
      );
      await tester.ensureVisible(byKey('auth.submit'));
      await tester.tap(byKey('auth.submit'));
      await settleIo(tester);

      expect(find.text(l.errorInvalidCode), findsOneWidget);
      await tester.pump(const Duration(seconds: 61));
    });
  });

  group('Rider intent', () {
    testWidgets(
      '"Join as a boda boda rider" -> sign up -> code -> rider onboarding',
      (tester) async {
        final h = await pumpAuthApp(
          tester,
          handler: routeHandler({
            'auth/signup': (o) => emptyResponse(202),
            'auth/signup/verify': (o) => jsonResponse(200, sessionJson()),
          }),
        );
        final l = l10n(tester);

        await tapKey(tester, 'auth.joinRider');
        expect(byKey('screen.signUp'), findsOneWidget);
        expect(find.text(l.signUpRiderNote), findsOneWidget);
        expect(h.intent.active, isTrue);

        await fillSignUp(tester);
        await tester.ensureVisible(byKey('auth.submit'));
        await tester.tap(byKey('auth.submit'));
        await settleIo(tester);
        expect(byKey('screen.verifyEmail'), findsOneWidget);

        await tester.enterText(byKey('auth.code'), '123456');
        await settleIo(tester);

        expect(byKey('screen.riderOnboarding'), findsOneWidget);
        expect(h.intent.active, isFalse);
      },
    );
  });
}
