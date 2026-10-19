import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridelink/core/api/api_exception.dart';
import 'package:ridelink/core/location/geo_point.dart';
import 'package:ridelink/core/location/location_service.dart';
import 'package:ridelink/core/routing/app_router.dart';
import 'package:ridelink/features/rider/data/rider_models.dart';

import '../../support/booking_fakes.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Finder byKey(String k) => find.byKey(Key(k));

  /// Fixed pumps instead of pumpAndSettle (the payment wait shows an endless spinner).
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

  group('online toggle', () {
    testWidgets('going online sends a location, starts the foreground tracker '
        'and asks for notification permission', (tester) async {
      var now = testNow;
      final h = await pumpBookingApp(
        tester,
        clock: () => now,
        goTo: AppRoutes.riderHome,
      );
      final l = l10nOf(tester);
      expect(byKey('screen.riderHome'), findsOneWidget);
      expect(find.text(l.riderOffline), findsOneWidget);

      await tap(tester, 'riderHome.onlineSwitch');
      expect(h.riderRepo.onlineCalls, [true]);
      expect(h.riderRepo.locationCalls, hasLength(1));
      expect(h.tracker.starts, 1);
      expect(h.tracker.notificationRequests, 1);
      expect(h.tracker.lastNotice!.title, l.onlineNotificationTitle);
      expect(find.text(l.riderOnline), findsOneWidget);

      // Positions closer together than the send gap are dropped.
      h.tracker.emit(const GeoPoint(-1.27, 36.81));
      await tester.pump();
      expect(h.riderRepo.locationCalls, hasLength(1));
      now = now.add(const Duration(seconds: 10));
      h.tracker.emit(const GeoPoint(-1.28, 36.82));
      await tester.pump();
      expect(h.riderRepo.locationCalls, hasLength(2));

      await tap(tester, 'riderHome.onlineSwitch');
      expect(h.riderRepo.onlineCalls, [true, false]);
      expect(h.tracker.running, isFalse);
      expect(find.text(l.riderOffline), findsOneWidget);
    });

    testWidgets('unverified rider sees why and a link to the status', (
      tester,
    ) async {
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: FakeRiderRepository(
          profile: riderProfileFixture(status: VerificationStatus.pending),
        ),
        goTo: AppRoutes.riderHome,
      );
      expect(byKey('riderHome.block.notVerified'), findsOneWidget);
      await tap(tester, 'riderHome.block.action');
      expect(byKey('screen.riderVerification'), findsOneWidget);
    });

    testWidgets('expired documents from the server are listed by name', (
      tester,
    ) async {
      final repo = FakeRiderRepository()
        ..onlineError = const ApiException(
          statusCode: 403,
          code: 'documents_missing',
          message:
              'documents missing or expired: psv_insurance, driving_licence',
          body: {
            'documents': ['psv_insurance', 'driving_licence'],
          },
        );
      final h = await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: repo,
        goTo: AppRoutes.riderHome,
      );
      await tap(tester, 'riderHome.onlineSwitch');
      final l = l10nOf(tester);
      expect(byKey('riderHome.block.documents'), findsOneWidget);
      expect(
        find.text(
          l.blockDocumentsBody('${l.docPsvInsurance}, ${l.docDrivingLicence}'),
        ),
        findsOneWidget,
      );
      expect(h.tracker.running, isFalse);
    });

    testWidgets('paused rider sees until when and why', (tester) async {
      final until = testNow.add(const Duration(hours: 20));
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: FakeRiderRepository(
          profile: riderProfileFixture(
            pausedUntil: until,
            pauseReason: 'missed_pickups',
            pauseFailures: 3,
          ),
        ),
        goTo: AppRoutes.riderHome,
      );
      expect(byKey('riderHome.block.paused'), findsOneWidget);
      expect(
        find.text(l10nOf(tester).blockPausedMissedPickups(3)),
        findsOneWidget,
      );
    });

    testWidgets('paused 403 on the toggle is shown with its end time', (
      tester,
    ) async {
      final repo = FakeRiderRepository()
        ..onlineError = const ApiException(
          statusCode: 403,
          code: 'rider_paused',
          message: 'you are paused after 3 missed pickups',
          body: {'paused_until': '2026-10-14T06:00:00Z'},
        );
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: repo,
        goTo: AppRoutes.riderHome,
      );
      await tap(tester, 'riderHome.onlineSwitch');
      expect(byKey('riderHome.block.paused'), findsOneWidget);
    });

    testWidgets(
      'location denied blocks going online without calling the server',
      (tester) async {
        final h = await pumpBookingApp(
          tester,
          location: FakeLocationService(initial: const LocationDenied()),
          goTo: AppRoutes.riderHome,
        );
        await tap(tester, 'riderHome.onlineSwitch');
        expect(byKey('riderHome.block.location'), findsOneWidget);
        expect(h.riderRepo.onlineCalls, isEmpty);
      },
    );
  });

  group('offer received (screen 6)', () {
    FakeRiderRepository withOffer() => FakeRiderRepository(
      profile: riderProfileFixture(online: true),
      activeResult: RiderActive(offer: riderOfferFixture()),
    );

    testWidgets(
      'resumes a pending offer with earnings, pickup terms and countdown',
      (tester) async {
        final h = await pumpBookingApp(
          tester,
          clock: () => testNow,
          riderRepo: withOffer(),
          goTo: AppRoutes.riderHome,
        );
        final l = l10nOf(tester);
        expect(byKey('screen.riderOffer'), findsOneWidget);
        expect(tester.widget<Text>(byKey('offer.earnings')).data, 'KES 214');
        expect(find.text(l.reachPickupWithin(10)), findsOneWidget);
        expect(find.text(l.pickupDistanceAway('0.8 km')), findsOneWidget);
        expect(find.text(l.tripDistance('4.8 km')), findsOneWidget);
        expect(tester.widget<Text>(byKey('countdown.seconds')).data, '60');
        await tester.pump(const Duration(seconds: 5));
        expect(tester.widget<Text>(byKey('countdown.seconds')).data, '55');
        // Online with an offer keeps location flowing.
        expect(h.tracker.running, isTrue);
      },
    );

    testWidgets('accept opens the job', (tester) async {
      final h = await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: withOffer(),
        goTo: AppRoutes.riderHome,
      );
      await tap(tester, 'offer.accept');
      expect(h.riderRepo.acceptCalls, ['order-9']);
      expect(byKey('screen.riderJob'), findsOneWidget);
    });

    testWidgets('accept 422 asks to turn on location', (tester) async {
      final repo = withOffer()
        ..acceptError = const ApiException(
          statusCode: 422,
          message: 'turn on location to accept',
        );
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: repo,
        goTo: AppRoutes.riderHome,
      );
      await tap(tester, 'offer.accept');
      expect(find.text(l10nOf(tester).acceptNeedsLocation), findsOneWidget);
      expect(byKey('screen.riderOffer'), findsOneWidget);
    });

    testWidgets('accept 403 paused returns home with the pause shown', (
      tester,
    ) async {
      final repo = withOffer()
        ..acceptError = const ApiException(
          statusCode: 403,
          code: 'rider_paused',
          message: 'paused',
          body: {'paused_until': '2026-10-14T06:00:00Z'},
        );
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: repo,
        goTo: AppRoutes.riderHome,
      );
      await tap(tester, 'offer.accept');
      expect(byKey('riderHome.block.paused'), findsOneWidget);
    });

    testWidgets('decline returns to the idle home with a message', (
      tester,
    ) async {
      final h = await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: withOffer(),
        goTo: AppRoutes.riderHome,
      );
      await tap(tester, 'offer.decline');
      expect(h.riderRepo.declineCalls, ['order-9']);
      expect(byKey('riderHome.status'), findsOneWidget);
      expect(find.text(l10nOf(tester).riderOfferDeclined), findsOneWidget);
    });

    testWidgets(
      'offer.received loads the offer; offer.resolved expired clears it',
      (tester) async {
        final repo = FakeRiderRepository(
          profile: riderProfileFixture(online: true),
        );
        final h = await pumpBookingApp(
          tester,
          clock: () => testNow,
          riderRepo: repo,
          goTo: AppRoutes.riderHome,
        );
        expect(byKey('screen.riderOffer'), findsNothing);

        repo.activeResult = RiderActive(offer: riderOfferFixture());
        h.emit('offer.received', {
          'offer_id': 'offer-9',
          'order_id': 'order-9',
        });
        await pumpFor(tester);
        expect(byKey('screen.riderOffer'), findsOneWidget);

        repo.activeResult = const RiderActive();
        h.emit('offer.resolved', {
          'offer_id': 'offer-9',
          'order_id': 'order-9',
          'outcome': 'expired',
        });
        await pumpFor(tester);
        expect(byKey('screen.riderOffer'), findsNothing);
        expect(find.text(l10nOf(tester).riderOfferExpired), findsOneWidget);
      },
    );

    testWidgets(
      'an offer arriving on the settings screen brings the rider home',
      (tester) async {
        final repo = FakeRiderRepository(
          profile: riderProfileFixture(online: true),
        );
        final h = await pumpBookingApp(
          tester,
          clock: () => testNow,
          riderRepo: repo,
          goTo: AppRoutes.riderHome,
        );
        await tap(tester, 'riderHome.settings');
        expect(byKey('screen.riderSettings'), findsOneWidget);
        repo.activeResult = RiderActive(offer: riderOfferFixture());
        h.emit('offer.received', {
          'offer_id': 'offer-9',
          'order_id': 'order-9',
        });
        await pumpFor(tester);
        expect(byKey('screen.riderOffer'), findsOneWidget);
      },
    );
  });

  group('active job', () {
    FakeRiderRepository withJob([String status = 'accepted']) {
      final job = jobFixture(status: status);
      return FakeRiderRepository(
        profile: riderProfileFixture(online: true),
        activeResult: RiderActive(order: job),
      )..job = job;
    }

    testWidgets(
      'full job: pickup countdown -> arrival -> trip -> cash -> complete',
      (tester) async {
        var now = testNow;
        final repo = withJob();
        final h = await pumpBookingApp(
          tester,
          clock: () => now,
          riderRepo: repo,
          goTo: AppRoutes.riderHome,
        );
        expect(byKey('screen.riderJob'), findsOneWidget);
        expect(tester.widget<Text>(byKey('job.pickupCountdown')).data, '10:00');
        now = now.add(const Duration(seconds: 65));
        await tester.pump(const Duration(seconds: 1));
        expect(tester.widget<Text>(byKey('job.pickupCountdown')).data, '8:55');

        await tap(tester, 'job.action.arrivedAtPickup');
        expect(byKey('job.pickupCountdown'), findsNothing);
        // Deliveries need the pickup photo before "Picked up".
        await tap(tester, 'evidence.pickup_photo.capture');
        await tap(tester, 'job.action.pickedUp');
        await tap(tester, 'job.action.startTrip');
        await tap(tester, 'job.action.arrivedAtDropoff');
        await tap(tester, 'job.action.requestPayment');
        expect(byKey('job.status.payment_requested'), findsOneWidget);

        // The sender taps "I've paid".
        h.emit('order.updated', {
          'order_id': 'order-9',
          'status': 'cash_pending',
        });
        await pumpFor(tester);
        expect(byKey('job.status.cash_pending'), findsOneWidget);
        await tap(tester, 'job.paymentReceived');
        expect(byKey('job.receivedDialog'), findsOneWidget);
        await tap(tester, 'job.receivedDialog.yes');
        await tap(tester, 'evidence.handover_photo.capture');
        await tap(tester, 'job.action.handOver');
        await tap(tester, 'job.action.complete');
        expect(byKey('job.status.completed'), findsOneWidget);
        // Completion asks the rider to rate the sender once; skippable.
        expect(byKey('rating.sheet'), findsOneWidget);
        await tap(tester, 'rating.skip');
        expect(byKey('rating.sheet'), findsNothing);

        expect(repo.jobCalls, [
          'arrived',
          'status:started',
          'status:in_transit',
          'status:arrived',
          'payment/request',
          'payment/received',
          'status:handed_over',
          'status:completed',
        ]);
        // Still online, so tracking continues after the job.
        await tap(tester, 'job.done');
        expect(byKey('riderHome.status'), findsOneWidget);
        expect(h.tracker.running, isTrue);
      },
    );

    testWidgets('arrival fallback 422 shows the localized reason', (
      tester,
    ) async {
      final repo = withJob()
        ..jobError = const ApiException(
          statusCode: 422,
          code: 'too_far_from_pickup',
          message: 'you are 420 m from the pickup point; arrival counts within 150 m',
        );
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: repo,
        goTo: AppRoutes.riderHome,
      );
      await tap(tester, 'job.action.arrivedAtPickup');
      await tester.ensureVisible(byKey('job.error'));
      expect(find.text(l10nOf(tester).errCodeTooFarFromPickup), findsOneWidget);
    });

    testWidgets('automatic arrival via order.updated switches to Picked up', (
      tester,
    ) async {
      final h = await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: withJob(),
        goTo: AppRoutes.riderHome,
      );
      h.emit('order.updated', {
        'order_id': 'order-9',
        'status': 'accepted',
        'pickup_arrived_at': '2026-10-13T09:47:00Z',
      });
      await pumpFor(tester);
      await tester.scrollUntilVisible(
        byKey('job.action.pickedUp'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(byKey('job.action.pickedUp'), findsOneWidget);
    });

    testWidgets('cash not received goes to review after confirming', (
      tester,
    ) async {
      final repo = withJob('cash_pending');
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: repo,
        goTo: AppRoutes.riderHome,
      );
      await tap(tester, 'job.paymentNotReceived');
      await tap(tester, 'job.notReceivedDialog.no');
      expect(repo.jobCalls, isEmpty);
      await tap(tester, 'job.paymentNotReceived');
      await tap(tester, 'job.notReceivedDialog.yes');
      expect(repo.jobCalls, ['payment/not-received']);
      expect(byKey('job.status.unresolved'), findsOneWidget);
    });

    testWidgets('cancel explains the 2-minute grace', (tester) async {
      var now = testNow.add(const Duration(seconds: 30));
      final repo = withJob();
      await pumpBookingApp(
        tester,
        clock: () => now,
        riderRepo: repo,
        goTo: AppRoutes.riderHome,
      );
      final l = l10nOf(tester);
      await tap(tester, 'job.cancel');
      expect(find.text(l.riderCancelWithinGrace('1:30')), findsOneWidget);
      await tap(tester, 'job.cancelDialog.no');

      now = testNow.add(const Duration(minutes: 3));
      await tap(tester, 'job.cancel');
      expect(find.text(l.riderCancelAfterGrace), findsOneWidget);
      await tap(tester, 'job.cancelDialog.yes');
      expect(repo.jobCalls, ['status:cancelled']);
      expect(byKey('job.status.cancelled'), findsOneWidget);
    });

    testWidgets('sender cancelling ends the job with the reason', (
      tester,
    ) async {
      final h = await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: withJob(),
        goTo: AppRoutes.riderHome,
      );
      h.emit('order.updated', {
        'order_id': 'order-9',
        'status': 'cancelled',
        'cancel_reason': 'sender',
      });
      await pumpFor(tester);
      expect(find.text(l10nOf(tester).jobCancelledBySender), findsOneWidget);
    });
  });
}
