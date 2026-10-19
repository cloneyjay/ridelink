import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridelink/core/api/api_exception.dart';
import 'package:ridelink/core/routing/app_router.dart';
import 'package:ridelink/features/booking/booking_routes.dart';
import 'package:ridelink/features/booking/offer_waiting_screen.dart';

import '../../support/booking_fakes.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Finder byKey(String k) => find.byKey(Key(k));

  /// Advances fake time in small steps without waiting for the countdown to settle.
  Future<void> advance(WidgetTester tester, Duration total) async {
    const step = Duration(milliseconds: 100);
    for (var t = Duration.zero; t < total; t += step) {
      await tester.pump(step);
    }
  }

  Future<BookingHarness> openWaiting(
    WidgetTester tester, {
    FakeBookingRepository? repo,
    Duration window = const Duration(seconds: 60),
  }) async {
    final h = await pumpBookingApp(
      tester,
      repo: repo,
      goTo: AppRoutes.waitingFor('order-1'),
      extra: PendingOffer(
        order: orderFixture(),
        rider: riderFixture(),
        offer: offerFixture(window: window),
      ),
      settle: false,
    );
    await advance(tester, const Duration(milliseconds: 500));
    return h;
  }

  Future<void> leave(BookingHarness h, WidgetTester tester) async {
    h.router.go(AppRoutes.home);
    await tester.pumpAndSettle();
  }

  String seconds(WidgetTester tester) =>
      tester.widget<Text>(byKey('countdown.seconds')).data!;

  testWidgets('countdown starts at the server window and ticks down', (
    tester,
  ) async {
    final h = await openWaiting(tester);
    expect(byKey('screen.offerWaiting'), findsOneWidget);
    expect(find.text('Waiting for Moses O.'), findsOneWidget);
    expect(seconds(tester), '60');
    expect(tester.widget<Text>(byKey('waiting.total')).data, 'KES 214');
    await advance(tester, const Duration(seconds: 3));
    expect(seconds(tester), '57');
    await leave(h, tester);
  });

  testWidgets('offer.resolved accepted opens tracking', (tester) async {
    final h = await openWaiting(tester);
    h.emit('offer.resolved', {
      'offer_id': 'offer-1',
      'order_id': 'order-1',
      'outcome': 'accepted',
    });
    await tester.pumpAndSettle();
    expect(byKey('screen.tracking'), findsOneWidget);
    expect(find.text('Moses O.'), findsOneWidget);
  });

  testWidgets('declined returns to the rider list with a message', (
    tester,
  ) async {
    final h = await openWaiting(tester);
    h.emit('offer.resolved', {
      'offer_id': 'offer-1',
      'order_id': 'order-1',
      'outcome': 'declined',
    });
    await tester.pumpAndSettle();
    expect(byKey('screen.riderList'), findsOneWidget);
    expect(
      find.text('The rider declined. Choose another rider.'),
      findsOneWidget,
    );
  });

  testWidgets('expired returns to the rider list with a message', (
    tester,
  ) async {
    final h = await openWaiting(tester);
    h.emit('offer.resolved', {
      'offer_id': 'offer-1',
      'order_id': 'order-1',
      'outcome': 'expired',
    });
    await tester.pumpAndSettle();
    expect(byKey('screen.riderList'), findsOneWidget);
    expect(
      find.text("The rider didn't respond in time. Choose another rider."),
      findsOneWidget,
    );
  });

  testWidgets('events for another offer are ignored', (tester) async {
    final h = await openWaiting(tester);
    h.emit('offer.resolved', {
      'offer_id': 'offer-other',
      'order_id': 'order-9',
      'outcome': 'accepted',
    });
    await advance(tester, const Duration(milliseconds: 300));
    expect(byKey('screen.offerWaiting'), findsOneWidget);
    await leave(h, tester);
  });

  testWidgets('back navigation is blocked while waiting', (tester) async {
    final h = await openWaiting(tester);
    final popped = await tester.binding.handlePopRoute();
    await advance(tester, const Duration(milliseconds: 300));
    expect(popped, isTrue);
    expect(byKey('screen.offerWaiting'), findsOneWidget);
    await leave(h, tester);
  });

  group('cancel', () {
    testWidgets('confirmed cancel cancels the order and goes home', (
      tester,
    ) async {
      final h = await openWaiting(tester);
      await tester.tap(byKey('waiting.cancel'));
      await advance(tester, const Duration(milliseconds: 500));
      expect(byKey('waiting.cancelDialog'), findsOneWidget);
      await tester.tap(byKey('waiting.cancelDialog.yes'));
      await tester.pumpAndSettle();
      expect(h.repo.cancelCalls, 1);
      expect(byKey('screen.home'), findsOneWidget);
      expect(find.text('Your order was cancelled.'), findsOneWidget);
    });

    testWidgets('keep waiting dismisses without cancelling', (tester) async {
      final h = await openWaiting(tester);
      await tester.tap(byKey('waiting.cancel'));
      await advance(tester, const Duration(milliseconds: 500));
      await tester.tap(byKey('waiting.cancelDialog.no'));
      await advance(tester, const Duration(milliseconds: 500));
      expect(h.repo.cancelCalls, 0);
      expect(byKey('screen.offerWaiting'), findsOneWidget);
      await leave(h, tester);
    });

    testWidgets('failed cancel keeps waiting and explains', (tester) async {
      final repo = FakeBookingRepository()
        ..cancelError = const ApiException(statusCode: 422, message: 'x');
      final h = await openWaiting(tester, repo: repo);
      await tester.tap(byKey('waiting.cancel'));
      await advance(tester, const Duration(milliseconds: 500));
      await tester.tap(byKey('waiting.cancelDialog.yes'));
      await advance(tester, const Duration(milliseconds: 500));
      expect(byKey('waiting.cancelFailed'), findsOneWidget);
      expect(byKey('screen.offerWaiting'), findsOneWidget);
      await leave(h, tester);
    });
  });

  testWidgets(
    'after the deadline a missed event falls back to the server status',
    (tester) async {
      final repo = FakeBookingRepository()
        ..order = orderFixture(status: 'created');
      final h = await openWaiting(
        tester,
        repo: repo,
        window: const Duration(seconds: 2),
      );
      await advance(tester, const Duration(seconds: 2));
      expect(seconds(tester), '0');
      expect(find.text("Checking the rider's response…"), findsOneWidget);
      expect(h.repo.getOrderCalls, 0);

      await advance(tester, OfferWaitingScreen.statusCheckDelay);
      await tester.pumpAndSettle();
      expect(h.repo.getOrderCalls, 1);
      expect(byKey('screen.riderList'), findsOneWidget);
      expect(
        find.text("The rider didn't respond in time. Choose another rider."),
        findsOneWidget,
      );
    },
  );
}
