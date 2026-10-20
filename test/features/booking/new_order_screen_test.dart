import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridelink/core/api/api_exception.dart';
import 'package:ridelink/core/routing/app_router.dart';
import 'package:ridelink/features/booking/data/booking_models.dart';
import 'package:ridelink/features/booking/data/booking_repository.dart';

import '../../support/booking_fakes.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Finder byKey(String k) => find.byKey(Key(k));

  Future<BookingHarness> openNewOrder(
    WidgetTester tester,
    ServiceType service, {
    FakeBookingRepository? repo,
  }) =>
      pumpBookingApp(tester, repo: repo, goTo: AppRoutes.newOrderFor(service));

  /// Opens the place search from [fieldKey], types [query] and picks [placeId].
  Future<void> pickPlace(
    WidgetTester tester,
    String fieldKey,
    String query,
    String placeId,
  ) async {
    await tapKeyAndSettle(tester, fieldKey);
    await tester.enterText(byKey('placeSearch.input'), query);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await tester.tap(byKey('placeSearch.result.$placeId'));
    await tester.pumpAndSettle();
  }

  group('place search', () {
    testWidgets('under 2 characters shows a hint and sends nothing', (
      tester,
    ) async {
      final h = await openNewOrder(tester, ServiceType.ride);
      await tapKeyAndSettle(tester, 'route.pickup');
      await tester.enterText(byKey('placeSearch.input'), 'W');
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Type at least 2 letters'), findsOneWidget);
      expect(h.repo.autocompleteCalls, isEmpty);
    });

    testWidgets('debounces typing to one call after 300 ms', (tester) async {
      final h = await openNewOrder(tester, ServiceType.ride);
      await tapKeyAndSettle(tester, 'route.pickup');
      await tester.enterText(byKey('placeSearch.input'), 'We');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(byKey('placeSearch.input'), 'Wes');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(byKey('placeSearch.input'), 'West');
      await tester.pump(const Duration(milliseconds: 299));
      expect(h.repo.autocompleteCalls, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();
      expect(h.repo.autocompleteCalls.map((c) => c.input), ['West']);
      expect(byKey('placeSearch.result.p-westlands'), findsOneWidget);
    });

    testWidgets(
      'session token is shared by searches and details, then dropped',
      (tester) async {
        final h = await openNewOrder(tester, ServiceType.ride);
        await tapKeyAndSettle(tester, 'route.pickup');
        await tester.enterText(byKey('placeSearch.input'), 'We');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
        await tester.enterText(byKey('placeSearch.input'), 'West');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
        await tester.tap(byKey('placeSearch.result.p-westlands'));
        await tester.pumpAndSettle();

        final tokens = h.repo.autocompleteCalls.map((c) => c.token).toSet();
        expect(tokens, hasLength(1));
        expect(h.repo.detailsCalls.single.token, tokens.single);
        expect(find.text(westlands.label), findsOneWidget);

        await pickPlace(tester, 'route.dropoff', 'Moi', 'p-cbd');
        expect(
          h.repo.autocompleteCalls.last.token,
          isNot(tokens.single),
          reason: 'a new search session gets a new token',
        );
      },
    );

    testWidgets('search uses the last known location as bias', (tester) async {
      final h = await openNewOrder(tester, ServiceType.ride);
      await pickPlace(tester, 'route.pickup', 'West', 'p-westlands');
      expect(h.repo.autocompleteCalls.single.near, isNotNull);
    });

    testWidgets('503 shows the location-search-unavailable state', (
      tester,
    ) async {
      final repo = FakeBookingRepository()
        ..autocompleteError = const MapsUnavailableException();
      await openNewOrder(tester, ServiceType.ride, repo: repo);
      await tapKeyAndSettle(tester, 'route.pickup');
      await tester.enterText(byKey('placeSearch.input'), 'West');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(byKey('placeSearch.unavailable'), findsOneWidget);
      expect(
        find.text('Location search is unavailable right now. Try again later.'),
        findsOneWidget,
      );
    });

    testWidgets('network failure shows retry; no results shows empty', (
      tester,
    ) async {
      final repo = FakeBookingRepository()
        ..autocompleteError = const ApiException(message: 'offline');
      await openNewOrder(tester, ServiceType.ride, repo: repo);
      await tapKeyAndSettle(tester, 'route.pickup');
      await tester.enterText(byKey('placeSearch.input'), 'West');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(byKey('placeSearch.failed'), findsOneWidget);

      repo.autocompleteError = null;
      await tester.enterText(byKey('placeSearch.input'), 'Zzz');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('No places found'), findsOneWidget);
    });
  });

  group('new delivery (screen 4)', () {
    testWidgets('empty submit shows every required-field error', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final h = await openNewOrder(tester, ServiceType.delivery);
      await tapKeyAndSettle(tester, 'order.submit');
      expect(find.text('Choose a pickup point'), findsOneWidget);
      expect(find.text('Choose a drop-off point'), findsOneWidget);
      expect(find.text("Enter the receiver's name"), findsOneWidget);
      expect(find.text('Choose a category'), findsOneWidget);
      expect(find.text('Describe the item'), findsOneWidget);
      expect(byKey('order.valueBand.error'), findsOneWidget);
      expect(h.repo.createCalls, isEmpty);
    });

    testWidgets('no phone field; prohibited categories are not offered', (
      tester,
    ) async {
      await openNewOrder(tester, ServiceType.delivery);
      expect(find.textContaining('Phone'), findsNothing);
      await tapKeyAndSettle(tester, 'order.category');
      expect(find.text('Documents'), findsWidgets);
      expect(find.text('Weapons'), findsNothing);
    });

    testWidgets('invalid weight blocks submit', (tester) async {
      final h = await openNewOrder(tester, ServiceType.delivery);
      await tester.enterText(byKey('order.weight'), '0');
      await tapKeyAndSettle(tester, 'order.submit');
      expect(find.text('Enter a weight above 0'), findsOneWidget);
      expect(h.repo.createCalls, isEmpty);
    });

    testWidgets('valid delivery creates the order and opens the rider list', (
      tester,
    ) async {
      final h = await openNewOrder(tester, ServiceType.delivery);
      await pickPlace(tester, 'route.pickup', 'West', 'p-westlands');
      await pickPlace(tester, 'route.dropoff', 'Moi', 'p-cbd');
      await tester.enterText(byKey('order.receiver'), ' Grace Wanjiku ');
      await tapKeyAndSettle(tester, 'order.category');
      await tester.tap(find.text('Documents').last);
      await tester.pumpAndSettle();
      await tester.enterText(byKey('order.description'), 'Sealed envelope');
      await tester.enterText(byKey('order.weight'), '0.5');
      await tapKeyAndSettle(tester, 'order.valueBand.2000_to_5000');
      await tapKeyAndSettle(tester, 'order.submit');
      expect(h.repo.createCalls, isEmpty);
      await tapKeyAndSettle(tester, 'confirmPickup.confirm');

      final input = h.repo.createCalls.single;
      expect(input.serviceType, ServiceType.delivery);
      expect(input.receiverName, 'Grace Wanjiku');
      expect(input.declaration!.categoryId, 'cat-docs');
      expect(input.declaration!.weightKg, 0.5);
      expect(input.declaration!.valueBand, ValueBand.from2000To5000);
      expect(input.route.pickup.placeId, 'p-westlands');
      expect(byKey('screen.riderList'), findsOneWidget);
    });

    testWidgets('server failure shows an error and stays on the form', (
      tester,
    ) async {
      final repo = FakeBookingRepository()
        ..createError = const ApiException(statusCode: 500, message: 'x');
      await openNewOrder(tester, ServiceType.ride, repo: repo);
      await pickPlace(tester, 'route.pickup', 'West', 'p-westlands');
      await pickPlace(tester, 'route.dropoff', 'Moi', 'p-cbd');
      await tapKeyAndSettle(tester, 'order.submit');
      await tapKeyAndSettle(tester, 'confirmPickup.confirm');
      expect(byKey('order.error'), findsOneWidget);
      expect(byKey('screen.newOrder'), findsOneWidget);
    });

    testWidgets('categories failure shows retry', (tester) async {
      final repo = FakeBookingRepository()
        ..categoriesError = const ApiException(message: 'offline');
      await openNewOrder(tester, ServiceType.delivery, repo: repo);
      expect(byKey('order.categoriesError'), findsOneWidget);
      repo.categoriesError = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(byKey('order.category'), findsOneWidget);
    });
  });

  group('new ride (screen 4)', () {
    testWidgets('has no receiver or item fields and sends only the route', (
      tester,
    ) async {
      final h = await openNewOrder(tester, ServiceType.ride);
      expect(byKey('order.receiver'), findsNothing);
      expect(byKey('order.category'), findsNothing);
      await pickPlace(tester, 'route.pickup', 'West', 'p-westlands');
      await pickPlace(tester, 'route.dropoff', 'Moi', 'p-cbd');
      await tapKeyAndSettle(tester, 'order.submit');
      await tapKeyAndSettle(tester, 'confirmPickup.confirm');
      final input = h.repo.createCalls.single;
      expect(input.serviceType, ServiceType.ride);
      expect(input.receiverName, isNull);
      expect(input.declaration, isNull);
      expect(byKey('screen.riderList'), findsOneWidget);
    });
  });
}
