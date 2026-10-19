import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridelink/core/api/api_exception.dart';
import 'package:ridelink/core/auth/session.dart';
import 'package:ridelink/core/location/geo_point.dart';
import 'package:ridelink/core/location/location_service.dart';

import '../../support/booking_fakes.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Finder byKey(String k) => find.byKey(Key(k));

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(byKey('menu.open'));
    await tester.pumpAndSettle();
  }

  group('menu mode switch', () {
    testWidgets(
      'registered rider sees "Switch to riding" and can switch back',
      (tester) async {
        final h = await pumpBookingApp(
          tester,
          account: FakeAccountRepository(rider: true),
        );
        await openMenu(tester);
        expect(byKey('menu.switchToRiding'), findsOneWidget);
        expect(byKey('menu.becomeRider'), findsNothing);

        await tester.tap(byKey('menu.switchToRiding'));
        await tester.pumpAndSettle();
        expect(byKey('screen.riderHome'), findsOneWidget);

        await tester.tap(find.byTooltip('Open navigation menu'));
        await tester.pumpAndSettle();
        await tester.tap(byKey('menu.switchToSending'));
        await tester.pumpAndSettle();
        expect(byKey('screen.home'), findsOneWidget);
        expect(h.account.calls, 1);
      },
    );

    testWidgets('404 shows "Become a rider" which opens rider onboarding', (
      tester,
    ) async {
      await pumpBookingApp(
        tester,
        account: FakeAccountRepository(),
        riderRepo: FakeRiderRepository(registered: false),
      );
      await openMenu(tester);
      expect(byKey('menu.switchToRiding'), findsNothing);
      await tester.tap(byKey('menu.becomeRider'));
      await tester.pumpAndSettle();
      expect(byKey('screen.riderOnboarding'), findsOneWidget);
    });

    testWidgets('rider check failure shows retry, which re-checks', (
      tester,
    ) async {
      final account = FakeAccountRepository(
        error: const ApiException(message: 'offline'),
      );
      await pumpBookingApp(tester, account: account);
      await openMenu(tester);
      expect(byKey('menu.riderStatusError'), findsOneWidget);

      account
        ..error = null
        ..rider = true;
      await tester.tap(byKey('menu.riderStatusError'));
      await tester.pumpAndSettle();
      expect(byKey('menu.switchToRiding'), findsOneWidget);
      expect(account.calls, 2);
    });

    testWidgets('sign out ends the session and returns to sign in', (
      tester,
    ) async {
      final h = await pumpBookingApp(tester);
      await openMenu(tester);
      await tester.tap(byKey('menu.signOut'));
      await tester.pumpAndSettle();
      expect(h.session.state, isA<SignedOut>());
      expect(byKey('screen.home'), findsNothing);
    });
  });

  group('sender home (screen 2)', () {
    testWidgets('no Maps key renders the placeholder; services offered', (
      tester,
    ) async {
      final h = await pumpBookingApp(tester);
      expect(byKey('home.mapPlaceholder'), findsOneWidget);
      expect(byKey('home.service.delivery'), findsOneWidget);
      expect(byKey('home.service.ride'), findsOneWidget);
      expect(find.text('Errand'), findsNothing);
      expect(byKey('home.location.denied'), findsNothing);
      expect(h.location.requests, 1);
    });

    testWidgets('choosing a service opens the new order screen', (
      tester,
    ) async {
      await pumpBookingApp(tester);
      await tester.tap(byKey('home.service.ride'));
      await tester.pumpAndSettle();
      expect(byKey('screen.newOrder'), findsOneWidget);
      expect(find.text('New ride'), findsOneWidget);
    });

    testWidgets('denied permission shows a card; Allow asks again', (
      tester,
    ) async {
      final location = FakeLocationService(
        initial: const LocationDenied(),
        afterRequest: const LocationFound(GeoPoint(-1.26, 36.8)),
      );
      await pumpBookingApp(tester, location: location);
      expect(byKey('home.location.denied'), findsOneWidget);

      await tester.tap(byKey('home.location.action'));
      await tester.pumpAndSettle();
      expect(location.requests, 2);
      expect(byKey('home.location.denied'), findsNothing);
    });

    testWidgets('permanently denied offers app settings', (tester) async {
      final location = FakeLocationService(
        initial: const LocationDeniedForever(),
      );
      await pumpBookingApp(tester, location: location);
      expect(byKey('home.location.deniedForever'), findsOneWidget);
      await tester.tap(byKey('home.location.action'));
      await tester.pumpAndSettle();
      expect(location.appSettingsOpened, 1);
    });

    testWidgets('location services off offers device settings', (tester) async {
      final location = FakeLocationService(initial: const LocationServiceOff());
      await pumpBookingApp(tester, location: location);
      expect(byKey('home.location.serviceOff'), findsOneWidget);
      await tester.tap(byKey('home.location.action'));
      await tester.pumpAndSettle();
      expect(location.locationSettingsOpened, 1);
    });
  });
}
