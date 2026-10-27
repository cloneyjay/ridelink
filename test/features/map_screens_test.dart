import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridelink/core/location/geo_point.dart';
import 'package:ridelink/core/location/location_service.dart';
import 'package:ridelink/core/routing/app_router.dart';
import 'package:ridelink/features/booking/data/booking_models.dart';
import 'package:ridelink/features/tracking/tracking_screen.dart';
import 'package:ridelink/theme/app_colors.dart';
import 'package:ridelink/theme/app_theme.dart';

import '../support/booking_fakes.dart';
import '../support/map_fakes.dart';

const _gps = GeoPoint(-1.2701, 36.8102);
const _gpsPlace = Place(
  placeId: 'r-gps',
  name: 'Ring Road',
  address: 'Kilimani, Nairobi',
  location: _gps,
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Finder byKey(String k) => find.byKey(Key(k));
  AppColors colors() => AppTheme.light.extension<AppColors>()!;
  const attribution =
      '© OpenFreeMap © OpenMapTiles © OpenStreetMap contributors';

  group('tracking map (screen 7)', () {
    testWidgets('pickup and drop-off markers; rider follows live updates', (
      tester,
    ) async {
      final engine = FakeMapEngine();
      final order = jobFixture();
      final h = await pumpBookingApp(
        tester,
        repo: FakeBookingRepository()..order = order,
        clock: () => testNow,
        goTo: AppRoutes.trackingFor(order.id),
        extra: TrackingArgs(
          riderId: 'rider-1',
          riderName: 'Moses O.',
          breakdown: riderFixture().breakdown,
        ),
        mapEngine: engine,
      );
      expect(byKey('tracking.map'), findsOneWidget);
      expect(find.text(attribution), findsOneWidget);
      expect(engine.marker('pickup')!.point, order.pickupLocation);
      expect(engine.marker('pickup')!.fill, colors().forest500);
      expect(engine.marker('dropoff')!.point, order.dropoffLocation);
      expect(engine.marker('dropoff')!.fill, colors().brand500);
      expect(engine.marker('rider'), isNull);

      h.emit('rider.location', {
        'order_id': order.id,
        'rider_id': 'rider-1',
        'lat': -1.27,
        'lng': 36.81,
      });
      await tester.pumpAndSettle();
      expect(engine.marker('rider')!.point, const GeoPoint(-1.27, 36.81));
      expect(engine.marker('rider')!.fill, colors().ride500);

      h.emit('rider.location', {
        'order_id': order.id,
        'rider_id': 'rider-1',
        'lat': -1.275,
        'lng': 36.815,
      });
      await tester.pumpAndSettle();
      expect(engine.marker('rider')!.point, const GeoPoint(-1.275, 36.815));
      expect(engine.markers.where((m) => m.id == 'rider'), hasLength(1));
    });
  });

  group('confirm pickup map', () {
    Future<BookingHarness> openConfirm(
      WidgetTester tester,
      FakeMapEngine engine,
      FakeBookingRepository repo,
    ) async {
      final h = await pumpBookingApp(
        tester,
        repo: repo,
        location: FakeLocationService(
          initial: const LocationFound(_gps, accuracyM: 20),
        ),
        goTo: AppRoutes.newOrderFor(ServiceType.ride),
        mapEngine: engine,
      );
      await tapKeyAndSettle(tester, 'route.dropoff');
      await tester.enterText(byKey('placeSearch.input'), 'Moi');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      await tester.tap(byKey('placeSearch.result.p-cbd'));
      await tester.pumpAndSettle();
      await tapKeyAndSettle(tester, 'order.submit');
      return h;
    }

    testWidgets('pin and helper over the map; panning moves the pickup', (
      tester,
    ) async {
      final engine = FakeMapEngine();
      final repo = FakeBookingRepository()..onReverse = (_) => _gpsPlace;
      final h = await openConfirm(tester, engine, repo);
      expect(byKey('confirmPickup.map'), findsOneWidget);
      expect(byKey('confirmPickup.pin'), findsOneWidget);
      expect(byKey('confirmPickup.helper'), findsOneWidget);
      expect(find.text(attribution), findsOneWidget);
      expect(engine.spec!.initialCenter, _gps);
      expect(engine.spec!.initialZoom, 17);

      // Coming to rest where it started is not a move.
      repo.reverseCalls.clear();
      engine.settleAt(_gps);
      await tester.pumpAndSettle();
      expect(repo.reverseCalls, isEmpty);

      const moved = GeoPoint(-1.2711, 36.8111);
      repo.onReverse = (p) => Place(
        placeId: 'r-pan',
        name: 'Argwings Kodhek Road',
        address: '',
        location: p,
      );
      engine.settleAt(moved);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(repo.reverseCalls.map((c) => c.point), [moved]);
      expect(find.text('Argwings Kodhek Road'), findsOneWidget);

      await tapKeyAndSettle(tester, 'confirmPickup.confirm');
      expect(h.repo.createCalls.single.route.pickup.location, moved);
    });

    testWidgets('Search instead moves the map to the chosen place', (
      tester,
    ) async {
      final engine = FakeMapEngine();
      final repo = FakeBookingRepository()..onReverse = (_) => _gpsPlace;
      await openConfirm(tester, engine, repo);
      await tapKeyAndSettle(tester, 'confirmPickup.search');
      await tester.enterText(byKey('placeSearch.input'), 'Westlands');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      await tester.tap(byKey('placeSearch.result.p-westlands'));
      await tester.pumpAndSettle();
      expect(engine.controller.moves.last.center, westlands.location);
      expect(engine.controller.moves.last.zoom, isNull);
    });
  });

  group('sender home map (screen 2)', () {
    testWidgets('centres on the sender and shows their location dot', (
      tester,
    ) async {
      final engine = FakeMapEngine();
      await pumpBookingApp(
        tester,
        location: FakeLocationService(initial: const LocationFound(_gps)),
        mapEngine: engine,
      );
      expect(byKey('home.map'), findsOneWidget);
      expect(byKey('home.mapPlaceholder'), findsNothing);
      expect(find.text(attribution), findsOneWidget);
      expect(engine.spec!.showMyLocation, isTrue);
      expect(engine.controller.moves.last, (center: _gps, zoom: 15.0));
    });

    testWidgets('no location: Nairobi overview without the location dot', (
      tester,
    ) async {
      final engine = FakeMapEngine();
      await pumpBookingApp(
        tester,
        location: FakeLocationService(initial: const LocationDenied()),
        mapEngine: engine,
      );
      expect(engine.spec!.showMyLocation, isFalse);
      expect(engine.spec!.initialZoom, 12);
      expect(engine.controller.moves, isEmpty);
    });
  });

  group('place search credit', () {
    testWidgets('"Powered by Geoapify" shows with results only', (
      tester,
    ) async {
      await pumpBookingApp(
        tester,
        goTo: AppRoutes.newOrderFor(ServiceType.ride),
      );
      await tapKeyAndSettle(tester, 'route.dropoff');
      expect(byKey('placeSearch.poweredBy'), findsNothing);
      await tester.enterText(byKey('placeSearch.input'), 'Moi');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('Powered by Geoapify'), findsOneWidget);
    });
  });
}
