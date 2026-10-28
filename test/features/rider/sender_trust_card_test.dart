import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridelink/core/api/api_exception.dart';
import 'package:ridelink/core/routing/app_router.dart';
import 'package:ridelink/features/profile/public/sender_profile_screen.dart';
import 'package:ridelink/features/rider/data/rider_models.dart';
import 'package:ridelink/features/rider/offer/sender_trust_card.dart';
import 'package:ridelink/theme/app_colors.dart';

import '../../support/booking_fakes.dart';
import '../../support/public_profile_fakes.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Finder byKey(String k) => find.byKey(Key(k));

  FakeRiderRepository withOffer({String? senderId = 'sender-1'}) =>
      FakeRiderRepository(
        profile: riderProfileFixture(online: true),
        activeResult: RiderActive(offer: riderOfferFixture(senderId: senderId)),
      );

  String seconds(WidgetTester tester) =>
      tester.widget<Text>(byKey('countdown.seconds')).data!;

  Future<BookingHarness> openOffer(
    WidgetTester tester,
    FakePublicProfileRepository profiles, {
    String? senderId = 'sender-1',
  }) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return pumpBookingApp(
      tester,
      clock: () => testNow,
      riderRepo: withOffer(senderId: senderId),
      publicProfiles: profiles,
      goTo: AppRoutes.riderHome,
      settle: false,
    );
  }

  Future<void> frames(WidgetTester tester, [int n = 6]) async {
    for (var i = 0; i < n; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('offer and countdown run while the profile is still loading', (
    tester,
  ) async {
    final profiles = FakePublicProfileRepository()..senderGate = Completer();
    await openOffer(tester, profiles);
    await frames(tester);
    expect(byKey('screen.riderOffer'), findsOneWidget);
    expect(profiles.senderCalls, ['sender-1']);
    expect(byKey('offer.senderTrust'), findsNothing);
    expect(seconds(tester), '60');
    await tester.pump(const Duration(seconds: 3));
    expect(seconds(tester), '57');

    profiles.senderGate!.complete();
    await frames(tester);
    expect(byKey('offer.senderTrust'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(seconds(tester), '55');
  });

  testWidgets('a failed profile shows nothing and leaves the countdown', (
    tester,
  ) async {
    final profiles = FakePublicProfileRepository()
      ..senderError = const ApiException(statusCode: 500, message: 'boom');
    await openOffer(tester, profiles);
    await frames(tester);
    expect(byKey('offer.senderTrust'), findsNothing);
    expect(byKey('offer.error'), findsNothing);
    expect(find.textContaining("Couldn't"), findsNothing);
    expect(seconds(tester), '60');
    await tester.pump(const Duration(seconds: 4));
    expect(seconds(tester), '56');
    expect(byKey('offer.accept'), findsOneWidget);
  });

  testWidgets('no sender id on the offer: no card, no request', (tester) async {
    final profiles = FakePublicProfileRepository();
    await openOffer(tester, profiles, senderId: null);
    await frames(tester);
    expect(byKey('offer.senderTrust'), findsNothing);
    expect(profiles.senderCalls, isEmpty);
  });

  testWidgets('loaded card shows orders, payment success and cancellations', (
    tester,
  ) async {
    await openOffer(tester, FakePublicProfileRepository());
    await frames(tester);
    final card = byKey('offer.senderTrust');
    Finder inCard(String text) =>
        find.descendant(of: card, matching: find.text(text));
    expect(inCard('Wanjiru'), findsOneWidget);
    expect(inCard('Orders'), findsOneWidget);
    expect(inCard('12'), findsOneWidget);
    expect(inCard('Payment success'), findsOneWidget);
    expect(inCard('100%'), findsOneWidget);
    expect(inCard('Cancellations'), findsOneWidget);
    expect(inCard('8%'), findsOneWidget);
    expect(inCard('Last 30 days'), findsOneWidget);
    expect(byKey('offer.senderTrust.newChip'), findsNothing);
  });

  testWidgets('small sample shows New on RideLink', (tester) async {
    final profiles = FakePublicProfileRepository(
      senders: {
        'sender-1': senderProfileFixture(
          paymentPct: null,
          cancelPct: null,
          newOnRideLink: true,
        ),
      },
    );
    await openOffer(tester, profiles);
    await frames(tester);
    expect(
      find.descendant(
        of: byKey('offer.senderTrust'),
        matching: find.text('New on RideLink'),
      ),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: byKey('offer.senderTrust'),
        matching: find.textContaining('%'),
      ),
      findsNothing,
    );
    expect(byKey('offer.senderTrust.newChip'), findsOneWidget);
  });

  testWidgets('tap opens the sender profile screen', (tester) async {
    await openOffer(tester, FakePublicProfileRepository());
    await frames(tester);
    await tester.tap(byKey('offer.senderTrust'));
    await frames(tester, 12);
    expect(find.byType(SenderProfileScreen), findsOneWidget);
    expect(byKey('screen.senderProfile'), findsOneWidget);
    expect(find.text('Sender profile'), findsOneWidget);
    expect(find.text('Orders (all time)'), findsOneWidget);
  });

  testWidgets(
    'card is at least 44 dp tall and never uses the countdown colour',
    (tester) async {
      await openOffer(tester, FakePublicProfileRepository());
      await frames(tester);
      final card = byKey('offer.senderTrust');
      expect(tester.getSize(card).height, greaterThanOrEqualTo(44));
      final countdown = AppColors.light.countdown;
      final inCard = find.descendant(
        of: card,
        matching: find.byWidgetPredicate((_) => true),
      );
      for (final e in inCard.evaluate()) {
        final w = e.widget;
        if (w is Text) expect(w.style?.color, isNot(countdown));
        if (w is Icon) expect(w.color, isNot(countdown));
        if (w is Container && w.decoration is BoxDecoration) {
          expect((w.decoration! as BoxDecoration).color, isNot(countdown));
        }
        if (w is Material) expect(w.color, isNot(countdown));
        if (w is Ink && w.decoration is BoxDecoration) {
          expect((w.decoration! as BoxDecoration).color, isNot(countdown));
        }
      }
      expect(find.byType(SenderTrustCard), findsOneWidget);
    },
  );
}
