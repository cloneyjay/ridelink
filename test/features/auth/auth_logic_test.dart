import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ridelink/core/api/api_exception.dart';
import 'package:ridelink/core/auth/nonce.dart';
import 'package:ridelink/features/auth/auth_errors.dart';
import 'package:ridelink/features/auth/auth_validators.dart';
import 'package:ridelink/l10n/app_localizations_en.dart';

void main() {
  final l = AppLocalizationsEn();

  group('nonce', () {
    test('sha256Hex matches the FIPS 180-2 "abc" vector', () {
      expect(
        sha256Hex('abc'),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });

    test('raw nonce is 32 URL-safe characters and differs each time', () {
      final a = generateRawNonce();
      final b = generateRawNonce();
      expect(a, hasLength(32));
      expect(RegExp(r'^[0-9A-Za-z\-._]+$').hasMatch(a), isTrue);
      expect(a, isNot(b));
    });

    test('raw nonce is deterministic for a seeded source (testability)', () {
      expect(
        generateRawNonce(random: Random(1)),
        generateRawNonce(random: Random(1)),
      );
    });
  });

  group('new password (NIST: 15–72, no composition rules)', () {
    test('14 characters is too short, 15 is fine', () {
      expect(validateNewPassword('a' * 14, l), l.errorPasswordTooShort);
      expect(validateNewPassword('a' * 15, l), isNull);
    });

    test('72 bytes is fine, 73 is too long', () {
      expect(validateNewPassword('a' * 72, l), isNull);
      expect(validateNewPassword('a' * 73, l), l.errorPasswordTooLong);
    });

    test(
      'length counts characters for the minimum and bytes for the maximum',
      () {
        // 15 two-byte characters: long enough, 30 bytes.
        expect(validateNewPassword('é' * 15, l), isNull);
        // 37 two-byte characters = 74 bytes: too long.
        expect(validateNewPassword('é' * 37, l), l.errorPasswordTooLong);
      },
    );

    test('no composition rules: all lowercase letters are accepted', () {
      expect(validateNewPassword('correcthorsebatterystaple', l), isNull);
    });
  });

  group('other validators', () {
    test('email', () {
      expect(validateEmail('moses@example.com', l), isNull);
      expect(validateEmail('  moses@example.com ', l), isNull);
      expect(validateEmail('moses@example', l), l.errorEmailInvalid);
      expect(validateEmail('', l), l.errorEmailInvalid);
    });

    test('names are required, trimmed and at most 50 characters', () {
      expect(validateFirstName('  ', l), l.errorFirstNameRequired);
      expect(validateLastName('', l), l.errorLastNameRequired);
      expect(validateFirstName('a' * 50, l), isNull);
      expect(validateFirstName('a' * 51, l), l.errorNameTooLong);
    });

    test('existing password only needs to be non-empty', () {
      expect(validateExistingPassword('', l), l.errorPasswordRequired);
      expect(validateExistingPassword('short', l), isNull);
    });

    test('code is exactly six digits', () {
      expect(validateCode('123456', l), isNull);
      expect(validateCode('12345', l), l.errorCodeFormat);
      expect(validateCode('12345a', l), l.errorCodeFormat);
    });
  });

  group('authErrorMessage', () {
    String msg(int? status, {String m = 'x', AuthUnauthorized? on401}) =>
        authErrorMessage(
          ApiException(statusCode: status, message: m),
          l,
          on401: on401 ?? AuthUnauthorized.wrongCredentials,
        );

    test('400 shows the server message', () {
      expect(
        msg(400, m: 'this password has appeared in a data breach'),
        'this password has appeared in a data breach',
      );
    });

    test('401 depends on the screen', () {
      expect(msg(401), l.errorWrongCredentials);
      expect(msg(401, on401: AuthUnauthorized.invalidCode), l.errorInvalidCode);
      expect(msg(401, on401: AuthUnauthorized.google), l.errorGoogleFailed);
    });

    test('429, 5xx and network errors get friendly strings', () {
      expect(msg(429), l.errorTooManyAttempts);
      expect(msg(502), l.errorServiceUnavailable);
      expect(msg(null), l.errorNetwork);
      expect(msg(418), l.errorGeneric);
    });

    test('403 email_not_confirmed is recognised', () {
      expect(
        const ApiException(
          statusCode: 403,
          message: 'email_not_confirmed',
        ).isEmailNotConfirmed,
        isTrue,
      );
    });
  });
}
