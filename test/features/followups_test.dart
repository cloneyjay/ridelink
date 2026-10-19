import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridelink/core/auth/nonce.dart';
import 'package:ridelink/core/routing/app_router.dart';
import 'package:ridelink/core/storage/local_store.dart';
import 'package:ridelink/features/auth/google_auth.dart';
import 'package:ridelink/features/booking/booking_routes.dart';
import 'package:ridelink/features/booking/data/booking_models.dart';
import 'package:ridelink/features/booking/data/pending_offer_store.dart';
import 'package:ridelink/features/orders/data/order_models.dart';
import 'package:ridelink/features/rider/data/rider_models.dart';
import 'package:ridelink/features/rider/rider_controller.dart';
import 'package:ridelink/features/shell/app_menu.dart';

import '../support/auth_harness.dart';
import '../support/booking_fakes.dart';
import '../support/fakes.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Finder byKey(String k) => find.byKey(Key(k));

  Future<void> pumpFor(WidgetTester tester, [int frames = 12]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  group('mode switch (phase 2 follow-ups)', () {
    test('mid-job blocks; online asks to go offline first', () {
      final profile = riderProfileFixture();
      expect(
        switchToSendingBlock(RiderState(loading: false, profile: profile)),
        SwitchToSendingBlock.none,
      );
      expect(
        switchToSendingBlock(
          RiderState(
            loading: false,
            profile: riderProfileFixture(online: true),
          ),
        ),
        SwitchToSendingBlock.online,
      );
      expect(
        switchToSendingBlock(
          RiderState(
            loading: false,
            profile: riderProfileFixture(online: true),
            job: jobFixture(status: 'in_transit'),
          ),
        ),
        SwitchToSendingBlock.activeJob,
      );
      expect(
        switchToSendingBlock(
          RiderState(
            loading: false,
            profile: profile,
            job: jobFixture(status: 'completed'),
          ),
        ),
        SwitchToSendingBlock.none,
      );
    });

    Future<BookingHarness> onlineRider(WidgetTester tester) async {
      final h = await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: FakeRiderRepository(
          profile: riderProfileFixture(online: true),
        ),
        goTo: AppRoutes.riderHome,
      );
      tester.state<ScaffoldState>(byKey('screen.riderHome')).openDrawer();
      await tester.pumpAndSettle();
      await tester.tap(byKey('menu.switchToSending'));
      await tester.pumpAndSettle();
      return h;
    }

    testWidgets('online: staying online keeps the rider side', (tester) async {
      final h = await onlineRider(tester);
      expect(byKey('menu.goOfflineDialog'), findsOneWidget);
      await tester.tap(byKey('menu.goOfflineDialog.no'));
      await tester.pumpAndSettle();
      expect(h.riderRepo.onlineCalls, isEmpty);
      expect(byKey('screen.riderHome'), findsOneWidget);
    });

    testWidgets('online: going offline then switches to sending', (
      tester,
    ) async {
      final h = await onlineRider(tester);
      await tester.tap(byKey('menu.goOfflineDialog.yes'));
      await tester.pumpAndSettle();
      expect(h.riderRepo.onlineCalls, [false]);
      expect(byKey('screen.home'), findsOneWidget);
      expect(h.tracker.running, isFalse);
    });

    testWidgets('online: if going offline fails, the switch stops', (
      tester,
    ) async {
      final repo = FakeRiderRepository(
        profile: riderProfileFixture(online: true),
      )..onlineError = apiError(500, 'internal_error');
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: repo,
        goTo: AppRoutes.riderHome,
      );
      tester.state<ScaffoldState>(byKey('screen.riderHome')).openDrawer();
      await tester.pumpAndSettle();
      await tester.tap(byKey('menu.switchToSending'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('menu.goOfflineDialog.yes'));
      await tester.pumpAndSettle();
      expect(byKey('menu.goOfflineFailed'), findsOneWidget);
      expect(byKey('screen.home'), findsNothing);
    });

    testWidgets('offline: switches straight away', (tester) async {
      await pumpBookingApp(
        tester,
        riderRepo: FakeRiderRepository(),
        goTo: AppRoutes.riderHome,
      );
      tester.state<ScaffoldState>(byKey('screen.riderHome')).openDrawer();
      await tester.pumpAndSettle();
      await tester.tap(byKey('menu.switchToSending'));
      await tester.pumpAndSettle();
      expect(byKey('menu.goOfflineDialog'), findsNothing);
      expect(byKey('screen.home'), findsOneWidget);
    });

    testWidgets(
      'starting in sender mode while online server-side resumes tracking',
      (tester) async {
        final h = await pumpBookingApp(
          tester,
          account: FakeAccountRepository(rider: true),
          riderRepo: FakeRiderRepository(
            profile: riderProfileFixture(online: true),
          ),
        );
        await pumpFor(tester);
        expect(byKey('screen.home'), findsOneWidget);
        expect(h.tracker.starts, 1);
        expect(h.tracker.running, isTrue);
      },
    );

    testWidgets('a plain sender never starts rider tracking', (tester) async {
      final h = await pumpBookingApp(tester);
      await pumpFor(tester);
      expect(h.riderRepo.meCalls, 0);
      expect(h.tracker.starts, 0);
    });
  });

  group('ride wording', () {
    Future<void> rideJob(WidgetTester tester, String status) {
      final job = jobFixture(status: status, service: ServiceType.ride);
      return pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: FakeRiderRepository(activeResult: RiderActive(order: job))
          ..job = job,
        goTo: AppRoutes.riderHome,
      );
    }

    String title(WidgetTester tester) =>
        tester.widget<Text>(byKey('job.title')).data!;

    testWidgets('picked up and dropped off speak of the passenger', (
      tester,
    ) async {
      await rideJob(tester, 'started');
      expect(title(tester), l10nOf(tester).jobPassengerPickedUp);
    });

    testWidgets('paid ride: "Passenger dropped off" action', (tester) async {
      await rideJob(tester, 'paid');
      final l = l10nOf(tester);
      await tester.scrollUntilVisible(
        byKey('job.action.handOver'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text(l.actionPassengerDroppedOff), findsOneWidget);
      expect(find.text(l.jobPaidBodyRide), findsOneWidget);
    });

    testWidgets('handed over ride: "Complete ride"', (tester) async {
      await rideJob(tester, 'handed_over');
      final l = l10nOf(tester);
      expect(title(tester), l.jobPassengerDroppedOff);
      await tester.scrollUntilVisible(
        byKey('job.action.complete'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text(l.actionCompleteRide), findsOneWidget);
    });

    testWidgets('deliveries keep delivery wording', (tester) async {
      final job = jobFixture(status: 'started');
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: FakeRiderRepository(activeResult: RiderActive(order: job))
          ..job = job,
        goTo: AppRoutes.riderHome,
      );
      expect(title(tester), l10nOf(tester).jobPickedUp);
    });
  });

  group('running late', () {
    testWidgets('sender sees "running late" once the deadline passes', (
      tester,
    ) async {
      var now = testNow.add(const Duration(minutes: 9));
      await pumpBookingApp(
        tester,
        repo: FakeBookingRepository()..order = jobFixture(),
        clock: () => now,
        goTo: AppRoutes.trackingFor('order-9'),
      );
      expect(byKey('tracking.countdown'), findsOneWidget);
      now = testNow.add(const Duration(minutes: 11));
      await tester.pump(const Duration(seconds: 1));
      expect(byKey('tracking.late'), findsOneWidget);
      expect(find.text(l10nOf(tester).riderRunningLate), findsOneWidget);
    });

    testWidgets('rider sees "running late" instead of 0:00', (tester) async {
      final job = jobFixture();
      await pumpBookingApp(
        tester,
        clock: () => testNow.add(const Duration(minutes: 12)),
        riderRepo: FakeRiderRepository(activeResult: RiderActive(order: job))
          ..job = job,
        goTo: AppRoutes.riderHome,
      );
      expect(byKey('job.late'), findsOneWidget);
      expect(byKey('job.pickupCountdown'), findsNothing);
    });
  });

  group('resume after restart', () {
    test('pending offer store round-trips per order', () async {
      final store = PendingOfferStore(MemoryLocalStore());
      await store.save(offerFixture(orderId: 'order-1'), riderFixture());
      final read = store.read('order-1')!;
      expect(read.offer.id, 'offer-1');
      expect(read.offer.expiresAt, offerFixture().expiresAt);
      expect(read.offer.quotedTotal, 214);
      expect(read.rider.displayName, 'Moses O.');
      expect(read.rider.breakdown.platformAmount, 77);
      expect(store.read('other-order'), isNull);
      await store.clear();
      expect(store.read('order-1'), isNull);
    });

    testWidgets('sending a request remembers it on the device', (tester) async {
      final h = await pumpBookingApp(
        tester,
        goTo: AppRoutes.quoteFor('order-1'),
        extra: RiderChoice(order: orderFixture(), rider: riderFixture()),
      );
      await tapKeyAndSettle(tester, 'quote.send');
      expect(PendingOfferStore(h.store).read('order-1'), isNotNull);
    });

    testWidgets('an offered order reopens the waiting screen', (tester) async {
      final store = MemoryLocalStore();
      await PendingOfferStore(store)
          .save(offerFixture(orderId: 'order-1'), riderFixture());
      await pumpBookingApp(
        tester,
        repo: FakeBookingRepository()
          ..myOrdersList = [orderFixture(status: 'offered')],
        store: store,
        settle: false,
      );
      await pumpFor(tester);
      expect(byKey('screen.offerWaiting'), findsOneWidget);
      expect(
        find.text(l10nOf(tester).waitingTitle('Moses O.')),
        findsOneWidget,
      );
    });

    testWidgets('without a stored offer the sender stays home', (tester) async {
      await pumpBookingApp(
        tester,
        repo: FakeBookingRepository()
          ..myOrdersList = [orderFixture(status: 'offered')],
      );
      expect(byKey('screen.home'), findsOneWidget);
    });

    testWidgets('tracking without route extras uses GET /orders/{id} details', (
      tester,
    ) async {
      final orders = FakeOrdersRepository()
        ..rider = const OrderRider(
          riderId: 'rider-1',
          displayName: 'Moses O.',
          plateNumber: 'KMFA 123B',
          hasPhoto: false,
          ratingAverage: 4.9,
          ratingCount: 10,
        )
        ..terms = OrderTerms(
          total: 214,
          currency: 'KES',
          pickupWindowMins: 15,
          breakdown: riderFixture().breakdown,
        );
      final h = await pumpBookingApp(
        tester,
        repo: FakeBookingRepository()..order = jobFixture(),
        orders: orders,
        clock: () => testNow,
        goTo: AppRoutes.trackingFor('order-9'),
      );
      final l = l10nOf(tester);
      expect(h.orders.detailsCalls, greaterThan(0));
      expect(tester.widget<Text>(byKey('tracking.riderName')).data, 'Moses O.');
      expect(tester.widget<Text>(byKey('tracking.plate')).data, 'KMFA 123B');
      await tapKeyAndSettle(tester, 'tracking.viewTerms');
      expect(find.text(l.minutesShort(15)), findsOneWidget);
      expect(find.text(l.breakdownBaseFare), findsOneWidget);
    });

    testWidgets('rider job shows the sender and agreed terms after restart', (
      tester,
    ) async {
      final job = jobFixture();
      final orders = FakeOrdersRepository()
        ..senderName = 'Grace W.'
        ..terms = const OrderTerms(
          total: 214,
          currency: 'KES',
          pickupWindowMins: 10,
        );
      await pumpBookingApp(
        tester,
        orders: orders,
        clock: () => testNow,
        riderRepo: FakeRiderRepository(activeResult: RiderActive(order: job))
          ..job = job,
        goTo: AppRoutes.riderHome,
      );
      final l = l10nOf(tester);
      await tester.scrollUntilVisible(
        byKey('job.senderName'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text(l.senderIs('Grace W.')), findsOneWidget);
      await tester.scrollUntilVisible(
        byKey('job.viewTerms'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(byKey('job.viewTerms'));
      await tester.pumpAndSettle();
      expect(byKey('terms.sheet'), findsOneWidget);
    });
  });

  group('Google sign-in (auth follow-ups)', () {
    test('each attempt after the first gets a fresh nonce', () async {
      final initCalls = <String>[];
      final nonceCalls = <String>[];
      final auth = GoogleSignInAuth(
        'server-id',
        perAttemptNonce: true,
        initialize: (id, hashed) async => initCalls.add(hashed),
        setNonce: (id, hashed) async {
          expect(id, 'server-id');
          nonceCalls.add(hashed);
        },
      );
      final first = await auth.nextNonce();
      final second = await auth.nextNonce();
      final third = await auth.nextNonce();
      expect(initCalls, [sha256Hex(first)]);
      expect(nonceCalls, [sha256Hex(second), sha256Hex(third)]);
      expect({first, second, third}, hasLength(3));
    });

    test('without per-attempt support one nonce covers the session', () async {
      var inits = 0;
      final auth = GoogleSignInAuth(
        'server-id',
        perAttemptNonce: false,
        initialize: (_, _) async => inits++,
        setNonce: (_, _) async => fail('must not re-initialize'),
      );
      expect(await auth.nextNonce(), await auth.nextNonce());
      expect(inits, 1);
    });

    testWidgets('the Google button carries the official G mark', (
      tester,
    ) async {
      await pumpAuthApp(
        tester,
        handler: routeHandler({}),
        google: FakeGoogleAuth(),
      );
      expect(byKey('auth.google'), findsOneWidget);
      expect(byKey('auth.google.mark'), findsOneWidget);
    });
  });
}
