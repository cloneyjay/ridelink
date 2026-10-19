import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridelink/core/location/geo_point.dart';
import 'package:ridelink/core/mode/app_mode.dart';
import 'package:ridelink/core/routing/app_router.dart';
import 'package:ridelink/features/booking/data/booking_models.dart';
import 'package:ridelink/features/orders/data/order_models.dart';
import 'package:ridelink/features/orders/order_labels.dart';
import 'package:ridelink/features/orders/order_providers.dart';
import 'package:ridelink/features/rider/data/rider_models.dart';

import '../../support/booking_fakes.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Finder byKey(String k) => find.byKey(Key(k));

  Order order(
    String id,
    String status, {
    int? price = 214,
    ServiceType service = ServiceType.delivery,
    String? senderId = testUserId,
    int day = 13,
  }) => Order(
    id: id,
    serviceType: service,
    status: status,
    pickupAddress: 'Westlands Mall',
    dropoffAddress: 'Moi Avenue $id',
    senderId: senderId,
    riderId: price == null ? null : 'rider-1',
    agreedPrice: price,
    acceptedAt: price == null ? null : DateTime.utc(2026, 10, day, 9),
    distanceKm: 4.8,
    createdAt: DateTime.utc(2026, 10, day, 9),
  );

  group('models', () {
    test(
      'GET /orders/{id} enrichment parses rider, sender, receiver and terms',
      () {
        final d = OrderDetails.fromJson({
          'id': 'o-1',
          'service_type': 'delivery',
          'status': 'accepted',
          'sender_id': 's-1',
          'pickup_address': 'A',
          'dropoff_address': 'B',
          'agreed_price': 350,
          'rider': {
            'rider_id': 'r-1',
            'display_name': 'Moses O.',
            'plate_number': 'KMFA 123B',
            'has_photo': true,
            'rating': {'average': 4.8, 'count': 12},
          },
          'sender': {'display_name': 'Grace W.'},
          'receiver_location': {
            'lat': -1.28,
            'lng': 36.82,
            'note': ' Blue gate ',
            'updated_at': '2026-10-13T09:45:00Z',
          },
          'terms': {
            'quote': {
              'total': 350,
              'currency': 'KES',
              'trip_distance_km': 6.2,
              'breakdown': {'base_fare': 80, 'platform_km': 6.2},
            },
            'cancel_policy': {
              'rider_cancel_grace_secs': 120,
              'pickup_window_mins': 10,
              'pickup_deadline': '2026-10-13T09:52:00Z',
            },
            'accepted_at': '2026-10-13T09:42:00Z',
          },
        });
        expect(d.order.senderId, 's-1');
        expect(d.rider!.plateNumber, 'KMFA 123B');
        expect(d.rider!.ratingCount, 12);
        expect(d.senderName, 'Grace W.');
        expect(d.receiverLocation!.point, const GeoPoint(-1.28, 36.82));
        expect(d.receiverLocation!.note, 'Blue gate');
        expect(d.terms!.total, 350);
        expect(d.terms!.pickupWindowMins, 10);
        expect(d.terms!.breakdown!.baseFare, 80);
        expect(roleFor(d, 's-1'), OrderRole.sender);
        expect(roleFor(d, 'r-1'), OrderRole.rider);
      },
    );

    test('null enrichment keys mean nothing yet', () {
      final d = OrderDetails.fromJson({
        'id': 'o-1',
        'status': 'created',
        'receiver_location': null,
        'terms': null,
      });
      expect(d.receiverLocation, isNull);
      expect(d.terms, isNull);
      expect(d.rider, isNull);
    });

    test('deep-link destinations', () {
      OrderDetails d(String status, {String? senderName}) => OrderDetails(
        order: order('o-1', status, senderId: null),
        senderName: senderName,
      );
      expect(
        routeForOrder(d('in_transit'), testUserId),
        AppRoutes.trackingFor('o-1'),
      );
      expect(
        routeForOrder(d('in_transit', senderName: 'Grace W.'), testUserId),
        AppRoutes.riderHome,
      );
      expect(
        routeForOrder(d('completed', senderName: 'Grace W.'), testUserId),
        AppRoutes.orderDetailFor('o-1', asRider: true),
      );
    });
  });

  group('history', () {
    testWidgets('sender history: newest first, status chips and agreed price', (
      tester,
    ) async {
      final orders = FakeOrdersRepository()
        ..senderOrdersList = [
          order('old', 'completed', day: 10),
          order('new', 'cancelled', price: null, day: 12),
        ];
      await pumpBookingApp(tester, orders: orders);
      await tester.tap(byKey('menu.open'));
      await tester.pumpAndSettle();
      await tapKeyAndSettle(tester, 'menu.history');
      final l = l10nOf(tester);
      expect(byKey('screen.history'), findsOneWidget);
      expect(find.text(l.historyTitle), findsOneWidget);
      final newer = tester.getTopLeft(byKey('history.order.new')).dy;
      final older = tester.getTopLeft(byKey('history.order.old')).dy;
      expect(newer, lessThan(older));
      expect(byKey('status.completed'), findsOneWidget);
      expect(find.text(l.statusCancelled), findsOneWidget);
      expect(tester.widget<Text>(byKey('history.price.old')).data, 'KES 214');
      expect(byKey('history.price.new'), findsNothing);
    });

    testWidgets('rider history uses the rider list', (tester) async {
      final orders = FakeOrdersRepository()
        ..riderOrdersList = [order('r', 'completed', senderId: 'someone')];
      await pumpBookingApp(
        tester,
        orders: orders,
        goTo: AppRoutes.historyFor(AppMode.rider),
      );
      expect(find.text(l10nOf(tester).historyRiderTitle), findsOneWidget);
      expect(byKey('history.order.r'), findsOneWidget);
    });

    testWidgets('empty and failed lists', (tester) async {
      final orders = FakeOrdersRepository()
        ..historyError = apiError(500, 'internal_error');
      await pumpBookingApp(tester, orders: orders, goTo: AppRoutes.history);
      expect(byKey('history.error'), findsOneWidget);
      orders.historyError = null;
      await tapKeyAndSettle(tester, 'history.retry');
      expect(byKey('history.empty'), findsOneWidget);
    });

    testWidgets('detail: route, price, rider, terms, evidence and my rating', (
      tester,
    ) async {
      final orders = FakeOrdersRepository()
        ..senderOrdersList = [order('o-1', 'completed')]
        ..fixedDetails['o-1'] = OrderDetails(
          order: order('o-1', 'completed'),
          rider: const OrderRider(
            riderId: 'rider-1',
            displayName: 'Moses O.',
            plateNumber: 'KMFA 123B',
            hasPhoto: false,
            ratingAverage: 4.9,
            ratingCount: 10,
          ),
          terms: const OrderTerms(
            total: 214,
            currency: 'KES',
            pickupWindowMins: 10,
          ),
        )
        ..ratingsByOrder['o-1'] = [
          const Rating(
            fromId: testUserId,
            toId: 'rider-1',
            score: 4,
            comment: 'Careful',
          ),
          const Rating(fromId: 'rider-1', toId: testUserId, score: 2),
        ];
      await pumpBookingApp(tester, orders: orders, goTo: AppRoutes.history);
      await tapKeyAndSettle(tester, 'history.order.o-1');
      final l = l10nOf(tester);
      expect(byKey('screen.orderDetail'), findsOneWidget);
      expect(tester.widget<Text>(byKey('orderDetail.price')).data, 'KES 214');
      expect(
        tester.widget<Text>(byKey('orderDetail.party')).data,
        'Moses O. · KMFA 123B',
      );
      expect(find.text('Moses O. · KMFA 123B'), findsOneWidget);
      await tester.scrollUntilVisible(
        byKey('orderDetail.myScore'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(tester.widget<StarRow>(byKey('orderDetail.myScore')).score, 4);
      expect(find.text('Careful'), findsOneWidget);
      expect(find.byType(StarRow), findsOneWidget, reason: 'only my rating');

      await tapKeyAndSettle(tester, 'orderDetail.terms');
      expect(byKey('terms.sheet'), findsOneWidget);
      expect(find.text(l.minutesShort(10)), findsOneWidget);
      Navigator.of(tester.element(byKey('terms.sheet'))).pop();
      await tester.pumpAndSettle();

      await tapKeyAndSettle(tester, 'orderDetail.evidence');
      expect(byKey('screen.evidence'), findsOneWidget);
    });

    testWidgets(
      'detail: an unrated completed order can be rated from history',
      (tester) async {
        final orders = FakeOrdersRepository()
          ..fixedDetails['o-1'] = OrderDetails(
            order: order('o-1', 'completed'),
          );
        await pumpBookingApp(
          tester,
          orders: orders,
          goTo: AppRoutes.orderDetailFor('o-1'),
        );
        await tapKeyAndSettle(tester, 'orderDetail.rate');
        await tester.tap(byKey('rating.star.5'));
        await tester.pump();
        await tapKeyAndSettle(tester, 'rating.submit');
        expect(orders.ratingCalls.single.score, 5);
        expect(byKey('orderDetail.myScore'), findsOneWidget);
      },
    );

    testWidgets('detail: a live order links back to tracking', (tester) async {
      final orders = FakeOrdersRepository()
        ..fixedDetails['order-9'] = OrderDetails(
          order: jobFixture(status: 'in_transit'),
        );
      await pumpBookingApp(
        tester,
        orders: orders,
        clock: () => testNow,
        goTo: AppRoutes.orderDetailFor('order-9'),
      );
      await tapKeyAndSettle(tester, 'orderDetail.openLive');
      expect(byKey('screen.tracking'), findsOneWidget);
    });
  });

  group('receiver link', () {
    testWidgets('sender shares the link in their language', (tester) async {
      final h = await pumpBookingApp(
        tester,
        repo: FakeBookingRepository()..order = jobFixture(status: 'in_transit'),
        clock: () => testNow,
        goTo: AppRoutes.trackingFor('order-9'),
      );
      await tapKeyAndSettle(tester, 'tracking.shareReceiver');
      expect(h.orders.receiverLinkCalls, 1);
      expect(
        h.share.shared.single,
        l10nOf(tester).receiverShareMessage(h.orders.receiverUrl),
      );
      expect(h.share.shared.single, contains('https://ridelink.test/r/abc123'));
    });

    testWidgets('link failure is shown localized', (tester) async {
      final orders = FakeOrdersRepository()
        ..receiverLinkError = apiError(422, 'invalid_status');
      final h = await pumpBookingApp(
        tester,
        repo: FakeBookingRepository()..order = jobFixture(status: 'in_transit'),
        orders: orders,
        clock: () => testNow,
        goTo: AppRoutes.trackingFor('order-9'),
      );
      await tapKeyAndSettle(tester, 'tracking.shareReceiver');
      expect(h.share.shared, isEmpty);
      expect(find.text(l10nOf(tester).errCodeInvalidStatus), findsOneWidget);
    });

    testWidgets('rides have no receiver link', (tester) async {
      await pumpBookingApp(
        tester,
        repo: FakeBookingRepository()
          ..order = jobFixture(status: 'in_transit', service: ServiceType.ride),
        clock: () => testNow,
        goTo: AppRoutes.trackingFor('order-9'),
      );
      expect(byKey('tracking.shareReceiver'), findsNothing);
    });

    testWidgets("rider sees the receiver's spot and note and can navigate", (
      tester,
    ) async {
      final job = jobFixture(status: 'in_transit');
      final orders = FakeOrdersRepository()
        ..receiverLocation = const ReceiverLocation(
          point: GeoPoint(-1.29, 36.83),
          note: 'Blue gate opposite the kiosk',
        );
      final h = await pumpBookingApp(
        tester,
        orders: orders,
        clock: () => testNow,
        riderRepo: FakeRiderRepository(activeResult: RiderActive(order: job))
          ..job = job,
        goTo: AppRoutes.riderHome,
      );
      await tester.scrollUntilVisible(
        byKey('job.navigate.receiver'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(
        find.text(
          l10nOf(tester).receiverSpotNote('Blue gate opposite the kiosk'),
        ),
        findsOneWidget,
      );
      await tester.tap(byKey('job.navigate.receiver'));
      await tester.pumpAndSettle();
      expect(h.navigation.destinations.single, const GeoPoint(-1.29, 36.83));
    });

    testWidgets('a receiver_location_shared notification reloads the spot', (
      tester,
    ) async {
      final job = jobFixture(status: 'in_transit');
      final orders = FakeOrdersRepository();
      final h = await pumpBookingApp(
        tester,
        orders: orders,
        clock: () => testNow,
        riderRepo: FakeRiderRepository(activeResult: RiderActive(order: job))
          ..job = job,
        goTo: AppRoutes.riderHome,
      );
      expect(byKey('job.receiverSpot'), findsNothing);
      orders.receiverLocation = const ReceiverLocation(
        point: GeoPoint(-1.29, 36.83),
      );
      h.emit('notification.created', {
        'id': 'n-5',
        'order_id': 'order-9',
        'type': 'receiver_location_shared',
        'data': {'order_id': 'order-9'},
      });
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        byKey('job.receiverSpot'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(byKey('job.receiverSpot.note'), findsNothing);
    });
  });

  group('navigate hand-off', () {
    Future<BookingHarness> job(WidgetTester tester, String status) {
      final o = jobFixture(status: status);
      return pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: FakeRiderRepository(activeResult: RiderActive(order: o))
          ..job = o,
        goTo: AppRoutes.riderHome,
      );
    }

    testWidgets('pickup step navigates to the pickup', (tester) async {
      final h = await job(tester, 'accepted');
      await tester.scrollUntilVisible(
        byKey('job.navigate.pickup'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(byKey('job.navigate.pickup'));
      await tester.pumpAndSettle();
      expect(
        h.navigation.destinations.single,
        const GeoPoint(-1.2648, 36.8025),
      );
    });

    testWidgets(
      'drop-off step navigates to the drop-off; failure is explained',
      (tester) async {
        final h = await job(tester, 'started');
        h.navigation.result = false;
        await tester.scrollUntilVisible(
          byKey('job.navigate.dropoff'),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(byKey('job.navigate.dropoff'));
        await tester.pumpAndSettle();
        expect(
          h.navigation.destinations.single,
          const GeoPoint(-1.2833, 36.8219),
        );
        expect(byKey('job.navigateFailed'), findsOneWidget);
      },
    );
  });
}
