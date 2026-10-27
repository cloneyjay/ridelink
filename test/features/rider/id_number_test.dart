import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridelink/core/routing/app_router.dart';
import 'package:ridelink/features/rider/data/rider_models.dart';
import 'package:ridelink/features/rider/onboarding/upload_document_sheet.dart';

import '../../support/booking_fakes.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Finder byKey(String k) => find.byKey(Key(k));

  test('ID number normalizes like the server', () {
    expect(normalizeIdNumber(' 1234 5678 '), '12345678');
    expect(normalizeIdNumber('a-12-b'), 'A12B');
    expect(normalizeIdNumber('123'), isNull);
    expect(normalizeIdNumber('1' * 20), '1' * 20);
    expect(normalizeIdNumber('1' * 21), isNull);
    expect(normalizeIdNumber('12_34'), isNull);
    expect(normalizeIdNumber(''), isNull);
  });

  test('verification JSON carries id_number_recorded', () {
    final v = Verification.fromJson({
      'status': 'pending',
      'documents': [
        {
          'doc_type': 'national_id',
          'status': 'pending',
          'id_number_recorded': true,
        },
        {'doc_type': 'rider_photo', 'status': 'missing'},
      ],
    });
    final id = v.documents.firstWhere((d) => d.type == DocType.nationalId);
    expect(id.idNumberRecorded, isTrue);
    expect(
      v.documents
          .firstWhere((d) => d.type == DocType.riderPhoto)
          .idNumberRecorded,
      isFalse,
    );
  });

  group('upload sheet', () {
    final missing = verificationFixture(
      status: VerificationStatus.pending,
      all: DocStatus.missing,
    );

    testWidgets('national ID requires a valid number and sends it normalized', (
      tester,
    ) async {
      final repo = FakeRiderRepository(verification: missing);
      await pumpBookingApp(
        tester,
        riderRepo: repo,
        goTo: AppRoutes.riderDocuments,
      );
      await tapKeyAndSettle(tester, 'documents.row.national_id');
      expect(byKey('upload.idNumber'), findsOneWidget);
      expect(find.text('National ID number'), findsOneWidget);
      expect(find.text('As printed on your ID'), findsOneWidget);
      await tapKeyAndSettle(tester, 'upload.camera');

      await tapKeyAndSettle(tester, 'upload.submit');
      expect(find.text('Enter your ID number'), findsOneWidget);
      expect(repo.uploads, isEmpty);

      await tester.enterText(byKey('upload.idNumber'), '12');
      await tapKeyAndSettle(tester, 'upload.submit');
      expect(find.text('Enter 4 to 20 letters or digits'), findsOneWidget);
      expect(repo.uploads, isEmpty);

      await tester.enterText(byKey('upload.idNumber'), '1234 5678');
      await tapKeyAndSettle(tester, 'upload.submit');
      expect(repo.uploads.single.type, DocType.nationalId);
      expect(repo.uploads.single.idNumber, '12345678');
      expect(find.text('ID number received'), findsOneWidget);
    });

    testWidgets('other documents have no ID number field', (tester) async {
      final repo = FakeRiderRepository(verification: missing);
      await pumpBookingApp(
        tester,
        riderRepo: repo,
        goTo: AppRoutes.riderDocuments,
      );
      await tapKeyAndSettle(tester, 'documents.row.rider_photo');
      expect(byKey('upload.idNumber'), findsNothing);
      await tapKeyAndSettle(tester, 'upload.gallery');
      await tapKeyAndSettle(tester, 'upload.submit');
      expect(repo.uploads.single.idNumber, isNull);
    });
  });
}
