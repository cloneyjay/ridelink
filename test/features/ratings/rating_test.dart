import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridelink/core/routing/app_router.dart';
import 'package:ridelink/core/storage/local_store.dart';
import 'package:ridelink/features/booking/data/booking_models.dart';
import 'package:ridelink/features/orders/data/order_models.dart';
import 'package:ridelink/features/orders/order_providers.dart';
import 'package:ridelink/features/ratings/rating_prompt_store.dart';
import 'package:ridelink/features/ratings/rating_sheet.dart';
import 'package:ridelink/features/rider/data/rider_models.dart';

import '../../support/booking_fakes.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Finder byKey(String k) => find.byKey(Key(k));

  Future<BookingHarness> completedTracking(
    WidgetTester tester, {
    FakeOrdersRepository? orders,
    MemoryLocalStore? store,
  }) => pumpBookingApp(
    tester,
    repo: FakeBookingRepository()..order = jobFixture(status: 'completed'),
    orders: orders,
    store: store,
    clock: () => testNow,
    goTo: AppRoutes.trackingFor('order-9'),
  );

  test('prompt store remembers each order once', () async {
    final store = RatingPromptStore(MemoryLocalStore());
    expect(store.wasPrompted('a'), isFalse);
    await store.markPrompted('a');
    await store.markPrompted('a');
    expect(store.wasPrompted('a'), isTrue);
    expect(store.wasPrompted('b'), isFalse);
  });

  test('who is rated depends on role and service', () {
    expect(
      ratingTargetFor(OrderRole.sender, ServiceType.ride),
      RatingTarget.rider,
    );
    expect(
      ratingTargetFor(OrderRole.rider, ServiceType.delivery),
      RatingTarget.sender,
    );
    expect(
      ratingTargetFor(OrderRole.rider, ServiceType.ride),
      RatingTarget.passenger,
    );
  });

  testWidgets('completion prompts the sender: stars + comment are sent', (
    tester,
  ) async {
    final h = await completedTracking(tester);
    final l = l10nOf(tester);
    expect(byKey('rating.sheet'), findsOneWidget);
    expect(find.text(l.rateRiderTitle), findsOneWidget);
    final submit = tester.widget<ElevatedButton>(
      find.descendant(
        of: byKey('rating.submit'),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(submit.onPressed, isNull, reason: 'a score is required');

    await tester.tap(byKey('rating.star.4'));
    await tester.pump();
    await tester.enterText(byKey('rating.comment'), '  On time, careful  ');
    await tapKeyAndSettle(tester, 'rating.submit');
    expect(h.orders.ratingCalls.single, (
      orderId: 'order-9',
      score: 4,
      comment: 'On time, careful',
    ));
    expect(byKey('rating.sheet'), findsNothing);
    expect(byKey('rating.thanks'), findsOneWidget);
  });

  testWidgets('skipping is remembered: no second prompt for the order', (
    tester,
  ) async {
    final store = MemoryLocalStore();
    await completedTracking(tester, store: store);
    await tapKeyAndSettle(tester, 'rating.skip');
    expect(byKey('rating.sheet'), findsNothing);

    await tapKeyAndSettle(tester, 'tracking.home');
    await pumpBookingApp(
      tester,
      repo: FakeBookingRepository()..order = jobFixture(status: 'completed'),
      store: store,
      clock: () => testNow,
      goTo: AppRoutes.trackingFor('order-9'),
    );
    expect(byKey('rating.sheet'), findsNothing);
  });

  testWidgets('no prompt when this party already rated (another device)', (
    tester,
  ) async {
    final orders = FakeOrdersRepository()
      ..ratingsByOrder['order-9'] = [
        const Rating(fromId: testUserId, toId: 'rider', score: 5),
      ];
    await completedTracking(tester, orders: orders);
    expect(byKey('rating.sheet'), findsNothing);
  });

  testWidgets('409 already_rated closes the sheet with a message', (
    tester,
  ) async {
    final orders = FakeOrdersRepository()
      ..ratingError = apiError(409, 'already_rated');
    await completedTracking(tester, orders: orders);
    await tester.tap(byKey('rating.star.5'));
    await tester.pump();
    await tapKeyAndSettle(tester, 'rating.submit');
    expect(byKey('rating.sheet'), findsNothing);
    expect(byKey('rating.already'), findsOneWidget);
    expect(find.text(l10nOf(tester).errCodeAlreadyRated), findsOneWidget);
  });

  testWidgets('other failures keep the sheet open with the error', (
    tester,
  ) async {
    final orders = FakeOrdersRepository()
      ..ratingError = apiError(500, 'internal_error');
    await completedTracking(tester, orders: orders);
    await tester.tap(byKey('rating.star.3'));
    await tester.pump();
    await tapKeyAndSettle(tester, 'rating.submit');
    expect(byKey('rating.sheet'), findsOneWidget);
    expect(find.text(l10nOf(tester).ratingFailed), findsOneWidget);
  });

  testWidgets('a rider on a ride rates the passenger', (tester) async {
    final job = jobFixture(status: 'completed', service: ServiceType.ride);
    await pumpBookingApp(
      tester,
      clock: () => testNow,
      riderRepo: FakeRiderRepository(activeResult: RiderActive(order: job))
        ..job = job,
      goTo: AppRoutes.riderHome,
    );
    expect(find.text(l10nOf(tester).ratePassengerTitle), findsOneWidget);
  });
}
