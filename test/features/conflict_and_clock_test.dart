import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridelink/core/api/api_exception.dart';
import 'package:ridelink/core/routing/app_router.dart';
import 'package:ridelink/core/time/server_clock.dart';
import 'package:ridelink/features/booking/booking_routes.dart';
import 'package:ridelink/features/booking/data/booking_models.dart';
import 'package:ridelink/features/orders/data/order_models.dart';
import 'package:ridelink/features/rider/data/rider_models.dart';
import 'package:ridelink/features/tracking/tracking_screen.dart';

import '../support/booking_fakes.dart';

/// A lost race as the server now answers it: 409 with the order's current status.
ApiException conflict(String status, {String code = 'conflict'}) =>
    ApiException(
      statusCode: 409,
      code: code,
      message: 'this order has changed; refresh and try again',
      body: {
        'error': 'this order has changed; refresh and try again',
        'code': code,
        'status': status,
      },
    );

/// Server clock [ahead] of the device clock, which reads [testNow].
ServerClock skewed(Duration ahead) =>
    ServerClock(deviceNow: () => testNow)
      ..observeSample(testNow.add(ahead), testNow);

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

  String seconds(WidgetTester tester) =>
      tester.widget<Text>(byKey('countdown.seconds')).data!;

  group('rider: 409 re-reads GET /riders/me/active', () {
    FakeRiderRepository withJob(String status) {
      final job = jobFixture(status: status);
      return FakeRiderRepository(
        profile: riderProfileFixture(online: true),
        activeResult: RiderActive(order: job),
      )..job = job;
    }

    FakeRiderRepository withOffer() => FakeRiderRepository(
      profile: riderProfileFixture(online: true),
      activeResult: RiderActive(offer: riderOfferFixture()),
    );

    testWidgets('job action: message, refetch, re-render; no retry', (
      tester,
    ) async {
      final repo = withJob('accepted');
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: repo,
        goTo: AppRoutes.riderHome,
      );
      final calls = repo.activeCalls;
      // The server moved on (arrival recorded automatically, trip started).
      repo
        ..jobError = conflict('in_transit')
        ..activeResult = RiderActive(
          order: jobFixture(status: 'in_transit', arrivedAt: testNow),
        );
      await tap(tester, 'job.action.arrivedAtPickup');

      expect(repo.jobCalls, ['arrived']);
      expect(repo.activeCalls, calls + 1);
      expect(byKey('riderHome.conflict'), findsOneWidget);
      expect(find.text(l10nOf(tester).errCodeConflict), findsOneWidget);
      expect(byKey('job.error'), findsNothing);
      expect(byKey('job.action.arrivedAtDropoff'), findsOneWidget);
    });

    testWidgets('payment step lost to a sender cancel: the final job '
        'state from GET /orders/{id} is shown, then Done returns home', (
      tester,
    ) async {
      final repo = withJob('arrived');
      final h = await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: repo,
        goTo: AppRoutes.riderHome,
      );
      final reads = h.orders.detailsCalls;
      repo
        ..jobError = conflict('cancelled')
        ..activeResult = const RiderActive();
      h.orders.fixedDetails['order-9'] = OrderDetails(
        order: jobFixture(status: 'cancelled', cancelReason: 'sender'),
      );
      await tap(tester, 'job.action.requestPayment');

      final l = l10nOf(tester);
      expect(repo.jobCalls, ['payment/request']);
      expect(h.orders.detailsCalls, greaterThan(reads));
      expect(byKey('riderHome.conflict'), findsOneWidget);
      expect(byKey('job.status.cancelled'), findsOneWidget);
      expect(find.text(l.jobCancelledBySender), findsOneWidget);
      expect(byKey('job.error'), findsNothing);

      await tap(tester, 'job.done');
      expect(byKey('screen.riderJob'), findsNothing);
      expect(byKey('riderHome.status'), findsOneWidget);
    });

    testWidgets('job 409 with no final state available falls back to the '
        'idle home', (tester) async {
      final repo = withJob('arrived');
      final h = await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: repo,
        goTo: AppRoutes.riderHome,
      );
      repo
        ..jobError = conflict('cancelled')
        ..activeResult = const RiderActive();
      h.orders.detailsError = apiError(500, 'internal_error');
      await tap(tester, 'job.action.requestPayment');

      expect(repo.jobCalls, ['payment/request']);
      expect(byKey('screen.riderJob'), findsNothing);
      expect(byKey('riderHome.status'), findsOneWidget);
      expect(byKey('riderHome.conflict'), findsOneWidget);
    });

    testWidgets('screen 6 accept: order_unavailable is shown, then the idle '
        'home from the server; no retry, no "expired" message', (tester) async {
      final repo = withOffer();
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: repo,
        goTo: AppRoutes.riderHome,
      );
      final calls = repo.activeCalls;
      repo
        ..acceptError = conflict('accepted', code: 'order_unavailable')
        ..activeResult = const RiderActive();
      await tap(tester, 'offer.accept');

      final l = l10nOf(tester);
      expect(repo.acceptCalls, ['order-9']);
      expect(repo.activeCalls, calls + 1);
      expect(byKey('screen.riderOffer'), findsNothing);
      expect(byKey('riderHome.status'), findsOneWidget);
      expect(find.text(l.errCodeOrderUnavailable), findsOneWidget);
      expect(find.text(l.riderOfferExpired), findsNothing);
    });

    testWidgets('screen 6 accept: an unknown 409 code shows the generic '
        'message and follows the server (here: the job is ours)', (
      tester,
    ) async {
      final repo = withOffer();
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: repo,
        goTo: AppRoutes.riderHome,
      );
      repo
        ..acceptError = conflict('accepted', code: 'offer_expired')
        ..activeResult = RiderActive(order: jobFixture());
      await tap(tester, 'offer.accept');

      expect(repo.acceptCalls, hasLength(1));
      expect(find.text(l10nOf(tester).errCodeConflict), findsOneWidget);
      expect(byKey('screen.riderJob'), findsOneWidget);
    });

    testWidgets('late accept (409 order_unavailable, status expired) is '
        'shown once and the server state is re-read', (tester) async {
      final repo = withOffer();
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: repo,
        goTo: AppRoutes.riderHome,
      );
      final calls = repo.activeCalls;
      repo
        ..acceptError = conflict('expired', code: 'order_unavailable')
        ..activeResult = const RiderActive();
      await tap(tester, 'offer.accept');

      expect(repo.acceptCalls, hasLength(1));
      expect(repo.activeCalls, calls + 1);
      expect(byKey('riderHome.conflict'), findsOneWidget);
      expect(find.text(l10nOf(tester).errCodeOrderUnavailable), findsOneWidget);
      expect(byKey('riderHome.status'), findsOneWidget);
    });

    testWidgets('sender cancel: offer.resolved "expired" alone (no '
        'order.updated) dismisses screen 6 and re-reads', (tester) async {
      final repo = withOffer();
      final h = await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: repo,
        goTo: AppRoutes.riderHome,
      );
      final calls = repo.activeCalls;
      repo.activeResult = const RiderActive();
      h.emit('offer.resolved', {
        'offer_id': 'offer-9',
        'order_id': 'order-9',
        'outcome': 'expired',
      });
      await pumpFor(tester);

      expect(byKey('screen.riderOffer'), findsNothing);
      expect(repo.activeCalls, calls + 1);
      expect(find.text(l10nOf(tester).riderOfferExpired), findsOneWidget);
    });

    testWidgets('offer.resolved "accepted" (e.g. another device) re-reads '
        'and opens the job without an end message', (tester) async {
      final repo = withOffer();
      final h = await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: repo,
        goTo: AppRoutes.riderHome,
      );
      repo.activeResult = RiderActive(order: jobFixture());
      h.emit('offer.resolved', {
        'offer_id': 'offer-9',
        'order_id': 'order-9',
        'outcome': 'accepted',
      });
      await pumpFor(tester);

      expect(byKey('screen.riderJob'), findsOneWidget);
      expect(byKey('riderHome.offerEnded'), findsNothing);
    });

    for (final (outcome, message) in [
      ('cancelled', 'riderOfferCancelled'),
      ('withdrawn_unknown_to_this_build', 'riderOfferExpired'),
    ]) {
      testWidgets('offer.resolved "$outcome" dismisses screen 6 and re-reads', (
        tester,
      ) async {
        final repo = withOffer();
        final h = await pumpBookingApp(
          tester,
          clock: () => testNow,
          riderRepo: repo,
          goTo: AppRoutes.riderHome,
        );
        final calls = repo.activeCalls;
        repo.activeResult = const RiderActive();
        h.emit('offer.resolved', {
          'offer_id': 'offer-9',
          'order_id': 'order-9',
          'outcome': outcome,
        });
        await pumpFor(tester);

        final l = l10nOf(tester);
        expect(byKey('screen.riderOffer'), findsNothing);
        expect(repo.activeCalls, calls + 1);
        expect(
          find.text(
            message == 'riderOfferCancelled'
                ? l.riderOfferCancelled
                : l.riderOfferExpired,
          ),
          findsOneWidget,
        );
      });
    }

    testWidgets('screen 6 decline: 409 re-reads instead of guessing', (
      tester,
    ) async {
      final repo = withOffer();
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: repo,
        goTo: AppRoutes.riderHome,
      );
      repo
        ..declineError = conflict('expired')
        ..activeResult = const RiderActive();
      await tap(tester, 'offer.decline');

      expect(repo.declineCalls, hasLength(1));
      expect(byKey('riderHome.conflict'), findsOneWidget);
      expect(find.text(l10nOf(tester).riderOfferDeclined), findsNothing);
      expect(byKey('screen.riderOffer'), findsNothing);
    });
  });

  group('sender: 409 re-reads the order', () {
    testWidgets('waiting screen cancel lost to an accept opens tracking', (
      tester,
    ) async {
      final repo = FakeBookingRepository()
        ..cancelError = conflict('accepted')
        ..order = orderFixture(status: 'accepted');
      final h = await pumpBookingApp(
        tester,
        repo: repo,
        goTo: AppRoutes.waitingFor('order-1'),
        extra: PendingOffer(
          order: orderFixture(status: 'offered'),
          rider: riderFixture(),
          offer: offerFixture(),
        ),
        settle: false,
      );
      await pumpFor(tester);
      final reads = repo.getOrderCalls;
      await tap(tester, 'waiting.cancel');
      await tap(tester, 'waiting.cancelDialog.yes');
      await pumpFor(tester);

      expect(repo.cancelCalls, 1);
      expect(repo.getOrderCalls, reads + 1);
      expect(byKey('screen.tracking'), findsOneWidget);
      expect(find.text(l10nOf(tester).errCodeConflict), findsOneWidget);
      h.router.go(AppRoutes.home);
      await tester.pumpAndSettle();
    });

    testWidgets('waiting screen: an unknown offer.resolved outcome re-reads '
        'the order and follows it', (tester) async {
      final repo = FakeBookingRepository()
        ..senderOrderResult = SenderOrder(
          order: orderFixture(status: 'created'),
        );
      final h = await pumpBookingApp(
        tester,
        repo: repo,
        goTo: AppRoutes.waitingFor('order-1'),
        extra: PendingOffer(
          order: orderFixture(status: 'offered'),
          rider: riderFixture(),
          offer: offerFixture(),
        ),
        settle: false,
      );
      await pumpFor(tester);
      final reads = repo.getOrderCalls;
      h.emit('offer.resolved', {
        'offer_id': 'offer-1',
        'order_id': 'order-1',
        'outcome': 'withdrawn_unknown_to_this_build',
      });
      await pumpFor(tester);

      expect(repo.getOrderCalls, reads + 1);
      expect(byKey('screen.riderList'), findsOneWidget);
      h.router.go(AppRoutes.home);
      await tester.pumpAndSettle();
    });

    testWidgets('tracking cancel: message, reload, re-render; no retry', (
      tester,
    ) async {
      final repo = FakeBookingRepository()
        ..order = jobFixture()
        ..cancelError = conflict('started');
      final h = await pumpBookingApp(
        tester,
        repo: repo,
        clock: () => testNow,
        goTo: AppRoutes.trackingFor('order-9'),
        extra: const TrackingArgs(riderName: 'Moses O.'),
      );
      final loads = h.orders.detailsCalls;
      repo.order = jobFixture(status: 'started', arrivedAt: testNow);
      await tapKeyAndSettle(tester, 'tracking.cancel');
      await tapKeyAndSettle(tester, 'tracking.cancelDialog.yes');

      expect(repo.cancelCalls, 1);
      expect(h.orders.detailsCalls, loads + 1);
      expect(byKey('tracking.conflict'), findsOneWidget);
      expect(byKey('tracking.actionError'), findsNothing);
      expect(byKey('tracking.inTransit'), findsOneWidget);
    });

    testWidgets('payment step: "I\'ve paid" lost race re-renders the state', (
      tester,
    ) async {
      final repo = FakeBookingRepository()
        ..order = jobFixture(status: 'payment_requested')
        ..paymentSentError = conflict('cancelled');
      final h = await pumpBookingApp(
        tester,
        repo: repo,
        clock: () => testNow,
        goTo: AppRoutes.trackingFor('order-9'),
      );
      final loads = h.orders.detailsCalls;
      repo.order = jobFixture(status: 'cancelled', cancelReason: 'rider');
      await tapKeyAndSettle(tester, 'tracking.ivePaid');
      await tapKeyAndSettle(tester, 'tracking.paidDialog.yes');

      expect(repo.paymentSentCalls, 1);
      expect(h.orders.detailsCalls, loads + 1);
      expect(byKey('tracking.conflict'), findsOneWidget);
      expect(byKey('tracking.cancelled'), findsOneWidget);
      expect(byKey('tracking.ivePaid'), findsNothing);
    });

    testWidgets('send offer 409 follows the server (order cancelled -> home)', (
      tester,
    ) async {
      final repo = FakeBookingRepository()
        ..offerError = conflict('cancelled')
        ..senderOrderResult = SenderOrder(
          order: orderFixture(status: 'cancelled'),
        );
      await pumpBookingApp(
        tester,
        repo: repo,
        goTo: AppRoutes.quoteFor('order-1'),
        extra: RiderChoice(order: orderFixture(), rider: riderFixture()),
      );
      await tapKeyAndSettle(tester, 'quote.send');

      expect(repo.offerCalls, hasLength(1));
      expect(byKey('screen.home'), findsOneWidget);
      expect(byKey('quote.conflict'), findsOneWidget);
    });

    testWidgets('rider list discard 409 follows the server', (tester) async {
      final repo = FakeBookingRepository()
        ..cancelError = conflict('accepted')
        ..order = orderFixture(status: 'accepted')
        ..senderOrderResult = SenderOrder(order: jobFixture(id: 'order-1'));
      await pumpBookingApp(
        tester,
        repo: repo,
        goTo: AppRoutes.ridersFor('order-1'),
      );
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tapKeyAndSettle(tester, 'riders.discardDialog.yes');

      expect(repo.cancelCalls, 1);
      expect(byKey('riders.conflict'), findsOneWidget);
      expect(byKey('screen.tracking'), findsOneWidget);
    });
  });

  group('countdowns use the server clock', () {
    testWidgets('screen 6 ring counts to expires_at in server time', (
      tester,
    ) async {
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        serverClock: skewed(const Duration(seconds: 20)),
        riderRepo: FakeRiderRepository(
          profile: riderProfileFixture(online: true),
          activeResult: RiderActive(offer: riderOfferFixture()),
        ),
        goTo: AppRoutes.riderHome,
      );
      expect(seconds(tester), '40');
    });

    testWidgets('sender waiting screen resumes to expires_at in server time', (
      tester,
    ) async {
      final h = await pumpBookingApp(
        tester,
        clock: () => testNow,
        serverClock: skewed(const Duration(seconds: 15)),
        goTo: AppRoutes.waitingFor('order-1'),
        extra: PendingOffer(
          order: orderFixture(status: 'offered'),
          rider: riderFixture(),
          offer: offerFixture(),
          fromServer: true,
        ),
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(seconds(tester), '45');
      h.router.go(AppRoutes.home);
      await tester.pumpAndSettle();
    });

    testWidgets('rider pickup deadline and running late use server time', (
      tester,
    ) async {
      final job = jobFixture();
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        serverClock: skewed(const Duration(minutes: 3)),
        riderRepo: FakeRiderRepository(
          profile: riderProfileFixture(online: true),
          activeResult: RiderActive(order: job),
        )..job = job,
        goTo: AppRoutes.riderHome,
      );
      expect(tester.widget<Text>(byKey('job.pickupCountdown')).data, '7:00');
    });

    testWidgets('a server clock past the deadline shows running late', (
      tester,
    ) async {
      final job = jobFixture();
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        serverClock: skewed(const Duration(minutes: 11)),
        riderRepo: FakeRiderRepository(
          profile: riderProfileFixture(online: true),
          activeResult: RiderActive(order: job),
        )..job = job,
        goTo: AppRoutes.riderHome,
      );
      expect(byKey('job.late'), findsOneWidget);
    });

    testWidgets('sender tracking countdown uses server time', (tester) async {
      await pumpBookingApp(
        tester,
        repo: FakeBookingRepository()..order = jobFixture(),
        clock: () => testNow,
        serverClock: skewed(const Duration(minutes: 3)),
        goTo: AppRoutes.trackingFor('order-9'),
      );
      expect(find.text(l10nOf(tester).riderArrivesIn(7)), findsOneWidget);
    });
  });
}
