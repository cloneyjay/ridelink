import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridelink/core/api/api_exception.dart';
import 'package:ridelink/core/errors/error_messages.dart';
import 'package:ridelink/l10n/app_localizations.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final sw = lookupAppLocalizations(const Locale('sw'));

  group('error-code localization', () {
    test('every code in the backend contract has EN and SW text', () {
      for (final code in knownErrorCodes) {
        final english = errorCodeMessage(code, en);
        final swahili = errorCodeMessage(code, sw);
        expect(english, isNotNull, reason: code);
        expect(english, isNotEmpty, reason: code);
        expect(swahili, isNotNull, reason: code);
        expect(swahili, isNotEmpty, reason: code);
      }
      expect(knownErrorCodes.toSet().length, knownErrorCodes.length);
    });

    test(
      'the code list matches respond/codes.go when the backend is checked out',
      () {
        final file = File(
          '../../Back_end/ridelink-backend/internal/respond/codes.go',
        );
        if (!file.existsSync()) {
          markTestSkipped('backend source not available');
          return;
        }
        final goCodes = RegExp(
          r'^\s*Code\w+\s*=\s*"([a-z_]+)"',
          multiLine: true,
        ).allMatches(file.readAsStringSync()).map((m) => m.group(1)!).toSet();
        expect(goCodes, isNotEmpty);
        expect(knownErrorCodes.toSet(), goCodes);
      },
    );

    test('evidence_photo_required names the missing photo by kind', () {
      ApiException missing(String? kind) => ApiException(
        statusCode: 422,
        code: 'evidence_photo_required',
        message: 'take the photo first',
        body: {'code': 'evidence_photo_required', 'kind': ?kind},
      );
      for (final l in [en, sw]) {
        expect(
          apiErrorText(missing('pickup_photo'), l),
          l.errCodeEvidencePickupPhotoRequired,
        );
        expect(
          apiErrorText(missing('handover_photo'), l),
          l.errCodeEvidenceHandoverPhotoRequired,
        );
        expect(apiErrorText(missing(null), l), l.errCodeEvidencePhotoRequired);
      }
      expect(
        sw.errCodeEvidencePickupPhotoRequired,
        isNot(en.errCodeEvidencePickupPhotoRequired),
      );
    });

    test('an unknown code shows the server text', () {
      const e = ApiException(
        statusCode: 400,
        code: 'brand_new_code',
        message: 'Something specific',
      );
      expect(apiErrorText(e, en), 'Something specific');
    });

    test('a known code wins over the server text, in the device language', () {
      const e = ApiException(
        statusCode: 422,
        code: 'hash_mismatch',
        message: 'the photo hash differs',
      );
      expect(apiErrorText(e, en), en.errCodeHashMismatch);
      expect(apiErrorText(e, sw), sw.errCodeHashMismatch);
      expect(sw.errCodeHashMismatch, isNot(en.errCodeHashMismatch));
    });

    test('network and server failures use the screen fallback', () {
      const network = ApiException(message: 'connection refused');
      const server = ApiException(
        statusCode: 500,
        code: 'internal_error',
        message: 'internal error',
      );
      expect(apiErrorText(network, en), en.errorNetwork);
      expect(apiErrorText(network, en, fallback: 'Fallback'), 'Fallback');
      expect(apiErrorText(server, en, fallback: 'Fallback'), 'Fallback');
      expect(apiErrorText(server, en), en.errCodeInternalError);
    });

    test('responses without a code map by status, then generic', () {
      expect(
        apiErrorText(const ApiException(statusCode: 409, message: 'x'), en),
        en.errCodeConflict,
      );
      expect(
        apiErrorText(const ApiException(statusCode: 418, message: 'x'), en),
        en.errorGeneric,
      );
      expect(apiErrorText(StateError('boom'), en), en.errorGeneric);
    });
  });
}
