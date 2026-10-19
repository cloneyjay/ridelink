import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridelink/core/files/document_picker.dart';
import 'package:ridelink/core/routing/app_router.dart';
import 'package:ridelink/features/booking/data/booking_models.dart';
import 'package:ridelink/features/evidence/data/evidence_models.dart';
import 'package:ridelink/features/evidence/photo_evidence_card.dart';
import 'package:ridelink/features/orders/data/order_models.dart';
import 'package:ridelink/features/rider/data/rider_models.dart';

import '../../support/booking_fakes.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Finder byKey(String k) => find.byKey(Key(k));

  Future<void> pumpFor(WidgetTester tester, [int frames = 12]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> tap(WidgetTester tester, String key) async {
    if (byKey(key).evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        byKey(key),
        200,
        scrollable: find.byType(Scrollable).last,
      );
    }
    await tester.ensureVisible(byKey(key));
    await tester.pump();
    await tester.tap(byKey(key));
    await pumpFor(tester);
  }

  FakeRiderRepository atPickup({String status = 'accepted'}) {
    final job = jobFixture(status: status, arrivedAt: testNow);
    return FakeRiderRepository(
      profile: riderProfileFixture(online: true),
      activeResult: RiderActive(order: job),
    )..job = job;
  }

  final photo = List<int>.generate(200, (i) => i % 251);
  final photoHash = sha256.convert(photo).toString();

  group('evidence capture (screen 9)', () {
    test('hash is lowercase hex SHA-256 of the bytes', () {
      expect(sha256OfBytes(photo), photoHash);
      expect(sha256OfBytes(photo), matches(RegExp(r'^[0-9a-f]{64}$')));
    });

    testWidgets(
      'rider takes the pickup photo with the camera; the device hash is sent',
      (tester) async {
        final picker = FakeDocumentPicker()
          ..next = PickedDocument(bytes: photo, name: 'pickup.jpg');
        final h = await pumpBookingApp(
          tester,
          clock: () => testNow,
          riderRepo: atPickup(),
          picker: picker,
          goTo: AppRoutes.riderHome,
        );
        await tap(tester, 'evidence.pickup_photo.capture');
        expect(picker.sources, [DocumentSource.camera]);
        expect(h.evidence.uploads, hasLength(1));
        final upload = h.evidence.uploads.single;
        expect(upload.orderId, 'order-9');
        expect(upload.kind, MediaKind.pickupPhoto);
        expect(upload.sha256, photoHash);
        expect(upload.bytes, photo);
        expect(byKey('evidence.pickup_photo.done'), findsOneWidget);
      },
    );

    testWidgets('upload shows progress while it runs', (tester) async {
      final evidence = FakeEvidenceRepository()..uploadGate = Completer();
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: atPickup(),
        evidence: evidence,
        goTo: AppRoutes.riderHome,
      );
      await tap(tester, 'evidence.pickup_photo.capture');
      expect(byKey('evidence.pickup_photo.uploading'), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, 0.5);
      evidence.uploadGate!.complete();
      await pumpFor(tester);
      expect(byKey('evidence.pickup_photo.done'), findsOneWidget);
    });

    testWidgets(
      'a failed upload keeps the photo and retries with the same hash',
      (tester) async {
        final evidence = FakeEvidenceRepository()
          ..uploadErrors.add(apiError(422, 'hash_mismatch'));
        final picker = FakeDocumentPicker()
          ..next = PickedDocument(bytes: photo, name: 'pickup.jpg');
        await pumpBookingApp(
          tester,
          clock: () => testNow,
          riderRepo: atPickup(),
          picker: picker,
          evidence: evidence,
          goTo: AppRoutes.riderHome,
        );
        await tap(tester, 'evidence.pickup_photo.capture');
        final l = l10nOf(tester);
        expect(byKey('evidence.pickup_photo.error'), findsOneWidget);
        expect(find.text(l.errCodeHashMismatch), findsOneWidget);

        await tap(tester, 'evidence.pickup_photo.retry');
        expect(picker.sources, hasLength(1), reason: 'retry reuses the photo');
        expect(evidence.uploads, hasLength(2));
        expect(evidence.uploads.map((u) => u.sha256).toSet(), {photoHash});
        expect(byKey('evidence.pickup_photo.done'), findsOneWidget);
      },
    );

    testWidgets('network failure says so; retake opens the camera again', (
      tester,
    ) async {
      final evidence = FakeEvidenceRepository()
        ..uploadErrors.add(apiError(500, 'internal_error'));
      final picker = FakeDocumentPicker();
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: atPickup(),
        picker: picker,
        evidence: evidence,
        goTo: AppRoutes.riderHome,
      );
      await tap(tester, 'evidence.pickup_photo.capture');
      expect(find.text(l10nOf(tester).evidenceUploadFailed), findsOneWidget);
      await tap(tester, 'evidence.pickup_photo.retake');
      expect(picker.sources, hasLength(2));
      expect(byKey('evidence.pickup_photo.done'), findsOneWidget);
    });

    testWidgets('a photo already in the chain shows as added', (tester) async {
      final evidence = FakeEvidenceRepository()
        ..events = [evidenceEventFixture(type: 'pickup_photo')];
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: atPickup(),
        evidence: evidence,
        goTo: AppRoutes.riderHome,
      );
      await tester.scrollUntilVisible(
        byKey('evidence.pickup_photo.done'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(byKey('evidence.pickup_photo.capture'), findsNothing);
    });

    testWidgets('handover photo is offered once paid', (tester) async {
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: atPickup(status: 'paid'),
        goTo: AppRoutes.riderHome,
      );
      await tester.scrollUntilVisible(
        byKey('evidence.handover_photo.capture'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(byKey('evidence.pickup_photo'), findsNothing);
    });

    testWidgets('sender can add an optional item photo before pickup', (
      tester,
    ) async {
      final h = await pumpBookingApp(
        tester,
        repo: FakeBookingRepository()..order = jobFixture(),
        clock: () => testNow,
        goTo: AppRoutes.trackingFor('order-9'),
      );
      await tap(tester, 'evidence.item_photo.capture');
      expect(h.evidence.uploads.single.kind, MediaKind.itemPhoto);
      expect(find.text(l10nOf(tester).optionalLabel), findsNothing);
    });
  });

  group('evidence record (screen 10)', () {
    Future<BookingHarness> openRecord(
      WidgetTester tester, {
      FakeEvidenceRepository? evidence,
    }) {
      final orders = FakeOrdersRepository()
        ..fixedDetails['order-9'] = OrderDetails(
          order: Order(
            id: 'order-9',
            serviceType: ServiceType.delivery,
            status: 'completed',
            pickupAddress: 'A',
            dropoffAddress: 'B',
            senderId: testUserId,
          ),
        );
      return pumpBookingApp(
        tester,
        orders: orders,
        evidence:
            evidence ??
            (FakeEvidenceRepository()
              ..events = [
                evidenceEventFixture(seq: 1, type: 'item_photo'),
                evidenceEventFixture(
                  seq: 2,
                  type: 'pickup_photo',
                  actorId: 'rider-profile',
                ),
                evidenceEventFixture(
                  seq: 3,
                  type: 'payment_requested',
                  actorId: 'rider-profile',
                ),
                evidenceEventFixture(seq: 4, type: 'cash_payment_sent'),
              ]),
        goTo: AppRoutes.evidenceFor('order-9'),
      );
    }

    testWidgets('timeline shows localized events, actors, hashes and photos', (
      tester,
    ) async {
      final h = await openRecord(tester);
      final l = l10nOf(tester);
      expect(byKey('screen.evidence'), findsOneWidget);
      expect(find.text(l.evidenceItemPhoto), findsOneWidget);
      expect(find.text(l.evidencePickupPhoto), findsOneWidget);
      expect(find.text(l.evidenceEventPaymentRequested), findsOneWidget);
      expect(
        find.textContaining('${l.evidenceActorRider} · '),
        findsNWidgets(2),
      );
      expect(find.textContaining('${l.evidenceActorYou} · '), findsWidgets);
      expect(find.text(l.evidenceHash('aaaaaaaa…0001')), findsOneWidget);
      expect(
        byKey('evidence.photo.00000000-0000-0000-0000-000000000001'),
        findsOneWidget,
      );
      expect(
        h.evidence.photoCalls,
        contains('00000000-0000-0000-0000-000000000001'),
      );
      await tester.tap(
        byKey('evidence.photo.00000000-0000-0000-0000-000000000001'),
      );
      await tester.pumpAndSettle();
      expect(byKey('evidence.photoDialog'), findsOneWidget);
    });

    testWidgets('verify: intact with the event count', (tester) async {
      final h = await openRecord(tester);
      final l = l10nOf(tester);
      await tapKeyAndSettle(tester, 'evidence.verify');
      expect(h.evidence.verifyCalls, 1);
      expect(byKey('evidence.verify.intact'), findsOneWidget);
      expect(find.text(l.evidenceIntactBody(3)), findsOneWidget);
    });

    testWidgets('verify: tampered chain', (tester) async {
      final evidence = FakeEvidenceRepository()
        ..verification = const ChainVerification(
          valid: false,
          eventCount: 5,
          error: 'event 3 hash mismatch',
        );
      await openRecord(tester, evidence: evidence);
      await tapKeyAndSettle(tester, 'evidence.verify');
      expect(byKey('evidence.verify.tampered'), findsOneWidget);
      expect(find.text(l10nOf(tester).evidenceTamperedBody(5)), findsOneWidget);
    });

    testWidgets('verify: the check itself failing is not "tampered"', (
      tester,
    ) async {
      final evidence = FakeEvidenceRepository()
        ..verifyError = apiError(500, 'internal_error');
      await openRecord(tester, evidence: evidence);
      await tapKeyAndSettle(tester, 'evidence.verify');
      expect(byKey('evidence.verify.error'), findsOneWidget);
      expect(byKey('evidence.verify.tampered'), findsNothing);
      expect(find.text(l10nOf(tester).evidenceVerifyFailed), findsOneWidget);
    });

    testWidgets('empty record', (tester) async {
      await openRecord(tester, evidence: FakeEvidenceRepository());
      expect(byKey('evidence.empty'), findsOneWidget);
    });

    testWidgets('load failure offers retry', (tester) async {
      final evidence = FakeEvidenceRepository()
        ..chainError = apiError(500, 'internal_error');
      await openRecord(tester, evidence: evidence);
      expect(byKey('evidence.loadError'), findsOneWidget);
      evidence.chainError = null;
      await tapKeyAndSettle(tester, 'evidence.retry');
      expect(byKey('evidence.empty'), findsOneWidget);
    });

    testWidgets('reachable from sender tracking', (tester) async {
      await pumpBookingApp(
        tester,
        repo: FakeBookingRepository()..order = jobFixture(),
        clock: () => testNow,
        goTo: AppRoutes.trackingFor('order-9'),
      );
      await tapKeyAndSettle(tester, 'tracking.evidence');
      expect(byKey('screen.evidence'), findsOneWidget);
    });

    testWidgets('reachable from the rider job', (tester) async {
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: atPickup(),
        goTo: AppRoutes.riderHome,
      );
      await tap(tester, 'job.evidence');
      await tester.pumpAndSettle();
      expect(byKey('screen.evidence'), findsOneWidget);
    });
  });
}
