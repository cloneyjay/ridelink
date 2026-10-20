import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridelink/core/api/api_exception.dart';
import 'package:ridelink/core/location/geo_point.dart';
import 'package:ridelink/core/location/location_service.dart';
import 'package:ridelink/core/routing/app_router.dart';
import 'package:ridelink/features/booking/booking_routes.dart';
import 'package:ridelink/features/booking/confirm_pickup_screen.dart';
import 'package:ridelink/features/booking/data/booking_models.dart';
import 'package:ridelink/features/booking/data/booking_repository.dart';
import 'package:ridelink/features/booking/default_pickup.dart';

import '../../support/booking_fakes.dart';

const gps = GeoPoint(-1.2701, 36.8102);

const gpsPlace = Place(
  placeId: 'r-gps',
  name: 'Ring Road',
  address: 'Kilimani, Nairobi',
  location: gps,
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Finder byKey(String k) => find.byKey(Key(k));

  FakeLocationService located({double? accuracy = 20}) =>
      FakeLocationService(initial: LocationFound(gps, accuracyM: accuracy));

  FakeBookingRepository reversing() =>
      FakeBookingRepository()..onReverse = (_) => gpsPlace;

  Future<BookingHarness> open(
    WidgetTester tester,
    ServiceType service, {
    FakeBookingRepository? repo,
    FakeLocationService? location,
    bool settle = true,
  }) => pumpBookingApp(
    tester,
    repo: repo ?? reversing(),
    location: location ?? located(),
    goTo: AppRoutes.newOrderFor(service),
    settle: settle,
  );

  Future<void> pick(
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

  group('default pickup', () {
    testWidgets('uses the current location with its reverse-geocoded label', (
      tester,
    ) async {
      final h = await open(tester, ServiceType.ride);
      expect(find.text(gpsPlace.label), findsOneWidget);
      expect(byKey('route.pickup.change'), findsOneWidget);
      final call = h.repo.reverseCalls.single;
      expect(call.point, gps);
      expect(call.language, 'en');
    });

    testWidgets('delivery gets the same default', (tester) async {
      await open(tester, ServiceType.delivery);
      expect(find.text(gpsPlace.label), findsOneWidget);
    });

    for (final (name, error) in [
      ('503', const MapsUnavailableException() as Object),
      ('network error', const ApiException(message: 'offline')),
    ]) {
      testWidgets('$name falls back to "Current location" at the GPS point', (
        tester,
      ) async {
        final repo = FakeBookingRepository()..reverseError = error;
        final h = await open(tester, ServiceType.ride, repo: repo);
        expect(find.text('Current location'), findsOneWidget);
        await pick(tester, 'route.dropoff', 'Moi', 'p-cbd');
        await tapKeyAndSettle(tester, 'order.submit');
        await tapKeyAndSettle(tester, 'confirmPickup.confirm');
        final route = h.repo.createCalls.single.route;
        expect(route.pickup.label, 'Current location');
        expect(route.pickup.location, gps);
        expect(
          route.toJson()['pickup_address'],
          '-1.27010, 36.81020',
          reason: 'no localized label is stored on the order',
        );
      });
    }

    testWidgets('404 falls back to "Current location"', (tester) async {
      final repo = FakeBookingRepository()..onReverse = (_) => null;
      await open(tester, ServiceType.ride, repo: repo);
      expect(find.text('Current location'), findsOneWidget);
      expect(byKey('route.pickup.change'), findsOneWidget);
    });

    testWidgets('no permission leaves the pickup empty without a dialog', (
      tester,
    ) async {
      final h = await open(
        tester,
        ServiceType.ride,
        location: FakeLocationService(initial: const LocationDenied()),
      );
      expect(find.text('Choose pickup'), findsOneWidget);
      expect(byKey('route.pickup.change'), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(h.repo.reverseCalls, isEmpty);
    });

    testWidgets('location off leaves the pickup empty', (tester) async {
      final h = await open(
        tester,
        ServiceType.delivery,
        location: FakeLocationService(initial: const LocationServiceOff()),
      );
      expect(find.text('Choose pickup'), findsOneWidget);
      expect(h.repo.reverseCalls, isEmpty);
    });

    testWidgets('accuracy worse than 100 m leaves the pickup empty', (
      tester,
    ) async {
      final h = await open(
        tester,
        ServiceType.ride,
        location: located(accuracy: 150),
      );
      expect(find.text('Choose pickup'), findsOneWidget);
      expect(h.repo.reverseCalls, isEmpty);
    });

    testWidgets('shows a locating state and the drop-off stays usable', (
      tester,
    ) async {
      final repo = reversing()..reverseGate = Completer<void>();
      await open(tester, ServiceType.ride, repo: repo, settle: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(byKey('route.pickup.locating'), findsOneWidget);
      expect(find.text('Finding your location'), findsOneWidget);
      await tester.tap(byKey('route.dropoff'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(byKey('screen.placeSearch'), findsOneWidget);

      repo.reverseGate!.complete();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text(gpsPlace.label), findsOneWidget);
      expect(byKey('route.pickup.locating'), findsNothing);
    });

    testWidgets('a pickup chosen while locating is not overwritten', (
      tester,
    ) async {
      final repo = reversing()..reverseGate = Completer<void>();
      await open(tester, ServiceType.ride, repo: repo, settle: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(byKey('route.pickup'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.enterText(byKey('placeSearch.input'), 'West');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.tap(byKey('placeSearch.result.p-westlands'));
      await tester.pumpAndSettle();
      repo.reverseGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text(westlands.label), findsOneWidget);
      expect(find.text(gpsPlace.label), findsNothing);
    });
  });

  group('pickup confirmation', () {
    testWidgets('Continue opens Confirm pickup, confirming creates the order', (
      tester,
    ) async {
      final h = await open(tester, ServiceType.ride);
      await pick(tester, 'route.dropoff', 'Moi', 'p-cbd');
      await tapKeyAndSettle(tester, 'order.submit');
      expect(byKey('screen.confirmPickup'), findsOneWidget);
      expect(find.text(gpsPlace.label), findsOneWidget);
      expect(h.repo.createCalls, isEmpty);

      await tapKeyAndSettle(tester, 'confirmPickup.confirm');
      expect(h.repo.createCalls.single.route.pickup.label, gpsPlace.label);
      expect(byKey('screen.riderList'), findsOneWidget);
    });

    testWidgets('backing out of Confirm pickup creates nothing', (
      tester,
    ) async {
      final h = await open(tester, ServiceType.ride);
      await pick(tester, 'route.dropoff', 'Moi', 'p-cbd');
      await tapKeyAndSettle(tester, 'order.submit');
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(byKey('screen.newOrder'), findsOneWidget);
      expect(h.repo.createCalls, isEmpty);
    });

    testWidgets('a confirmed pickup skips the confirm screen', (tester) async {
      final repo = reversing()
        ..createError = const ApiException(statusCode: 500, message: 'x');
      final h = await open(tester, ServiceType.ride, repo: repo);
      await pick(tester, 'route.dropoff', 'Moi', 'p-cbd');
      await tapKeyAndSettle(tester, 'order.submit');
      await tapKeyAndSettle(tester, 'confirmPickup.confirm');
      expect(byKey('order.error'), findsOneWidget);

      await tapKeyAndSettle(tester, 'order.submit');
      expect(byKey('screen.confirmPickup'), findsNothing);
      expect(h.repo.createCalls, hasLength(2));
    });

    testWidgets('changing a confirmed pickup needs confirming again', (
      tester,
    ) async {
      final repo = reversing()
        ..createError = const ApiException(statusCode: 500, message: 'x');
      final h = await open(tester, ServiceType.ride, repo: repo);
      await pick(tester, 'route.dropoff', 'Moi', 'p-cbd');
      await tapKeyAndSettle(tester, 'order.submit');
      await tapKeyAndSettle(tester, 'confirmPickup.confirm');

      await pick(tester, 'route.pickup.change', 'West', 'p-westlands');
      await tapKeyAndSettle(tester, 'order.submit');
      expect(byKey('screen.confirmPickup'), findsOneWidget);
      expect(find.text(westlands.label), findsOneWidget);
      await tapKeyAndSettle(tester, 'confirmPickup.confirm');
      expect(h.repo.createCalls.last.route.pickup.placeId, 'p-westlands');
    });

    testWidgets('a searched pickup must be confirmed too', (tester) async {
      final h = await open(
        tester,
        ServiceType.ride,
        location: FakeLocationService(initial: const LocationDenied()),
      );
      await pick(tester, 'route.pickup', 'West', 'p-westlands');
      await pick(tester, 'route.dropoff', 'Moi', 'p-cbd');
      await tapKeyAndSettle(tester, 'order.submit');
      expect(byKey('screen.confirmPickup'), findsOneWidget);
      expect(h.repo.createCalls, isEmpty);
    });

    testWidgets('Search instead returns to Confirm pickup re-centred', (
      tester,
    ) async {
      final h = await open(tester, ServiceType.ride);
      await pick(tester, 'route.dropoff', 'Moi', 'p-cbd');
      await tapKeyAndSettle(tester, 'order.submit');
      await pick(tester, 'confirmPickup.search', 'West', 'p-westlands');

      expect(byKey('screen.confirmPickup'), findsOneWidget);
      expect(find.text(westlands.label), findsOneWidget);
      expect(h.repo.createCalls, isEmpty, reason: 'still needs confirming');
      await tapKeyAndSettle(tester, 'confirmPickup.confirm');
      final pickup = h.repo.createCalls.single.route.pickup;
      expect(pickup.placeId, 'p-westlands');
      expect(pickup.location, westlands.location);
    });

    testWidgets('ride copy; no map key shows the placeholder, no helper', (
      tester,
    ) async {
      await open(tester, ServiceType.ride);
      await pick(tester, 'route.dropoff', 'Moi', 'p-cbd');
      await tapKeyAndSettle(tester, 'order.submit');
      expect(find.text('Confirm your pickup spot'), findsOneWidget);
      expect(
        find.text('Confirm where the rider collects the item'),
        findsNothing,
      );
      expect(byKey('home.mapPlaceholder'), findsOneWidget);
      expect(byKey('confirmPickup.helper'), findsNothing);
      expect(byKey('confirmPickup.pin'), findsNothing);
    });

    testWidgets('delivery copy', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await open(tester, ServiceType.delivery);
      await pick(tester, 'route.dropoff', 'Moi', 'p-cbd');
      await tester.enterText(byKey('order.receiver'), 'Grace');
      await tapKeyAndSettle(tester, 'order.category');
      await tester.tap(find.text('Documents').last);
      await tester.pumpAndSettle();
      await tester.enterText(byKey('order.description'), 'Envelope');
      await tapKeyAndSettle(tester, 'order.valueBand.under_500');
      await tapKeyAndSettle(tester, 'order.submit');
      expect(
        find.text('Confirm where the rider collects the item'),
        findsOneWidget,
      );
      expect(find.text('Confirm your pickup spot'), findsNothing);
    });

    testWidgets('panning reverse-geocodes the pin centre, debounced', (
      tester,
    ) async {
      final repo = reversing();
      final h = await open(tester, ServiceType.ride, repo: repo);
      await pick(tester, 'route.dropoff', 'Moi', 'p-cbd');
      await tapKeyAndSettle(tester, 'order.submit');
      final state = tester.state<ConfirmPickupScreenState>(
        find.byType(ConfirmPickupScreen),
      );
      repo.reverseCalls.clear();
      const moved = GeoPoint(-1.2711, 36.8111);
      const moved2 = GeoPoint(-1.2721, 36.8121);
      repo.onReverse = (p) => Place(
        placeId: 'r-pan',
        name: 'Argwings Kodhek Road',
        address: '',
        location: p,
      );

      state.handleCameraIdle(moved);
      await tester.pump(const Duration(milliseconds: 100));
      state.handleCameraIdle(moved2);
      await tester.pump();
      expect(byKey('confirmPickup.resolving'), findsOneWidget);
      expect(
        find.text(gpsPlace.label),
        findsOneWidget,
        reason: 'last good label stays while loading',
      );
      await tester.pump(ConfirmPickupScreen.debounce);
      await tester.pumpAndSettle();
      expect(repo.reverseCalls.map((c) => c.point), [moved2]);
      expect(find.text('Argwings Kodhek Road'), findsOneWidget);

      repo.onReverse = (_) => null;
      state.handleCameraIdle(moved);
      await tester.pump(ConfirmPickupScreen.debounce);
      await tester.pumpAndSettle();
      expect(find.text('Pinned location'), findsOneWidget);

      await tapKeyAndSettle(tester, 'confirmPickup.confirm');
      final route = h.repo.createCalls.single.route;
      expect(route.pickup.location, moved);
      expect(route.pickup.label, 'Pinned location');
      expect(route.toJson()['pickup_address'], coordinateText(moved));
    });
  });

  group('reverse lookup timeout', () {
    testWidgets('a hanging lookup falls back after 5 s', (tester) async {
      final repo = reversing()..reverseGate = Completer<void>();
      await open(tester, ServiceType.ride, repo: repo, settle: false);
      await tester.pump();
      await tester.pump(reverseLookupTimeout);
      await tester.pumpAndSettle();
      expect(find.text('Current location'), findsOneWidget);
      expect(byKey('route.pickup.locating'), findsNothing);
    });

    testWidgets('Confirm pickup re-enables with "Pinned location"', (
      tester,
    ) async {
      final repo = reversing();
      await open(tester, ServiceType.ride, repo: repo);
      await pick(tester, 'route.dropoff', 'Moi', 'p-cbd');
      await tapKeyAndSettle(tester, 'order.submit');
      final state = tester.state<ConfirmPickupScreenState>(
        find.byType(ConfirmPickupScreen),
      );
      repo.reverseGate = Completer<void>();
      state.handleCameraIdle(const GeoPoint(-1.2711, 36.8111));
      await tester.pump(ConfirmPickupScreen.debounce);
      await tester.pump(const Duration(seconds: 1));
      expect(byKey('confirmPickup.resolving'), findsOneWidget);
      await tester.pump(reverseLookupTimeout);
      await tester.pumpAndSettle();
      expect(byKey('confirmPickup.resolving'), findsNothing);
      expect(find.text('Pinned location'), findsOneWidget);
    });
  });

  group('order address', () {
    test('real addresses are stored as-is, pins as coordinates', () {
      const pin = Place(
        placeId: '',
        name: '',
        address: '',
        location: GeoPoint(-1.286364, 36.8172),
        localLabel: 'Current location',
      );
      expect(pin.label, 'Current location');
      expect(pin.orderAddress, '-1.28636, 36.81720');
      final json = const RouteInput(pickup: pin, dropoff: cbd).toJson();
      expect(json['pickup_address'], '-1.28636, 36.81720');
      expect(json['dropoff_address'], cbd.label);
    });
  });

  group('edit route', () {
    testWidgets('a changed pickup is confirmed before saving', (tester) async {
      final h = await pumpBookingApp(
        tester,
        goTo: AppRoutes.ridersFor('order-1'),
        extra: RiderListArgs(order: orderFixture()),
      );
      await tapKeyAndSettle(tester, 'riders.editRoute');
      await pick(tester, 'route.pickup', 'Moi', 'p-cbd');
      await tapKeyAndSettle(tester, 'editRoute.save');
      expect(byKey('screen.confirmPickup'), findsOneWidget);
      expect(
        find.text('Confirm where the rider collects the item'),
        findsOneWidget,
      );
      expect(h.repo.routeCalls, isEmpty);
      await tapKeyAndSettle(tester, 'confirmPickup.confirm');
      expect(h.repo.routeCalls.single.pickup.placeId, 'p-cbd');
    });
  });

  group('pickupFix', () {
    final now = DateTime(2026, 10, 20, 9);

    test('reuses a fresh, accurate cached fix without reading', () async {
      final service = FakeLocationService();
      final fix = await pickupFix(
        cached: LocationFix(point: gps, accuracyM: 30, at: now),
        service: service,
        now: now.add(const Duration(minutes: 1)),
        onFresh: (_) => fail('no new read expected'),
      );
      expect(fix!.point, gps);
      expect(service.reads, 0);
    });

    test('re-reads a stale fix and caches the new one', () async {
      final service = FakeLocationService(
        initial: const LocationFound(GeoPoint(-1.3, 36.9), accuracyM: 12),
      );
      LocationFix? cached;
      final fix = await pickupFix(
        cached: LocationFix(point: gps, accuracyM: 30, at: now),
        service: service,
        now: now.add(const Duration(minutes: 3)),
        onFresh: (f) => cached = f,
      );
      expect(fix!.point, const GeoPoint(-1.3, 36.9));
      expect(cached!.accuracyM, 12);
      expect(service.reads, 1);
    });

    test('unknown accuracy is not accepted', () async {
      final fix = await pickupFix(
        cached: null,
        service: FakeLocationService(initial: const LocationFound(gps)),
        now: now,
        onFresh: (_) {},
      );
      expect(fix, isNull);
    });
  });
}
