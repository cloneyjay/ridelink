import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridelink/core/routing/app_router.dart';
import 'package:ridelink/features/booking/booking_routes.dart';
import 'package:ridelink/features/booking/data/booking_models.dart';
import 'package:ridelink/features/booking/resume.dart';

import '../../support/booking_fakes.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Finder byKey(String k) => find.byKey(Key(k));

  Future<void> advance(WidgetTester tester, Duration total) async {
    const step = Duration(milliseconds: 100);
    for (var t = Duration.zero; t < total; t += step) {
      await tester.pump(step);
    }
  }

  Future<void> foreground(WidgetTester tester) async {
    for (final s in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(s);
    }
    await advance(tester, const Duration(milliseconds: 500));
  }

  String seconds(WidgetTester tester) =>
      tester.widget<Text>(byKey('countdown.seconds')).data!;

  final offered = offerFixture().offeredAt!;
  DateTime twentySecondsIn() => offered.add(const Duration(seconds: 20));

  SenderOrder pendingOrder({
    String orderId = 'order-1',
    String offerId = 'offer-1',
    String rider = 'Moses O.',
  }) => SenderOrder(
    order: orderFixture(id: orderId, status: 'offered'),
    offer: offerFixture(id: offerId, orderId: orderId),
    rider: riderFixture(name: rider),
  );

  Order created(Order o, DateTime at) => Order(
    id: o.id,
    serviceType: o.serviceType,
    status: o.status,
    pickupAddress: o.pickupAddress,
    dropoffAddress: o.dropoffAddress,
    agreedPrice: o.agreedPrice,
    acceptedAt: o.acceptedAt,
    pickupDeadline: o.pickupDeadline,
    createdAt: at,
  );

  Future<void> leave(BookingHarness h, WidgetTester tester) async {
    h.router.go(AppRoutes.home);
    await advance(tester, const Duration(milliseconds: 500));
  }

  group('sender order parsing', () {
    Map<String, dynamic> orderJson({Object? pending, bool withKey = true}) => {
      'id': 'order-1',
      'service_type': 'delivery',
      'status': 'offered',
      'pickup_address': 'A',
      'dropoff_address': 'B',
      if (withKey) 'pending_offer': pending,
    };

    test('pending_offer is parsed with the offer and rider shapes', () {
      final o = SenderOrder.fromJson(
        orderJson(
          pending: {
            'offer': offerFixture().toJson(),
            'rider': riderFixture().toJson(),
          },
        ),
      );
      expect(o.hasPendingOffer, isTrue);
      expect(o.offer!.id, 'offer-1');
      expect(o.offer!.expiresAt, offerFixture().expiresAt);
      expect(o.rider!.displayName, 'Moses O.');
      expect(o.rider!.total, 214);
    });

    test('null, absent or malformed pending_offer means none', () {
      expect(SenderOrder.fromJson(orderJson()).hasPendingOffer, isFalse);
      expect(
        SenderOrder.fromJson(orderJson(withKey: false)).hasPendingOffer,
        isFalse,
      );
      expect(
        SenderOrder.fromJson(
          orderJson(
            pending: {
              'offer': {'id': 'x'},
              'rider': riderFixture().toJson(),
            },
          ),
        ).hasPendingOffer,
        isFalse,
      );
    });
  });

  group('resume targets', () {
    test('pending offer -> waiting, assigned -> tracking, else none', () {
      expect(resumeTargetFor(pendingOrder()), isA<ResumeWaiting>());
      final waiting = resumeTargetFor(pendingOrder())! as ResumeWaiting;
      expect(waiting.pending.fromServer, isTrue);
      expect(waiting.location, AppRoutes.waitingFor('order-1'));
      expect(
        resumeTargetFor(SenderOrder(order: jobFixture())),
        isA<ResumeTracking>(),
      );
      expect(resumeTargetFor(SenderOrder(order: orderFixture())), isNull);
      expect(
        resumeTargetFor(SenderOrder(order: orderFixture(status: 'offered'))),
        isNull,
        reason: 'offered without a live offer has nothing to wait on',
      );
    });

    test('newest first; orders without a live screen are skipped', () {
      final t0 = DateTime.utc(2026, 10, 19, 8);
      final targets = resumeTargets([
        SenderOrder(order: created(jobFixture(id: 'old'), t0)),
        SenderOrder(
          order: created(
            orderFixture(id: 'draft'),
            t0.add(const Duration(hours: 2)),
          ),
        ),
        SenderOrder(
          order: created(
            jobFixture(id: 'new'),
            t0.add(const Duration(hours: 1)),
          ),
        ),
      ]);
      expect(
        [for (final t in targets) (t as ResumeTracking).order.id],
        ['new', 'old'],
      );
    });
  });

  group('server-driven resume on the sender side', () {
    testWidgets('a pending offer reopens the waiting screen from the server', (
      tester,
    ) async {
      final repo = FakeBookingRepository()..activeList = [pendingOrder()];
      final h = await pumpBookingApp(
        tester,
        repo: repo,
        clock: twentySecondsIn,
        settle: false,
      );
      await advance(tester, const Duration(milliseconds: 500));
      expect(repo.activeCalls, 1);
      expect(byKey('screen.offerWaiting'), findsOneWidget);
      expect(find.text('Waiting for Moses O.'), findsOneWidget);
      expect(seconds(tester), '40', reason: 'counts down to expires_at');
      await leave(h, tester);
    });

    testWidgets('an assigned order reopens tracking', (tester) async {
      final repo = FakeBookingRepository()
        ..activeList = [SenderOrder(order: jobFixture())]
        ..order = jobFixture();
      await pumpBookingApp(tester, repo: repo, clock: () => testNow);
      expect(byKey('screen.tracking'), findsOneWidget);
    });

    testWidgets('no active orders: the sender stays home', (tester) async {
      final repo = FakeBookingRepository();
      await pumpBookingApp(tester, repo: repo);
      expect(repo.activeCalls, 1);
      expect(byKey('screen.home'), findsOneWidget);
      expect(byKey('home.activeOrders'), findsNothing);
    });

    testWidgets(
      'several active orders: the newest resumes, all stay reachable',
      (tester) async {
        final repo = FakeBookingRepository()
          ..activeList = [
            SenderOrder(order: jobFixture(id: 'order-new')),
            pendingOrder(orderId: 'order-old'),
          ]
          ..order = jobFixture(id: 'order-new');
        final h = await pumpBookingApp(
          tester,
          repo: repo,
          clock: () => testNow,
        );
        expect(byKey('screen.tracking'), findsOneWidget);
        expect(h.router.state.matchedLocation, contains('order-new'));

        await tapKeyAndSettle(tester, 'tracking.back');
        expect(byKey('home.activeOrder.order-new'), findsOneWidget);
        expect(byKey('home.activeOrder.order-old'), findsOneWidget);
      },
    );

    testWidgets('foreground re-asks the server and resumes from home', (
      tester,
    ) async {
      final repo = FakeBookingRepository()..order = jobFixture();
      await pumpBookingApp(tester, repo: repo, clock: () => testNow);
      expect(byKey('screen.home'), findsOneWidget);

      repo.activeList = [SenderOrder(order: jobFixture())];
      await foreground(tester);
      await tester.pumpAndSettle();
      expect(repo.activeCalls, 2);
      expect(byKey('screen.tracking'), findsOneWidget);
    });

    testWidgets('realtime reconnect re-asks the server and resumes', (
      tester,
    ) async {
      final repo = FakeBookingRepository()..order = jobFixture();
      final h = await pumpBookingApp(tester, repo: repo, clock: () => testNow);
      repo.activeList = [SenderOrder(order: jobFixture())];
      h.emit('connected', {});
      await tester.pumpAndSettle();
      expect(repo.activeCalls, 2);
      expect(byKey('screen.tracking'), findsOneWidget);
    });

    testWidgets('a live screen the sender left is not reopened on foreground', (
      tester,
    ) async {
      final repo = FakeBookingRepository()
        ..activeList = [SenderOrder(order: jobFixture())]
        ..order = jobFixture();
      await pumpBookingApp(tester, repo: repo, clock: () => testNow);
      await tapKeyAndSettle(tester, 'tracking.back');
      await foreground(tester);
      await tester.pumpAndSettle();
      expect(byKey('screen.home'), findsOneWidget);
      expect(byKey('home.activeOrder.order-9'), findsOneWidget);
    });

    testWidgets('the sender is not pulled off another screen', (tester) async {
      final repo = FakeBookingRepository();
      final h = await pumpBookingApp(
        tester,
        repo: repo,
        clock: () => testNow,
        goTo: AppRoutes.ridersFor('order-1'),
      );
      repo.activeList = [SenderOrder(order: jobFixture())];
      await foreground(tester);
      h.emit('connected', {});
      await tester.pumpAndSettle();
      expect(repo.activeCalls, greaterThanOrEqualTo(2));
      expect(byKey('screen.riderList'), findsOneWidget);
    });
  });

  group('waiting screen stays in sync with the server', () {
    Future<BookingHarness> openWaiting(
      WidgetTester tester,
      FakeBookingRepository repo,
    ) async {
      final h = await pumpBookingApp(
        tester,
        repo: repo,
        clock: twentySecondsIn,
        goTo: AppRoutes.waitingFor('order-1'),
        extra: PendingOffer(
          order: orderFixture(status: 'offered'),
          rider: riderFixture(),
          offer: offerFixture(),
        ),
        settle: false,
      );
      await advance(tester, const Duration(milliseconds: 500));
      return h;
    }

    testWidgets('expiry re-reads the order before leaving', (tester) async {
      final repo = FakeBookingRepository()
        ..order = orderFixture(status: 'created');
      final h = await openWaiting(tester, repo);
      h.emit('offer.resolved', {
        'offer_id': 'offer-1',
        'order_id': 'order-1',
        'outcome': 'expired',
      });
      await tester.pumpAndSettle();
      expect(repo.getOrderCalls, 1);
      expect(byKey('screen.riderList'), findsOneWidget);
    });

    testWidgets('expiry with the server unreachable still leaves the offer', (
      tester,
    ) async {
      final repo = FakeBookingRepository()
        ..senderOrderError = apiError(500, 'internal_error');
      final h = await openWaiting(tester, repo);
      h.emit('offer.resolved', {
        'offer_id': 'offer-1',
        'order_id': 'order-1',
        'outcome': 'declined',
      });
      await tester.pumpAndSettle();
      expect(byKey('screen.riderList'), findsOneWidget);
    });

    testWidgets('reconnect shows the live offer the server has now', (
      tester,
    ) async {
      final repo = FakeBookingRepository()
        ..senderOrderResult = pendingOrder(
          offerId: 'offer-2',
          rider: 'Amina K.',
        );
      final h = await openWaiting(tester, repo);
      h.emit('connected', {});
      await advance(tester, const Duration(milliseconds: 500));
      expect(find.text('Waiting for Amina K.'), findsOneWidget);
      expect(find.text('Waiting for Moses O.'), findsNothing);
      await leave(h, tester);
    });

    testWidgets('reconnect after the offer ended never shows it as live', (
      tester,
    ) async {
      final repo = FakeBookingRepository()
        ..order = orderFixture(status: 'offered');
      final h = await openWaiting(tester, repo);
      expect(seconds(tester), isNot('0'));
      h.emit('connected', {});
      await advance(tester, const Duration(milliseconds: 500));
      expect(seconds(tester), '0');
      expect(find.text("Checking the rider's response…"), findsOneWidget);
      await leave(h, tester);
    });

    testWidgets('reconnect after acceptance opens tracking', (tester) async {
      final repo = FakeBookingRepository()..order = jobFixture(id: 'order-1');
      final h = await openWaiting(tester, repo);
      h.emit('connected', {});
      await tester.pumpAndSettle();
      expect(byKey('screen.tracking'), findsOneWidget);
    });

    testWidgets('foreground re-reads the order', (tester) async {
      final repo = FakeBookingRepository()..senderOrderResult = pendingOrder();
      final h = await openWaiting(tester, repo);
      await foreground(tester);
      expect(repo.getOrderCalls, 1);
      expect(byKey('screen.offerWaiting'), findsOneWidget);
      await leave(h, tester);
    });
  });

  group('no device copy of live order state', () {
    test(
      'the pending-offer store is gone and nothing writes offers locally',
      () {
        expect(
          File('lib/features/booking/data/pending_offer_store.dart')
              .existsSync(),
          isFalse,
        );
        final offenders = <String>[];
        for (final f in Directory('lib').listSync(recursive: true)) {
          if (f is! File || !f.path.endsWith('.dart')) continue;
          // The startup cleanup names the old key only to delete it.
          if (f.uri.pathSegments.last == 'legacy_keys.dart') continue;
          final src = f.readAsStringSync();
          if (RegExp(
            r'PendingOfferStore|pendingOfferStore|ridelink\.pending_offer',
          ).hasMatch(src)) {
            offenders.add(f.path);
          }
        }
        expect(offenders, isEmpty);
      },
    );

    test('local storage is used only for preferences', () {
      final users = <String>[];
      for (final f in Directory('lib').listSync(recursive: true)) {
        if (f is! File || !f.path.endsWith('.dart')) continue;
        if (f.readAsStringSync().contains('localStoreProvider')) {
          users.add(f.uri.pathSegments.last);
        }
      }
      expect(users.toSet(), {'providers.dart', 'main.dart'});
    });
  });
}
