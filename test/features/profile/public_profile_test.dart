import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridelink/core/api/api_client.dart';
import 'package:ridelink/core/api/api_exception.dart';
import 'package:ridelink/core/auth/access_token_source.dart';
import 'package:ridelink/core/config/app_config.dart';
import 'package:ridelink/core/providers.dart';
import 'package:ridelink/core/routing/app_router.dart';
import 'package:ridelink/features/booking/booking_routes.dart';
import 'package:ridelink/features/profile/public/public_profile_models.dart';
import 'package:ridelink/features/profile/public/public_profile_repository.dart';
import 'package:ridelink/features/profile/public/public_profile_view.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import 'package:ridelink/theme/app_dimensions.dart';
import 'package:ridelink/theme/app_theme.dart';

import '../../support/booking_fakes.dart';
import '../../support/fakes.dart';
import '../../support/public_profile_fakes.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Finder byKey(String k) => find.byKey(Key(k));

  group('PublicProfile.fromJson', () {
    test('parses the sender body', () {
      final p = PublicProfile.fromJson(senderProfileJson());
      expect(p.role, PublicProfileRole.sender);
      expect(p.id, 'sender-1');
      expect(p.firstName, 'Wanjiru');
      expect(p.photoUrl, 'http://test.local/v1/senders/sender-1/photo');
      expect(p.joinedAt, DateTime.utc(2026, 10, 1));
      expect(p.badges, isEmpty);
      expect(p.newOnRideLink, isFalse);
      expect(p.stats30d, {
        'orders': 12,
        'payment_success_pct': 100,
        'cancellation_pct': 8,
      });
      expect(p.allTime, {'orders': 47});
      expect(p.orders30d, 12);
      expect(p.paymentSuccessPct, 100);
      expect(p.cancellationPct, 8);
      expect(p.ordersAllTime, 47);
      expect(p.rating, isNull);
      expect(p.computedAt, DateTime.utc(2026, 10, 27, 2));
    });

    test('null percentages stay null; missing counts are 0', () {
      final json = senderProfileJson(paymentPct: null, cancelPct: null)
        ..['all_time'] = <String, dynamic>{}
        ..['computed_at'] = null;
      final p = PublicProfile.fromJson(json);
      expect(p.paymentSuccessPct, isNull);
      expect(p.cancellationPct, isNull);
      expect(p.ordersAllTime, 0);
      expect(p.computedAt, isNull);
    });

    test('parses the rider body with badge, rating and terms', () {
      final p = PublicProfile.fromJson(riderProfileJson());
      expect(p.role, PublicProfileRole.rider);
      expect(p.isVerifiedRider, isTrue);
      expect(p.photoUrl, isNull);
      expect(p.completed30d, 40);
      expect(p.onTimePct, 98);
      expect(p.acceptPct, 90);
      expect(p.disputePct, 0);
      expect(p.positivePct, 97);
      expect(p.completedAllTime, 340);
      expect(p.rating!.average, 4.8);
      expect(p.rating!.count, 120);
      expect(p.terms, {'delivery_price_per_km': 16});
    });

    test('badges null is treated as empty', () {
      final p = PublicProfile.fromJson(riderProfileJson()..['badges'] = null);
      expect(p.badges, isEmpty);
      expect(p.isVerifiedRider, isFalse);
    });
  });

  group('ApiPublicProfileRepository', () {
    ({PublicProfileRepository repo, List<String> paths}) build() {
      final paths = <String>[];
      final adapter = FakeAdapter((o) {
        paths.add('${o.uri.path.replaceFirst('/v1/', '')}?${o.uri.query}');
        if (o.uri.path.endsWith('/photo')) {
          return o.uri.path.contains('s404')
              ? jsonResponse(404, {'error': 'not found'})
              : ResponseBody.fromBytes([1, 2, 3], 200);
        }
        final body =
            o.uri.path.contains('senders/') || o.uri.query == 'role=sender'
            ? senderProfileJson()
            : riderProfileJson();
        return jsonResponse(200, body);
      });
      final api = ApiClient(
        AppConfig(apiBaseUrl: Uri.parse('http://test.local')),
        tokens: _StaticTokens(),
        adapter: adapter,
      );
      return (repo: ApiPublicProfileRepository(api), paths: paths);
    }

    test('calls the three endpoints', () async {
      final b = build();
      expect((await b.repo.sender('s1')).role, PublicProfileRole.sender);
      expect((await b.repo.rider('r1')).role, PublicProfileRole.rider);
      expect(
        (await b.repo.mine(PublicProfileRole.sender)).role,
        PublicProfileRole.sender,
      );
      await b.repo.mine(PublicProfileRole.rider);
      expect(await b.repo.senderPhoto('s1'), [1, 2, 3]);
      expect(await b.repo.senderPhoto('s404'), isNull);
      expect(b.paths, [
        'senders/s1/public-profile?',
        'riders/r1/public-profile?',
        'me/public-profile?role=sender',
        'me/public-profile?role=rider',
        'senders/s1/photo?',
        'senders/s404/photo?',
      ]);
    });
  });

  group('PublicProfileView', () {
    Future<void> pumpView(
      WidgetTester tester,
      PublicProfile profile, {
      Locale locale = const Locale('en'),
      Widget? below,
      FakePublicProfileRepository? repo,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            publicProfileRepositoryProvider.overrideWithValue(
              repo ?? FakePublicProfileRepository(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            locale: locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: PublicProfileView(profile: profile, below: below),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    AppLocalizations l10n(WidgetTester tester) =>
        AppLocalizations.of(tester.element(find.byType(PublicProfileView)));

    testWidgets('sender: joined, 30-day stats, all-time orders, no rating', (
      tester,
    ) async {
      await pumpView(tester, senderProfileFixture());
      expect(find.text('Wanjiru'), findsOneWidget);
      expect(find.text('Joined Oct 2026'), findsOneWidget);
      expect(find.text('Last 30 days'), findsOneWidget);
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Payment success'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Cancellations'), findsOneWidget);
      expect(find.text('8%'), findsOneWidget);
      expect(find.text('Orders (all time)'), findsOneWidget);
      expect(find.text('47'), findsOneWidget);
      expect(find.text('Verified rider'), findsNothing);
      expect(byKey('publicProfile.stat.rating'), findsNothing);
      expect(find.text(l10n(tester).statRating), findsNothing);
    });

    testWidgets('null percentage shows New on RideLink', (tester) async {
      await pumpView(
        tester,
        senderProfileFixture(paymentPct: null, cancelPct: null),
      );
      expect(find.text('New on RideLink'), findsNWidgets(2));
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('Swahili joined line and labels', (tester) async {
      await pumpView(
        tester,
        senderProfileFixture(paymentPct: null),
        locale: const Locale('sw'),
      );
      final l = l10n(tester);
      expect(find.textContaining('Alijiunga'), findsOneWidget);
      expect(find.text('Joined Oct 2026'), findsNothing);
      expect(find.text(l.publicProfilePaymentSuccess), findsOneWidget);
      expect(find.text(l.publicProfileNewOnRideLink), findsOneWidget);
      expect(find.text(l.publicProfileOrdersAllTime), findsOneWidget);
    });

    testWidgets('rider: verified badge, rating, trips all time, below child', (
      tester,
    ) async {
      await pumpView(
        tester,
        riderPublicProfileFixture(),
        below: const Text('terms-below', key: Key('below')),
      );
      expect(find.text('Moses'), findsOneWidget);
      expect(find.text('Verified rider'), findsOneWidget);
      expect(find.text('Joined Oct 2026'), findsOneWidget);
      expect(byKey('publicProfile.stat.rating'), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);
      expect(find.text('98%'), findsOneWidget);
      expect(find.text('Accepted'), findsOneWidget);
      expect(find.text('90%'), findsOneWidget);
      expect(find.text('On time'), findsOneWidget);
      expect(find.text('Disputes'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('Positive'), findsOneWidget);
      expect(find.text('97%'), findsOneWidget);
      expect(find.text('Completed jobs'), findsOneWidget);
      expect(find.text('40'), findsOneWidget);
      expect(byKey('publicProfile.newChip'), findsNothing);
      expect(find.text('Trips (all time)'), findsOneWidget);
      expect(find.text('340'), findsOneWidget);
      expect(byKey('below'), findsOneWidget);
    });

    testWidgets('new_on_ridelink shows the New on RideLink chip', (
      tester,
    ) async {
      await pumpView(tester, senderProfileFixture(newOnRideLink: true));
      expect(byKey('publicProfile.newChip'), findsOneWidget);
      await pumpView(
        tester,
        PublicProfile.fromJson(riderProfileJson()..['new_on_ridelink'] = true),
      );
      expect(byKey('publicProfile.newChip'), findsOneWidget);
    });

    testWidgets('sender photo loads as bytes through the Go client', (
      tester,
    ) async {
      final repo = FakePublicProfileRepository();
      await pumpView(tester, senderProfileFixture(), repo: repo);
      expect(repo.senderPhotoCalls, ['sender-1']);
      expect(find.text('W'), findsOneWidget, reason: 'null bytes: initials');
    });

    testWidgets('sender photo error or no photo_url shows initials', (
      tester,
    ) async {
      final repo = FakePublicProfileRepository()
        ..senderPhotoError = const ApiException(statusCode: 500, message: 'x');
      await pumpView(tester, senderProfileFixture(), repo: repo);
      expect(find.text('W'), findsOneWidget);

      final none = FakePublicProfileRepository();
      await pumpView(
        tester,
        PublicProfile.fromJson(senderProfileJson(hasPhoto: false)),
        repo: none,
      );
      expect(none.senderPhotoCalls, isEmpty);
      expect(find.text('W'), findsOneWidget);
    });

    testWidgets('unverified rider has no badge', (tester) async {
      await pumpView(
        tester,
        PublicProfile.fromJson(riderProfileJson(verified: false)),
      );
      expect(find.text('Verified rider'), findsNothing);
    });

    testWidgets('all tap targets are at least 44 dp', (tester) async {
      await pumpView(
        tester,
        riderPublicProfileFixture(),
        below: OutlinedButton(onPressed: () {}, child: const Text('x')),
      );
      final targets = find.byWidgetPredicate(
        (w) => w is InkWell || w is ButtonStyleButton,
      );
      for (final e in targets.evaluate()) {
        final size = tester.getSize(find.byWidget(e.widget));
        expect(size.width, greaterThanOrEqualTo(AppLayout.minTapTarget));
        expect(size.height, greaterThanOrEqualTo(AppLayout.minTapTarget));
      }
    });
  });

  group('screen 3 uses the shared profile', () {
    testWidgets('rider profile from GET /riders/{id}/public-profile', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final h = await pumpBookingApp(
        tester,
        goTo: AppRoutes.ridersFor('order-1'),
        extra: RiderListArgs(order: orderFixture()),
      );
      await tapKeyAndSettle(tester, 'riders.row.rider-1');
      expect(byKey('screen.riderProfile'), findsOneWidget);
      expect(h.publicProfiles.riderCalls, ['rider-1']);
      expect(find.text('Verified rider'), findsOneWidget);
      expect(find.text('Joined Oct 2026'), findsOneWidget);
      expect(find.text('Trips (all time)'), findsOneWidget);
      expect(byKey('profile.breakdown'), findsOneWidget);
      expect(byKey('profile.request'), findsOneWidget);
    });

    testWidgets('profile failure keeps the price and request; retry loads', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final profiles = FakePublicProfileRepository()..riderError = notFound();
      await pumpBookingApp(
        tester,
        publicProfiles: profiles,
        goTo: AppRoutes.ridersFor('order-1'),
        extra: RiderListArgs(order: orderFixture()),
      );
      await tapKeyAndSettle(tester, 'riders.row.rider-1');
      expect(byKey('publicProfile.error'), findsOneWidget);
      expect(byKey('profile.breakdown'), findsOneWidget);
      expect(byKey('profile.request'), findsOneWidget);
      profiles.riderError = null;
      await tapKeyAndSettle(tester, 'publicProfile.retry');
      expect(find.text('Verified rider'), findsOneWidget);
    });
  });
}

class _StaticTokens implements AccessTokenSource {
  @override
  String? get accessToken => 'access-1';

  @override
  bool get hasSession => true;

  @override
  bool get accessTokenExpiresSoon => false;

  @override
  Future<bool> refresh() async => false;
}
