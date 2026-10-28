import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridelink/core/routing/app_router.dart';
import 'package:ridelink/features/profile/public/public_profile_models.dart';

import '../../support/booking_fakes.dart';
import '../../support/public_profile_fakes.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Finder byKey(String k) => find.byKey(Key(k));

  Future<BookingHarness> openMine(
    WidgetTester tester, {
    bool rider = true,
    FakePublicProfileRepository? profiles,
  }) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final h = await pumpBookingApp(
      tester,
      account: FakeAccountRepository()..rider = rider,
      riderRepo: FakeRiderRepository(registered: rider),
      publicProfiles: profiles,
      goTo: AppRoutes.profile,
    );
    expect(find.text('Your public profile'), findsOneWidget);
    await tapKeyAndSettle(tester, 'profile.publicProfile');
    return h;
  }

  testWidgets('Profile tab shows Your public profile; sender view by default', (
    tester,
  ) async {
    final h = await openMine(tester, rider: false);
    expect(byKey('screen.myPublicProfile'), findsOneWidget);
    expect(h.publicProfiles.mineCalls, [PublicProfileRole.sender]);
    expect(find.text('This is what riders see about you'), findsOneWidget);
    expect(find.text('Orders (all time)'), findsOneWidget);
  });

  testWidgets('sender-only user sees no rider option', (tester) async {
    await openMine(tester, rider: false);
    expect(byKey('myPublicProfile.role'), findsNothing);
    expect(byKey('myPublicProfile.role.rider'), findsNothing);
  });

  testWidgets('both roles: switch to the rider view', (tester) async {
    final h = await openMine(tester);
    expect(byKey('myPublicProfile.role'), findsOneWidget);
    await tapKeyAndSettle(tester, 'myPublicProfile.role.rider');
    expect(h.publicProfiles.mineCalls.last, PublicProfileRole.rider);
    expect(find.text('This is what senders see about you'), findsOneWidget);
    expect(find.text('Trips (all time)'), findsOneWidget);
    expect(find.text('Verified rider'), findsOneWidget);

    await tapKeyAndSettle(tester, 'myPublicProfile.role.sender');
    expect(find.text('This is what riders see about you'), findsOneWidget);
  });

  testWidgets('rider view 404 hides the rider option', (tester) async {
    final profiles = FakePublicProfileRepository(
      mineByRole: {PublicProfileRole.sender: senderProfileFixture()},
    );
    await openMine(tester, profiles: profiles);
    await tapKeyAndSettle(tester, 'myPublicProfile.role.rider');
    expect(byKey('myPublicProfile.role'), findsNothing);
    expect(find.text('This is what riders see about you'), findsOneWidget);
  });

  testWidgets('role switch segments are at least 44 dp', (tester) async {
    await openMine(tester);
    for (final k in [
      'myPublicProfile.role.sender',
      'myPublicProfile.role.rider',
    ]) {
      final size = tester.getSize(byKey(k));
      expect(size.height, greaterThanOrEqualTo(44));
      expect(size.width, greaterThanOrEqualTo(44));
    }
  });
}
