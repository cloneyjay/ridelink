import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridelink/core/api/api_exception.dart';
import 'package:ridelink/core/routing/app_router.dart';
import 'package:ridelink/features/rider/data/rider_models.dart';

import '../../support/booking_fakes.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Finder byKey(String k) => find.byKey(Key(k));

  group('registration', () {
    testWidgets('new rider registers with a normalized plate, then documents', (
      tester,
    ) async {
      final repo = FakeRiderRepository(
        registered: false,
        verification: verificationFixture(
          status: VerificationStatus.pending,
          all: DocStatus.missing,
        ),
      );
      final h = await pumpBookingApp(
        tester,
        riderRepo: repo,
        goTo: AppRoutes.riderOnboarding,
      );
      expect(byKey('screen.riderOnboarding'), findsOneWidget);
      expect(byKey('onboarding.vehicle'), findsOneWidget);

      await tester.enterText(byKey('onboarding.plate'), 'k');
      await tapKeyAndSettle(tester, 'onboarding.submit');
      expect(find.text(l10nOf(tester).plateInvalid), findsOneWidget);
      expect(repo.registerCalls, isEmpty);

      await tester.enterText(byKey('onboarding.plate'), ' kmfa  123b');
      await tapKeyAndSettle(tester, 'onboarding.submit');
      expect(repo.registerCalls, ['KMFA 123B']);
      expect(byKey('screen.riderDocuments'), findsOneWidget);
      expect(h.router.state.matchedLocation, AppRoutes.riderDocuments);
    });

    testWidgets('server validation message is shown', (tester) async {
      final repo = FakeRiderRepository(registered: false)
        ..registerError = const ApiException(
          statusCode: 400,
          message: 'plate_number must be 3 to 12 letters, digits or spaces',
        );
      await pumpBookingApp(
        tester,
        riderRepo: repo,
        goTo: AppRoutes.riderOnboarding,
      );
      await tester.enterText(byKey('onboarding.plate'), 'KMFA 123B');
      await tapKeyAndSettle(tester, 'onboarding.submit');
      expect(byKey('onboarding.serverError'), findsOneWidget);
    });

    testWidgets('already registered goes straight to the checklist', (
      tester,
    ) async {
      await pumpBookingApp(tester, goTo: AppRoutes.riderOnboarding);
      expect(byKey('screen.riderDocuments'), findsOneWidget);
    });
  });

  group('document checklist', () {
    final mixed = verificationFixture(
      status: VerificationStatus.pending,
      overrides: {
        DocType.riderPhoto: const DocumentState(
          type: DocType.riderPhoto,
          status: DocStatus.missing,
        ),
        DocType.nationalId: const DocumentState(
          type: DocType.nationalId,
          status: DocStatus.pending,
        ),
        DocType.psvInsurance: DocumentState(
          type: DocType.psvInsurance,
          status: DocStatus.rejected,
          rejectionReason: 'Certificate is blurry',
          expiresOn: DateTime(2027, 3, 1),
        ),
        DocType.drivingLicence: DocumentState(
          type: DocType.drivingLicence,
          status: DocStatus.approved,
          expiresOn: DateTime(2027, 6, 30),
          current: true,
        ),
      },
    );

    testWidgets('shows per-document status, rejection reason and expiry', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 4000);
      tester.view.devicePixelRatio = 1.5;
      addTearDown(tester.view.reset);
      await pumpBookingApp(
        tester,
        riderRepo: FakeRiderRepository(verification: mixed),
        goTo: AppRoutes.riderDocuments,
      );
      final l = l10nOf(tester);
      Text status(String t) =>
          tester.widget<Text>(byKey('documents.status.$t'));
      expect(status('rider_photo').data, l.docStatusMissing);
      expect(status('national_id').data, l.docStatusPending);
      expect(status('psv_insurance').data, l.docStatusRejected);
      expect(status('driving_licence').data, l.docStatusApproved);
      expect(
        find.text(l.docRejectedReason('Certificate is blurry')),
        findsOneWidget,
      );
      expect(find.textContaining('2027'), findsWidgets);
      expect(find.text(l.documentsProgress(5, 7)), findsOneWidget);
      final cont = tester.widget<ElevatedButton>(
        find.descendant(
          of: byKey('documents.continue'),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(cont.onPressed, isNull);
    });

    testWidgets('uploads a document from the gallery and refreshes', (
      tester,
    ) async {
      final repo = FakeRiderRepository(verification: mixed);
      final h = await pumpBookingApp(
        tester,
        riderRepo: repo,
        goTo: AppRoutes.riderDocuments,
      );
      await tapKeyAndSettle(tester, 'documents.row.rider_photo');
      expect(byKey('upload.sheet'), findsOneWidget);
      // Photo-only documents don't offer PDFs.
      expect(byKey('upload.file'), findsNothing);
      await tapKeyAndSettle(tester, 'upload.gallery');
      expect(byKey('upload.fileName'), findsOneWidget);
      await tapKeyAndSettle(tester, 'upload.submit');

      expect(repo.uploads.single.type, DocType.riderPhoto);
      expect(h.picker.sources.single.name, 'gallery');
      expect(byKey('documents.uploaded'), findsOneWidget);
      expect(
        tester.widget<Text>(byKey('documents.status.rider_photo')).data,
        l10nOf(tester).docStatusPending,
      );
    });

    testWidgets('expiring documents need a date before upload', (tester) async {
      final repo = FakeRiderRepository(verification: mixed);
      await pumpBookingApp(
        tester,
        riderRepo: repo,
        goTo: AppRoutes.riderDocuments,
      );
      await tapKeyAndSettle(tester, 'documents.row.psv_insurance');
      expect(byKey('upload.date'), findsOneWidget);
      expect(byKey('upload.file'), findsOneWidget);
      await tapKeyAndSettle(tester, 'upload.camera');
      await tapKeyAndSettle(tester, 'upload.submit');
      expect(find.text(l10nOf(tester).docDateRequired), findsOneWidget);
      expect(repo.uploads, isEmpty);

      await tapKeyAndSettle(tester, 'upload.date');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tapKeyAndSettle(tester, 'upload.submit');
      expect(repo.uploads.single.expires, isNotNull);
      expect(repo.uploads.single.issued, isNull);
    });

    testWidgets('server upload error is shown localized in the sheet', (
      tester,
    ) async {
      final repo = FakeRiderRepository(verification: mixed)
        ..uploadError = const ApiException(
          statusCode: 400,
          code: 'invalid_file_type',
          message: 'file must be a JPEG, PNG or PDF',
        );
      await pumpBookingApp(
        tester,
        riderRepo: repo,
        goTo: AppRoutes.riderDocuments,
      );
      await tapKeyAndSettle(tester, 'documents.row.national_id');
      await tapKeyAndSettle(tester, 'upload.gallery');
      await tapKeyAndSettle(tester, 'upload.submit');
      expect(find.text(l10nOf(tester).errCodeInvalidFileType), findsOneWidget);
    });
  });

  group('overall status', () {
    Future<void> open(WidgetTester tester, Verification v) => pumpBookingApp(
      tester,
      riderRepo: FakeRiderRepository(verification: v),
      goTo: AppRoutes.riderVerification,
    );

    testWidgets('pending review', (tester) async {
      await open(
        tester,
        verificationFixture(
          status: VerificationStatus.pending,
          all: DocStatus.pending,
        ),
      );
      expect(byKey('verification.pending'), findsOneWidget);
    });

    testWidgets('approved offers the rider home', (tester) async {
      await open(tester, verificationFixture());
      expect(byKey('verification.approved'), findsOneWidget);
      await tapKeyAndSettle(tester, 'verification.goHome');
      expect(byKey('screen.riderHome'), findsOneWidget);
    });

    testWidgets('rejected sends the rider to fix documents', (tester) async {
      await open(
        tester,
        verificationFixture(
          status: VerificationStatus.rejected,
          overrides: {
            DocType.nationalId: const DocumentState(
              type: DocType.nationalId,
              status: DocStatus.rejected,
              rejectionReason: 'Name does not match',
            ),
          },
        ),
      );
      expect(byKey('verification.rejected'), findsOneWidget);
      await tapKeyAndSettle(tester, 'verification.documents');
      expect(byKey('screen.riderDocuments'), findsOneWidget);
    });
  });

  group('pricing and settings', () {
    testWidgets('shows allowed ranges and current values', (tester) async {
      await pumpBookingApp(tester, goTo: AppRoutes.riderSettings);
      final l = l10nOf(tester);
      expect(find.text(l.settingsPickupRadiusHelp('3 km')), findsOneWidget);
      expect(find.text(l.settingsMaxDistanceHelp('10 km')), findsOneWidget);
      expect(
        find.text(l.settingsRateRange('KES 16', 'KES 32')),
        findsNWidgets(2),
      );
      expect(find.text('1.8'), findsOneWidget);
    });

    testWidgets('values outside the limits are rejected locally', (
      tester,
    ) async {
      final h = await pumpBookingApp(tester, goTo: AppRoutes.riderSettings);
      await tester.enterText(byKey('settings.pickupRadius'), '4');
      await tester.enterText(byKey('settings.maxDistance'), '5');
      await tester.enterText(byKey('settings.deliveryRate'), '40');
      await tapKeyAndSettle(tester, 'settings.save');
      final l = l10nOf(tester);
      expect(find.text(l.settingsRadiusTooHigh('3 km')), findsOneWidget);
      expect(find.text(l.settingsDistanceTooLow('10 km')), findsOneWidget);
      expect(
        find.text(l.settingsRateRange('KES 16', 'KES 32')),
        findsNWidgets(2),
      );
      expect(h.riderRepo.settingsCalls, isEmpty);
    });

    testWidgets('valid values are saved with PATCH', (tester) async {
      final h = await pumpBookingApp(tester, goTo: AppRoutes.riderSettings);
      await tester.enterText(byKey('settings.pickupRadius'), '2.5');
      await tester.enterText(byKey('settings.rideRate'), '24');
      await tapKeyAndSettle(tester, 'settings.save');
      final saved = h.riderRepo.settingsCalls.single;
      expect(saved.pickupRadiusKm, 2.5);
      expect(saved.ridePricePerKm, 24);
      expect(saved.maxDistanceKm, 10);
      expect(byKey('settings.saved'), findsOneWidget);
    });
  });
}
