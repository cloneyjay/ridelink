import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridelink/core/api/api_exception.dart';
import 'package:ridelink/core/routing/app_router.dart';
import 'package:ridelink/features/booking/booking_routes.dart';
import 'package:ridelink/features/booking/data/booking_models.dart';

import '../../support/booking_fakes.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Finder byKey(String k) => find.byKey(Key(k));

  Future<BookingHarness> openRiders(
    WidgetTester tester, {
    FakeBookingRepository? repo,
    Order? order,
    bool withExtra = true,
    bool settle = true,
  }) => pumpBookingApp(
    tester,
    repo: repo,
    goTo: AppRoutes.ridersFor('order-1'),
    extra: withExtra ? RiderListArgs(order: order ?? orderFixture()) : null,
    settle: settle,
  );

  void useTallView(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  double rowTop(WidgetTester tester, String riderId) =>
      tester.getTopLeft(byKey('riders.row.$riderId')).dy;

  group('rider list (decision 7)', () {
    testWidgets('loading, then the riders with their total price', (
      tester,
    ) async {
      final repo = FakeBookingRepository()..ridersGate = Completer();
      await openRiders(tester, repo: repo, settle: false);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      repo.ridersGate!.complete(repo.riders);
      await tester.pumpAndSettle();
      expect(byKey('riders.row.rider-1'), findsOneWidget);
      expect(find.text('KES 214'), findsOneWidget);
      expect(find.text('Moses O.'), findsOneWidget);
      expect(find.text('98% on time · 340 completed'), findsOneWidget);
      expect(
        find.text('0.8 km from pickup · Arrives within 10 min'),
        findsOneWidget,
      );
      expect(find.text('Trip 4.8 km'), findsOneWidget);
      expect(byKey('riders.estimatedNote'), findsNothing);
    });

    testWidgets('empty state with retry', (tester) async {
      final repo = FakeBookingRepository()
        ..riders = const RiderList(
          tripDistanceKm: 4.8,
          distanceEstimated: false,
          riders: [],
        );
      final h = await openRiders(tester, repo: repo);
      expect(byKey('riders.empty'), findsOneWidget);
      expect(find.text('No riders nearby right now'), findsOneWidget);
      await tester.tap(byKey('riders.retry'));
      await tester.pumpAndSettle();
      expect(h.repo.ridersCalls, 2);
    });

    testWidgets('error state; retry recovers', (tester) async {
      final repo = FakeBookingRepository()
        ..ridersError = const ApiException(message: 'offline');
      await openRiders(tester, repo: repo);
      expect(byKey('riders.error'), findsOneWidget);
      repo.ridersError = null;
      await tester.tap(byKey('riders.retry'));
      await tester.pumpAndSettle();
      expect(byKey('riders.row.rider-1'), findsOneWidget);
    });

    testWidgets('sort toggle switches between price and distance', (
      tester,
    ) async {
      final repo = FakeBookingRepository()
        ..riders = RiderList(
          tripDistanceKm: 4.8,
          distanceEstimated: false,
          riders: [
            riderFixture(
              id: 'near',
              name: 'Near R.',
              total: 300,
              pickupKm: 0.3,
            ),
            riderFixture(
              id: 'cheap',
              name: 'Cheap R.',
              total: 180,
              pickupKm: 2.5,
            ),
          ],
        );
      await openRiders(tester, repo: repo);
      expect(rowTop(tester, 'cheap'), lessThan(rowTop(tester, 'near')));

      await tester.tap(byKey('riders.sort.distance'));
      await tester.pumpAndSettle();
      expect(rowTop(tester, 'near'), lessThan(rowTop(tester, 'cheap')));

      await tester.tap(byKey('riders.sort.price'));
      await tester.pumpAndSettle();
      expect(rowTop(tester, 'cheap'), lessThan(rowTop(tester, 'near')));
    });

    testWidgets('estimated distance note and riders without stats', (
      tester,
    ) async {
      final repo = FakeBookingRepository()
        ..riders = RiderList(
          tripDistanceKm: 5.1,
          distanceEstimated: true,
          riders: [
            riderFixture(
              ratingCount: 0,
              rating: 0,
              onTime: null,
              completed: null,
            ),
          ],
        );
      await openRiders(tester, repo: repo);
      expect(byKey('riders.estimatedNote'), findsOneWidget);
      expect(find.text('No ratings yet'), findsOneWidget);
      expect(find.textContaining('on time'), findsNothing);
      expect(find.text('MO'), findsOneWidget, reason: 'initials, no photo');
    });

    testWidgets('without route extra the order is fetched by id', (
      tester,
    ) async {
      final h = await openRiders(tester, withExtra: false);
      expect(h.repo.getOrderCalls, 1);
      expect(byKey('riders.row.rider-1'), findsOneWidget);
    });

    testWidgets('edit route saves via PATCH and refreshes riders', (
      tester,
    ) async {
      final h = await openRiders(tester);
      await tapKeyAndSettle(tester, 'riders.editRoute');
      expect(byKey('screen.editRoute'), findsOneWidget);

      await tapKeyAndSettle(tester, 'route.dropoff');
      await tester.enterText(byKey('placeSearch.input'), 'West');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      await tester.tap(byKey('placeSearch.result.p-westlands'));
      await tester.pumpAndSettle();
      await tapKeyAndSettle(tester, 'editRoute.save');

      expect(h.repo.routeCalls.single.dropoff.placeId, 'p-westlands');
      expect(h.repo.routeCalls.single.pickup.address, westlands.label);
      expect(byKey('screen.riderList'), findsOneWidget);
      expect(h.repo.ridersCalls, 2);
    });

    testWidgets('locked route (422) explains it can no longer change', (
      tester,
    ) async {
      final repo = FakeBookingRepository()
        ..routeError = const ApiException(statusCode: 422, message: 'x');
      await openRiders(tester, repo: repo);
      await tapKeyAndSettle(tester, 'riders.editRoute');
      await tapKeyAndSettle(tester, 'route.pickup');
      await tester.enterText(byKey('placeSearch.input'), 'Moi');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      await tester.tap(byKey('placeSearch.result.p-cbd'));
      await tester.pumpAndSettle();
      await tapKeyAndSettle(tester, 'editRoute.save');
      expect(byKey('screen.confirmPickup'), findsOneWidget);
      await tapKeyAndSettle(tester, 'confirmPickup.confirm');
      expect(find.text('This route can no longer be changed.'), findsOneWidget);
    });

    testWidgets('edit route is hidden unless the order is created', (
      tester,
    ) async {
      await openRiders(tester, order: orderFixture(status: 'offered'));
      expect(byKey('riders.editRoute'), findsNothing);
    });
  });

  group('rider profile (screen 3) and quote (screen 5)', () {
    testWidgets('profile shows stats and the price breakdown', (tester) async {
      useTallView(tester);
      final repo = FakeBookingRepository()
        ..riders = RiderList(
          tripDistanceKm: 12,
          distanceEstimated: false,
          riders: [riderFixture(total: 300, riderKm: 2)],
        );
      await openRiders(tester, repo: repo);
      await tapKeyAndSettle(tester, 'riders.row.rider-1');
      expect(byKey('screen.riderProfile'), findsOneWidget);
      expect(find.text('Base fare'), findsOneWidget);
      expect(find.text('KES 80'), findsOneWidget);
      expect(find.text('Platform rate for 4.8 km'), findsOneWidget);
      expect(find.text('KES 77'), findsOneWidget);
      expect(find.text('Rider rate beyond 4.8 km'), findsOneWidget);
      expect(find.text('2 km at KES 25 per km'), findsOneWidget);
      expect(find.text('KES 50'), findsOneWidget);
      expect(byKey('profile.breakdown.minimum'), findsNothing);
      expect(tester.widget<Text>(byKey('profile.total')).data, 'KES 300');
    });

    testWidgets('minimum fare note; no rider row within max distance', (
      tester,
    ) async {
      useTallView(tester);
      final repo = FakeBookingRepository()
        ..riders = RiderList(
          tripDistanceKm: 1,
          distanceEstimated: false,
          riders: [riderFixture(total: 120, minimumFare: true)],
        );
      await openRiders(tester, repo: repo);
      await tapKeyAndSettle(tester, 'riders.row.rider-1');
      expect(byKey('profile.breakdown.minimum'), findsOneWidget);
      expect(byKey('profile.breakdown.rider'), findsNothing);
    });

    testWidgets('request -> final quote -> send request -> waiting', (
      tester,
    ) async {
      final h = await openRiders(tester);
      await tapKeyAndSettle(tester, 'riders.row.rider-1');
      await tapKeyAndSettle(tester, 'profile.request');
      expect(byKey('screen.quote'), findsOneWidget);
      expect(tester.widget<Text>(byKey('quote.total')).data, 'KES 214');
      expect(
        find.text('This price is final. It is locked once the rider accepts.'),
        findsOneWidget,
      );
      expect(find.textContaining('Negotiat'), findsNothing);

      await tester.tap(byKey('quote.send'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(h.repo.offerCalls.single, (
        orderId: 'order-1',
        riderId: 'rider-1',
      ));
      expect(byKey('screen.offerWaiting'), findsOneWidget);

      h.router.go(AppRoutes.home);
      await tester.pumpAndSettle();
    });

    testWidgets('send failure shows an error on the quote', (tester) async {
      final repo = FakeBookingRepository()
        ..offerError = const ApiException(statusCode: 422, message: 'x');
      await openRiders(tester, repo: repo);
      await tapKeyAndSettle(tester, 'riders.row.rider-1');
      await tapKeyAndSettle(tester, 'profile.request');
      await tapKeyAndSettle(tester, 'quote.send');
      expect(byKey('quote.error'), findsOneWidget);
      expect(byKey('screen.quote'), findsOneWidget);
    });
  });
}
