import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridelink/core/auth/session.dart';
import 'package:ridelink/core/routing/app_router.dart';
import 'package:ridelink/features/rider/data/rider_models.dart';

import '../../support/booking_fakes.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Finder byKey(String k) => find.byKey(Key(k));

  bool fieldEnabled(WidgetTester tester, String key) =>
      tester
          .widget<TextField>(
            find.descendant(of: byKey(key), matching: find.byType(TextField)),
          )
          .enabled ??
      true;

  testWidgets(
    'reachable from the menu; shows names, read-only email, language',
    (tester) async {
      await pumpBookingApp(
        tester,
        riderRepo: FakeRiderRepository(registered: false),
      );
      await tester.tap(byKey('menu.open'));
      await tester.pumpAndSettle();
      await tapKeyAndSettle(tester, 'menu.profile');
      final l = l10nOf(tester);
      expect(byKey('screen.profile'), findsOneWidget);
      expect(find.text('Moses'), findsOneWidget);
      expect(find.text('Otieno'), findsOneWidget);
      expect(find.text('moses@example.com'), findsOneWidget);
      expect(
        find.byType(TextField),
        findsNWidgets(2),
        reason: 'email is not a field',
      );
      expect(find.text(l.profileLanguageValue), findsOneWidget);
      expect(byKey('profile.shownAs'), findsOneWidget);
    },
  );

  testWidgets('edit and save the names', (tester) async {
    final h = await pumpBookingApp(
      tester,
      riderRepo: FakeRiderRepository(registered: false),
      goTo: AppRoutes.profile,
    );
    await tester.enterText(byKey('profile.lastName'), '  Onyango ');
    await tester.pump();
    await tapKeyAndSettle(tester, 'profile.save');
    expect(h.account.nameCalls.single, (first: 'Moses', last: 'Onyango'));
    expect(byKey('profile.saved'), findsOneWidget);
  });

  testWidgets('empty name is caught before sending', (tester) async {
    final h = await pumpBookingApp(
      tester,
      riderRepo: FakeRiderRepository(registered: false),
      goTo: AppRoutes.profile,
    );
    await tester.enterText(byKey('profile.firstName'), ' ');
    await tester.pump();
    await tapKeyAndSettle(tester, 'profile.save');
    expect(h.account.nameCalls, isEmpty);
    expect(find.text(l10nOf(tester).errorFirstNameRequired), findsOneWidget);
  });

  testWidgets('a verified rider sees the lock message and cannot edit', (
    tester,
  ) async {
    await pumpBookingApp(
      tester,
      riderRepo: FakeRiderRepository(),
      goTo: AppRoutes.profile,
    );
    expect(byKey('profile.locked'), findsOneWidget);
    expect(find.text(l10nOf(tester).profileNameLocked), findsOneWidget);
    expect(fieldEnabled(tester, 'profile.firstName'), isFalse);
    expect(byKey('profile.save'), findsNothing);
  });

  testWidgets('a 403 on save shows the lock message', (tester) async {
    final account = FakeAccountRepository()
      ..nameError = apiError(
        403,
        'forbidden',
        'verified riders change their name through support',
      );
    await pumpBookingApp(
      tester,
      account: account,
      riderRepo: FakeRiderRepository(
        profile: riderProfileFixture(status: VerificationStatus.pending),
      ),
      goTo: AppRoutes.profile,
    );
    expect(byKey('profile.shownAs'), findsOneWidget);
    await tester.enterText(byKey('profile.firstName'), 'Mo');
    await tester.pump();
    await tapKeyAndSettle(tester, 'profile.save');
    expect(byKey('profile.locked'), findsOneWidget);
    expect(fieldEnabled(tester, 'profile.lastName'), isFalse);
  });

  testWidgets('sign out ends the session', (tester) async {
    final h = await pumpBookingApp(
      tester,
      riderRepo: FakeRiderRepository(registered: false),
      goTo: AppRoutes.profile,
    );
    await tapKeyAndSettle(tester, 'profile.signOut');
    expect(h.session.state, isA<SignedOut>());
  });
}
