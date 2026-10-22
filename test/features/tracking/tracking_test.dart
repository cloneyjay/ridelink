import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridelink/core/mode/app_mode.dart';
import 'package:ridelink/core/routing/app_router.dart';
import 'package:ridelink/features/booking/data/booking_models.dart';
import 'package:ridelink/features/tracking/tracking_screen.dart';

import '../../support/booking_fakes.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Finder byKey(String k) => find.byKey(Key(k));

  final args = TrackingArgs(
    riderId: 'rider-1',
    riderName: 'Moses O.',
    breakdown: riderFixture().breakdown,
  );

  Future<BookingHarness> openTracking(
    WidgetTester tester,
    Order order, {
    DateTime Function()? clock,
  }) => pumpBookingApp(
    tester,
    repo: FakeBookingRepository()..order = order,
    clock: clock ?? () => testNow,
    goTo: AppRoutes.trackingFor(order.id),
    extra: args,
  );

  group('sender tracking (screen 7)', () {
    testWidgets(
      'one countdown until the rider arrives, then the arrived state',
      (tester) async {
        var now = testNow;
        final h = await openTracking(tester, jobFixture(), clock: () => now);
        final l = l10nOf(tester);
        expect(byKey('screen.tracking'), findsOneWidget);
        expect(byKey('home.mapPlaceholder'), findsOneWidget);
        expect(find.text('Moses O.'), findsOneWidget);
        expect(find.text(l.riderArrivesIn(10)), findsOneWidget);
        expect(byKey('tracking.step.accepted.current'), findsOneWidget);

        now = now.add(const Duration(minutes: 3));
        await tester.pump(const Duration(seconds: 1));
        expect(find.text(l.riderArrivesIn(7)), findsOneWidget);

        h.emit('rider.location', {
          'order_id': 'order-9',
          'rider_id': 'rider-1',
          'lat': -1.27,
          'lng': 36.81,
        });
        h.emit('order.updated', {
          'order_id': 'order-9',
          'status': 'accepted',
          'pickup_arrived_at': '2026-10-13T09:47:00Z',
        });
        await tester.pumpAndSettle();
        expect(byKey('tracking.countdown'), findsNothing);
        expect(byKey('tracking.arrived'), findsOneWidget);
        expect(byKey('tracking.step.atPickup.current'), findsOneWidget);
      },
    );

    testWidgets(
      'payment step: the rider confirms; completion shows delivered',
      (tester) async {
        final h = await openTracking(
          tester,
          jobFixture(status: 'payment_requested'),
        );
        final l = l10nOf(tester);
        expect(byKey('tracking.payNow'), findsOneWidget);
        expect(byKey('tracking.step.payment.current'), findsOneWidget);
        expect(byKey('tracking.ivePaid'), findsNothing);

        h.emit('order.updated', {'order_id': 'order-9', 'status': 'completed'});
        await tester.pumpAndSettle();
        expect(tester.widget<Text>(byKey('tracking.done')).data, l.delivered);
        expect(byKey('tracking.payNow'), findsNothing);
        // Completion asks the sender to rate the rider once; skippable.
        expect(byKey('rating.sheet'), findsOneWidget);
        await tapKeyAndSettle(tester, 'rating.skip');
        await tapKeyAndSettle(tester, 'tracking.home');
        expect(byKey('screen.home'), findsOneWidget);
      },
    );

    testWidgets('not paid asks the sender "Did you pay?"', (tester) async {
      final h = await openTracking(
        tester,
        jobFixture(status: 'payment_requested'),
      );
      // The server now reports the order unresolved with the answer pending.
      h.repo.order = jobFixture(status: 'unresolved');
      h.emit('order.updated', {'order_id': 'order-9', 'status': 'unresolved'});
      await tester.pumpAndSettle();
      expect(h.orders.paymentCalls, greaterThanOrEqualTo(2));
      expect(byKey('tracking.unresolved'), findsOneWidget);
      expect(byKey('payer.prompt'), findsOneWidget);
      expect(byKey('tracking.payNow'), findsNothing);
      expect(find.text(l10nOf(tester).payerPromptTitle), findsOneWidget);
    });

    testWidgets('legacy cash_pending still shows the waiting state', (
      tester,
    ) async {
      await openTracking(tester, jobFixture(status: 'cash_pending'));
      expect(byKey('tracking.waitingRider'), findsOneWidget);
      expect(byKey('tracking.payNow'), findsNothing);
    });

    testWidgets('pickup timeout cancellation is explained', (tester) async {
      final h = await openTracking(tester, jobFixture());
      h.emit('order.updated', {
        'order_id': 'order-9',
        'status': 'cancelled',
        'cancel_reason': 'pickup_timeout',
      });
      await tester.pumpAndSettle();
      expect(find.text(l10nOf(tester).orderCancelledTimeout), findsOneWidget);
      expect(byKey('tracking.cancel'), findsNothing);
    });

    testWidgets('View terms shows route, breakdown, price and pickup window', (
      tester,
    ) async {
      await openTracking(tester, jobFixture(status: 'in_transit'));
      await tapKeyAndSettle(tester, 'tracking.viewTerms');
      expect(byKey('terms.sheet'), findsOneWidget);
      expect(find.text(l10nOf(tester).breakdownBaseFare), findsOneWidget);
      final total = find.descendant(
        of: byKey('terms.total'),
        matching: find.text('KES 214'),
      );
      expect(total, findsOneWidget);
      expect(
        find.descendant(
          of: byKey('terms.window'),
          matching: find.text('10 min'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('sender can cancel while the rider is on the way', (
      tester,
    ) async {
      final h = await openTracking(tester, jobFixture());
      await tapKeyAndSettle(tester, 'tracking.cancel');
      await tapKeyAndSettle(tester, 'tracking.cancelDialog.yes');
      expect(h.repo.cancelCalls, 1);
      expect(byKey('tracking.cancelled'), findsOneWidget);
    });

    testWidgets('after a restart the active order reopens once from home', (
      tester,
    ) async {
      final repo = FakeBookingRepository()
        ..activeList = [SenderOrder(order: jobFixture(status: 'in_transit'))]
        ..order = jobFixture(status: 'in_transit');
      await pumpBookingApp(tester, repo: repo, clock: () => testNow);
      expect(byKey('screen.tracking'), findsOneWidget);
      expect(byKey('tracking.inTransit'), findsOneWidget);

      await tapKeyAndSettle(tester, 'tracking.back');
      expect(byKey('screen.home'), findsOneWidget);
      expect(byKey('home.activeOrder.order-9'), findsOneWidget);
      await tapKeyAndSettle(tester, 'home.activeOrder.order-9');
      expect(byKey('screen.tracking'), findsOneWidget);
    });
  });

  group('phase 1 follow-ups', () {
    testWidgets(
      'leaving the rider list asks to discard and cancels the order',
      (tester) async {
        final h = await pumpBookingApp(
          tester,
          goTo: AppRoutes.ridersFor('order-1'),
        );
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(byKey('riders.discardDialog'), findsOneWidget);
        await tapKeyAndSettle(tester, 'riders.discardDialog.no');
        expect(byKey('screen.riderList'), findsOneWidget);
        expect(h.repo.cancelCalls, 0);

        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        await tapKeyAndSettle(tester, 'riders.discardDialog.yes');
        expect(h.repo.cancelCalls, 1);
        expect(byKey('screen.home'), findsOneWidget);
      },
    );

    testWidgets('discard failure keeps the list and says so', (tester) async {
      final h = await pumpBookingApp(
        tester,
        repo: FakeBookingRepository()..cancelError = Exception('offline'),
        goTo: AppRoutes.ridersFor('order-1'),
      );
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tapKeyAndSettle(tester, 'riders.discardDialog.yes');
      expect(byKey('riders.discardFailed'), findsOneWidget);
      expect(byKey('screen.riderList'), findsOneWidget);
      expect(h.repo.cancelCalls, 1);
    });

    testWidgets('app opens the last-used mode on launch', (tester) async {
      await pumpBookingApp(
        tester,
        initialLocation: AppRoutes.splash,
        modeStore: MemoryModeStore(AppMode.rider),
      );
      expect(byKey('screen.riderHome'), findsOneWidget);
    });

    testWidgets('switching sides is remembered on the device', (tester) async {
      final store = MemoryModeStore();
      await pumpBookingApp(
        tester,
        account: FakeAccountRepository(rider: true),
        modeStore: store,
      );
      expect(store.mode, isNot(AppMode.rider));
      await tester.tap(byKey('menu.open'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('menu.switchToRiding'));
      await tester.pumpAndSettle();
      expect(store.mode, AppMode.rider);
    });
  });
}
