import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridelink/core/api/api_exception.dart';
import 'package:ridelink/core/routing/app_router.dart';
import 'package:ridelink/features/booking/data/booking_models.dart';
import 'package:ridelink/features/evidence/data/evidence_models.dart';
import 'package:ridelink/features/rider/data/rider_models.dart';
import 'package:ridelink/features/rider/job/job_logic.dart';

import '../../support/booking_fakes.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Finder byKey(String k) => find.byKey(Key(k));

  Future<void> pumpFor(WidgetTester tester, [int frames = 12]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> reveal(WidgetTester tester, String key) async {
    if (byKey(key).evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        byKey(key),
        200,
        scrollable: find.byType(Scrollable).last,
      );
    }
    await tester.ensureVisible(byKey(key));
    await tester.pump();
  }

  Future<void> tap(WidgetTester tester, String key) async {
    await reveal(tester, key);
    await tester.tap(byKey(key));
    await pumpFor(tester);
  }

  bool enabled(WidgetTester tester, String key) =>
      tester
          .widget<ElevatedButton>(
            find.descendant(
              of: byKey(key),
              matching: find.byType(ElevatedButton),
            ),
          )
          .onPressed !=
      null;

  FakeRiderRepository withJob(
    String status, {
    ServiceType service = ServiceType.delivery,
  }) {
    final job = jobFixture(
      status: status,
      arrivedAt: testNow,
      service: service,
    );
    return FakeRiderRepository(
      profile: riderProfileFixture(online: true),
      activeResult: RiderActive(order: job),
    )..job = job;
  }

  group('required photos (deliveries only)', () {
    test('rules: deliveries need pickup and handover photos, rides none', () {
      final delivery = jobFixture(arrivedAt: testNow);
      final ride = jobFixture(arrivedAt: testNow, service: ServiceType.ride);
      expect(
        requiredPhoto(delivery, JobAction.pickedUp),
        MediaKind.pickupPhoto,
      );
      expect(
        requiredPhoto(delivery, JobAction.handOver),
        MediaKind.handoverPhoto,
      );
      expect(
        requiredPhoto(delivery, JobAction.confirmPayment),
        MediaKind.handoverPhoto,
      );
      expect(
        photoStepFor(jobFixture(status: 'payment_requested')),
        MediaKind.handoverPhoto,
      );
      expect(requiredPhoto(ride, JobAction.confirmPayment), isNull);
      expect(
        photoStepFor(
          jobFixture(status: 'payment_requested', service: ServiceType.ride),
        ),
        isNull,
      );
      expect(requiredPhoto(delivery, JobAction.startTrip), isNull);
      expect(requiredPhoto(ride, JobAction.pickedUp), isNull);
      expect(requiredPhoto(ride, JobAction.handOver), isNull);
      expect(photoStepFor(ride), isNull);
      expect(
        photoStepFor(jobFixture(status: 'paid', service: ServiceType.ride)),
        isNull,
      );
    });

    testWidgets('"Picked up" is disabled until the pickup photo is uploaded', (
      tester,
    ) async {
      final repo = withJob('accepted');
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: repo,
        goTo: AppRoutes.riderHome,
      );
      await reveal(tester, 'job.action.pickedUp');
      expect(enabled(tester, 'job.action.pickedUp'), isFalse);
      expect(byKey('job.photoRequired'), findsOneWidget);
      expect(find.text(l10nOf(tester).jobPickupPhotoRequired), findsOneWidget);

      await tap(tester, 'evidence.pickup_photo.capture');
      await reveal(tester, 'job.action.pickedUp');
      expect(enabled(tester, 'job.action.pickedUp'), isTrue);
      expect(byKey('job.photoRequired'), findsNothing);
      await tap(tester, 'job.action.pickedUp');
      expect(repo.jobCalls, ['status:started']);
    });

    testWidgets('a photo already in the chain unlocks the action', (
      tester,
    ) async {
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: withJob('accepted'),
        evidence: FakeEvidenceRepository()
          ..events = [evidenceEventFixture(type: 'pickup_photo')],
        goTo: AppRoutes.riderHome,
      );
      await reveal(tester, 'job.action.pickedUp');
      expect(enabled(tester, 'job.action.pickedUp'), isTrue);
    });

    testWidgets('"Hand over" is disabled until the handover photo', (
      tester,
    ) async {
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: withJob('paid'),
        goTo: AppRoutes.riderHome,
      );
      await reveal(tester, 'job.action.handOver');
      expect(enabled(tester, 'job.action.handOver'), isFalse);
      expect(
        find.text(l10nOf(tester).jobHandoverPhotoRequired),
        findsOneWidget,
      );
      await tap(tester, 'evidence.handover_photo.capture');
      await reveal(tester, 'job.action.handOver');
      expect(enabled(tester, 'job.action.handOver'), isTrue);
    });

    testWidgets(
      'server 422 evidence_photo_required explains the kind and opens the camera',
      (tester) async {
        final repo = withJob('accepted');
        final camera = FakeEvidenceCamera();
        final h = await pumpBookingApp(
          tester,
          clock: () => testNow,
          riderRepo: repo,
          camera: camera,
          evidence: FakeEvidenceRepository()
            ..events = [evidenceEventFixture(type: 'pickup_photo')],
          goTo: AppRoutes.riderHome,
        );
        repo.jobError = const ApiException(
          statusCode: 422,
          code: 'evidence_photo_required',
          message: 'take the pickup photo first',
          body: {
            'error': 'take the pickup photo first',
            'code': 'evidence_photo_required',
            'kind': 'pickup_photo',
          },
        );
        await tap(tester, 'job.action.pickedUp');
        await pumpFor(tester);
        await reveal(tester, 'job.error');
        expect(
          find.text(l10nOf(tester).errCodeEvidencePickupPhotoRequired),
          findsOneWidget,
        );
        expect(camera.shots, 1, reason: 'the pickup photo capture opens');
        expect(h.evidence.uploads.single.kind, MediaKind.pickupPhoto);
      },
    );

    testWidgets('a failed upload keeps the action locked with retry', (
      tester,
    ) async {
      final evidence = FakeEvidenceRepository()
        ..uploadErrors.add(apiError(500, 'internal_error'));
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: withJob('accepted'),
        evidence: evidence,
        goTo: AppRoutes.riderHome,
      );
      await tap(tester, 'evidence.pickup_photo.capture');
      expect(byKey('evidence.pickup_photo.retry'), findsOneWidget);
      expect(byKey('evidence.pickup_photo.retake'), findsOneWidget);
      await reveal(tester, 'job.action.pickedUp');
      expect(enabled(tester, 'job.action.pickedUp'), isFalse);
      await tap(tester, 'evidence.pickup_photo.retry');
      await reveal(tester, 'job.action.pickedUp');
      expect(enabled(tester, 'job.action.pickedUp'), isTrue);
    });

    for (final status in [
      'accepted',
      'started',
      'payment_requested',
      'paid',
      'handed_over',
    ]) {
      testWidgets('rides show no photo step ($status)', (tester) async {
        await pumpBookingApp(
          tester,
          clock: () => testNow,
          riderRepo: withJob(status, service: ServiceType.ride),
          goTo: AppRoutes.riderHome,
        );
        await tester.pumpAndSettle();
        expect(byKey('evidence.pickup_photo'), findsNothing);
        expect(byKey('evidence.handover_photo'), findsNothing);
        expect(byKey('job.photoRequired'), findsNothing);
        final action = nextAction(
          jobFixture(
            status: status,
            arrivedAt: testNow,
            service: ServiceType.ride,
          ),
        );
        final key = action == JobAction.confirmPayment
            ? 'job.paymentReceived'
            : 'job.action.${action.name}';
        await reveal(tester, key);
        expect(enabled(tester, key), isTrue);
      });
    }
  });

  group('camera only', () {
    testWidgets('evidence capture offers no gallery or file option', (
      tester,
    ) async {
      final h = await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: withJob('accepted'),
        goTo: AppRoutes.riderHome,
      );
      await reveal(tester, 'evidence.pickup_photo.capture');
      final l = l10nOf(tester);
      expect(find.text(l.docChooseGallery), findsNothing);
      await tap(tester, 'evidence.pickup_photo.capture');
      expect(h.camera.shots, 1);
      expect(h.picker.sources, isEmpty, reason: 'document picker not used');
    });

    testWidgets('the sender item photo is camera-only and optional', (
      tester,
    ) async {
      final h = await pumpBookingApp(
        tester,
        repo: FakeBookingRepository()..order = jobFixture(),
        clock: () => testNow,
        goTo: AppRoutes.trackingFor('order-9'),
      );
      await reveal(tester, 'evidence.item_photo.capture');
      expect(find.text(l10nOf(tester).optionalLabel), findsOneWidget);
      await tap(tester, 'evidence.item_photo.capture');
      expect(h.camera.shots, 1);
      expect(h.picker.sources, isEmpty);
    });

    test('evidence sources never reach the gallery', () {
      for (final path in [
        'lib/core/files/evidence_camera.dart',
        'lib/features/evidence/photo_evidence_card.dart',
      ]) {
        final src = File(path).readAsStringSync();
        expect(src.contains('ImageSource.gallery'), isFalse, reason: path);
        expect(src.contains('DocumentSource'), isFalse, reason: path);
        expect(src.contains('FilePicker'), isFalse, reason: path);
      }
    });
  });

  group('rider re-reads /riders/me/active', () {
    testWidgets('on foreground', (tester) async {
      final repo = withJob('accepted');
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: repo,
        goTo: AppRoutes.riderHome,
      );
      final before = repo.activeCalls;
      for (final s in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(s);
      }
      await pumpFor(tester);
      expect(repo.activeCalls, before + 1);
    });

    testWidgets('on realtime reconnect', (tester) async {
      final repo = withJob('accepted');
      final h = await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: repo,
        goTo: AppRoutes.riderHome,
      );
      final before = repo.activeCalls;
      final offer = repo.activeResult;
      repo.activeResult = RiderActive(
        order: offer.order!.copyWith(status: 'started'),
      );
      h.emit('connected', {});
      await pumpFor(tester);
      expect(repo.activeCalls, before + 1);
      expect(
        tester.widget<Text>(byKey('job.title')).data,
        l10nOf(tester).jobPickedUp,
      );
    });
  });
}
