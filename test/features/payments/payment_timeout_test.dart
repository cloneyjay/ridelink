import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ridelink/core/push/push_payload.dart';
import 'package:ridelink/core/push/push_text.dart';
import 'package:ridelink/core/routing/app_router.dart';
import 'package:ridelink/features/booking/data/booking_models.dart';
import 'package:ridelink/features/evidence/evidence_record_screen.dart';
import 'package:ridelink/features/notifications/notification_text.dart';
import 'package:ridelink/features/orders/data/order_models.dart';
import 'package:ridelink/features/orders/order_labels.dart';
import 'package:ridelink/features/payments/data/payment_models.dart';
import 'package:ridelink/features/payments/payment_validation.dart';
import 'package:ridelink/features/rider/data/rider_models.dart';
import 'package:ridelink/features/rider/rider_labels.dart';
import 'package:ridelink/features/tracking/tracking_screen.dart';
import 'package:ridelink/l10n/app_localizations.dart';

import '../../support/booking_fakes.dart';

const _till = PaymentMethod(
  type: PayMethod.mpesaTill,
  number: '123456',
  accountName: 'Moses Boda',
);

Order _timeoutClosed({DateTime? until, ServiceType? service}) =>
    jobFixture(
      status: 'completed',
      arrivedAt: testNow,
      service: service ?? ServiceType.delivery,
    ).copyWith(
      paymentConfirmation: (PaymentConfirmation.timeout,),
      lateReportUntil: (until,),
    );

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('en');
    await initializeDateFormatting('sw');
  });

  Finder byKey(String k) => find.byKey(Key(k));
  final en = lookupAppLocalizations(const Locale('en'));
  final sw = lookupAppLocalizations(const Locale('sw'));

  Future<void> pumpFor(WidgetTester tester, [int frames = 12]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> tap(WidgetTester tester, String key) async {
    if (byKey(key).evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        byKey(key),
        200,
        scrollable: find.byType(Scrollable).last,
      );
    }
    await tester.ensureVisible(byKey(key));
    await tester.pump();
    await tester.tap(byKey(key));
    await pumpFor(tester);
  }

  group('order JSON', () {
    Map<String, dynamic> json(Map<String, dynamic> extra) => {
      'id': 'o1',
      'service_type': 'delivery',
      'status': 'completed',
      ...extra,
    };

    test('payer, payment_confirmation and late_report_until parse', () {
      final o = Order.fromJson(
        json({
          'payer': 'receiver',
          'payment_confirmation': 'timeout',
          'late_report_until': '2026-10-14T09:42:00Z',
        }),
      );
      expect(o.payer, Payer.receiver);
      expect(o.paymentConfirmation, PaymentConfirmation.timeout);
      expect(o.lateReportUntil, DateTime.utc(2026, 10, 14, 9, 42));
      expect(o.closedByTimeout, isTrue);
      expect(o.canReportLate(testNow), isTrue);
      expect(o.canReportLate(DateTime.utc(2026, 10, 14, 9, 43)), isFalse);
    });

    test('missing fields default to sender pays, not yet confirmed', () {
      final o = Order.fromJson(json({}));
      expect(o.payer, Payer.sender);
      expect(o.paymentConfirmation, isNull);
      expect(o.lateReportUntil, isNull);
      expect(o.closedByTimeout, isFalse);
      expect(o.canReportLate(testNow), isFalse);
      final confirmed = Order.fromJson(
        json({'payment_confirmation': 'confirmed'}),
      );
      expect(confirmed.closedByTimeout, isFalse);
    });

    test('realtime updates carry the new fields, and null clears them', () {
      final o = jobFixture(status: 'payment_requested');
      final closed = o.applyUpdate({
        'status': 'completed',
        'payment_confirmation': 'timeout',
        'late_report_until': '2026-10-14T09:42:00Z',
      });
      expect(closed.closedByTimeout, isTrue);
      expect(closed.lateReportUntil, isNotNull);
      final reported = closed.applyUpdate({
        'status': 'unresolved',
        'late_report_until': null,
      });
      expect(reported.lateReportUntil, isNull);
      expect(reported.paymentConfirmation, PaymentConfirmation.timeout);
      expect(o.applyUpdate({'status': 'completed'}).paymentConfirmation, null);
      // After a late report the server keeps "timeout"; the status wins.
      expect(reported.closedByTimeout, isFalse);
      expect(reported.canReportLate(testNow), isFalse);
      expect(orderStatusLabel(en, reported), en.statusUnresolved);
    });
  });

  group('copy', () {
    test('timeout-closed orders get their own status label', () {
      for (final l in [en, sw]) {
        expect(
          orderStatusLabel(l, _timeoutClosed()),
          l.statusCompletedUnconfirmed,
        );
        expect(
          orderStatusLabel(l, jobFixture(status: 'completed')),
          l.statusCompleted,
        );
        expect(
          evidenceEventName(l, 'payment_timeout_closed', ServiceType.delivery),
          l.statusCompletedUnconfirmed,
        );
      }
      expect(en.statusCompletedUnconfirmed, 'Completed, payment not confirmed');
    });

    test('payment_reminder and timeout-close notifications and pushes', () {
      expect(en.notifPaymentReminderTitle, 'Confirm payment');
      expect(
        en.notifPaymentReminderBody,
        'Did you get paid for this order? Tap to confirm.',
      );
      expect(
        en.lateReportBody('14 Oct, 15:30'),
        "This order was closed because payment wasn't confirmed. "
        'If you weren\'t paid, tap Not paid by 14 Oct, 15:30.',
      );
      expect(paymentTimeoutRiderType, 'payment_timeout_closed');
      expect(paymentTimeoutSenderType, 'order_completed');
      expect(en.notifOrderClosedTitle, 'Order closed');
      expect(en.notifOrderCompleteTitle, 'Order complete');
      expect(en.notifOrderCompleteBody, 'Your order is complete.');
      for (final l in [en, sw]) {
        for (final (type, title, body) in [
          (
            paymentReminderType,
            l.notifPaymentReminderTitle,
            l.notifPaymentReminderBody,
          ),
          (
            paymentTimeoutRiderType,
            l.notifOrderClosedTitle,
            l.lateReportBodyNoDeadline,
          ),
          (
            paymentTimeoutSenderType,
            l.notifOrderCompleteTitle,
            l.notifOrderCompleteBody,
          ),
        ]) {
          final n = notificationText(
            notificationFixture(type: type, data: const {'order_id': 'o'}),
            l,
          );
          expect((n.title, n.body), (title, body), reason: type);
          final p = pushText(PushPayload(type: type, orderId: 'o'), l);
          expect((p.title, p.body), (title, body), reason: 'push $type');
        }
      }
      // In-app, the rider's text names the real deadline (local time).
      final until = DateTime.utc(2026, 10, 14, 9, 42);
      final closed = notificationText(
        notificationFixture(
          type: paymentTimeoutRiderType,
          data: {'order_id': 'o', 'late_report_until': until.toIso8601String()},
        ),
        en,
      );
      expect(closed.body, en.lateReportBody(formatDateTime(en, until)));
      final reminder = notificationText(
        notificationFixture(
          type: paymentReminderType,
          data: const {'order_id': 'o', 'reminder': 2},
        ),
        en,
      );
      expect(reminder.title, 'Confirm payment');
      expect(riderPushTypes, contains(paymentReminderType));
      expect(riderPushTypes, contains(paymentTimeoutRiderType));
      expect(riderPushTypes, isNot(contains(paymentTimeoutSenderType)));
    });

    test(
      'payment_not_paid uses the receiver wording when the receiver paid',
      () {
        for (final l in [en, sw]) {
          String body(Map<String, dynamic> data, {String server = 'x'}) =>
              notificationText(
                notificationFixture(
                  type: 'payment_not_paid',
                  data: data,
                  body: server,
                ),
                l,
              ).body;
          expect(body(const {'order_id': 'o'}), l.notifPaymentNotPaidBody);
          expect(
            body(const {'order_id': 'o', 'payer': 'receiver'}),
            l.notifPaymentNotPaidReceiverBody,
          );
          expect(
            body(
              const {'order_id': 'o'},
              server: "Your rider says the receiver didn't pay. Tell us if it was paid.",
            ),
            l.notifPaymentNotPaidReceiverBody,
          );
        }
      },
    );
  });

  group('receiver pays', () {
    testWidgets('sender pay card says the receiver is paying, with fallback '
        'details', (tester) async {
      final orders = FakeOrdersRepository()
        ..paymentResult = const OrderPayment(
          amount: 214,
          currency: 'KES',
          cash: true,
          methods: [_till],
        );
      await pumpBookingApp(
        tester,
        repo: FakeBookingRepository()
          ..order = jobFixture(status: 'payment_requested')
              .copyWith(payer: Payer.receiver),
        orders: orders,
        clock: () => testNow,
        goTo: AppRoutes.trackingFor('order-9'),
        extra: const TrackingArgs(riderId: 'rider-1', riderName: 'Moses O.'),
      );
      final l = l10nOf(tester);
      expect(
        tester.widget<Text>(byKey('tracking.receiverPaying')).data,
        'Your receiver is paying KES 214.',
      );
      expect(find.text("If they can't pay, you can pay here."), findsOneWidget);
      expect(find.text(l.payYourRiderTitle), findsNothing);
      expect(byKey('tracking.pay.cash'), findsOneWidget);
      expect(
        tester.widget<Text>(byKey('tracking.pay.mpesa_till.number')).data,
        '123456',
      );
      expect(byKey('tracking.copy.mpesa_till'), findsOneWidget);
    });

    test('mobile numbers show in the local form; copy is digits only', () {
      const pochi = PaymentMethod(
        type: PayMethod.mpesaPochi,
        number: '+254712345678',
        accountName: 'M',
      );
      expect(payNumberFor(pochi), (
        shown: '0712 345 678',
        copied: '0712345678',
      ));
      const send = PaymentMethod(
        type: PayMethod.mpesaSendMoney,
        number: '+254112345678',
        accountName: 'M',
      );
      expect(payNumberFor(send).shown, '0112 345 678');
      expect(payNumberFor(_till), (shown: '123456', copied: '123456'));
      expect(formatLocalMobile('not a number'), 'not a number');
    });

    testWidgets('receiver-paid "Did you pay?" asks whether it was paid', (
      tester,
    ) async {
      final orders = FakeOrdersRepository()
        ..paymentResult = const OrderPayment(
          amount: 214,
          currency: 'KES',
          cash: true,
          methods: [],
          payerResponse: PayerResponseState.pending,
        );
      await pumpBookingApp(
        tester,
        repo: FakeBookingRepository()
          ..order = jobFixture(status: 'unresolved')
              .copyWith(payer: Payer.receiver),
        orders: orders,
        clock: () => testNow,
        goTo: AppRoutes.trackingFor('order-9'),
        extra: const TrackingArgs(riderId: 'rider-1', riderName: 'Moses O.'),
      );
      final l = l10nOf(tester);
      expect(
        find.text("Your rider says the receiver didn't pay. Was it paid?"),
        findsOneWidget,
      );
      expect(find.text(l.payerPromptTitle), findsNothing);
      expect(byKey('payer.prompt'), findsOneWidget);
    });

    FakeRiderRepository withJob(Order job) => FakeRiderRepository(
      profile: riderProfileFixture(online: true),
      activeResult: RiderActive(order: job),
    )..job = job;

    testWidgets('rider sees who pays at arrival', (tester) async {
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: withJob(
          jobFixture(
            status: 'payment_requested',
            arrivedAt: testNow,
          ).copyWith(payer: Payer.receiver),
        ),
        goTo: AppRoutes.riderHome,
      );
      await pumpFor(tester);
      expect(byKey('job.payer.receiver'), findsOneWidget);
      expect(find.text('Receiver pays'), findsOneWidget);
    });

    testWidgets('rider collect panel shows mobile numbers in the local form', (
      tester,
    ) async {
      final orders = FakeOrdersRepository()
        ..paymentResult = const OrderPayment(
          amount: 214,
          currency: 'KES',
          cash: true,
          methods: [
            _till,
            PaymentMethod(
              type: PayMethod.mpesaSendMoney,
              number: '+254712345678',
              accountName: 'Moses Otieno',
            ),
          ],
        );
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        orders: orders,
        riderRepo: withJob(
          jobFixture(status: 'payment_requested', arrivedAt: testNow),
        ),
        goTo: AppRoutes.riderHome,
      );
      await pumpFor(tester);
      expect(find.text('0712 345 678'), findsOneWidget);
      expect(find.text('+254712345678'), findsNothing);
      expect(find.text('123456'), findsOneWidget);
    });

    testWidgets('sender pays is shown too', (tester) async {
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: withJob(
          jobFixture(status: 'payment_requested', arrivedAt: testNow),
        ),
        goTo: AppRoutes.riderHome,
      );
      await pumpFor(tester);
      expect(byKey('job.payer.sender'), findsOneWidget);
      expect(find.text('Sender pays'), findsOneWidget);
    });
  });

  group('payment timeout: rider', () {
    FakeRiderRepository withJob(Order job) => FakeRiderRepository(
      profile: riderProfileFixture(online: true),
      activeResult: RiderActive(order: job),
    )..job = job;

    testWidgets('Not paid within the window reports it and shows review', (
      tester,
    ) async {
      final repo = withJob(
        _timeoutClosed(until: testNow.add(const Duration(hours: 20))),
      );
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: repo,
        goTo: AppRoutes.riderHome,
      );
      await pumpFor(tester);
      // Completion still asks for a rating first.
      expect(byKey('rating.sheet'), findsOneWidget);
      await tap(tester, 'rating.skip');
      await tester.pumpAndSettle();
      final l = l10nOf(tester);
      expect(byKey('job.late'), findsOneWidget);
      expect(
        find.text(
          l.lateReportBody(
            formatDateTime(l, testNow.add(const Duration(hours: 20))),
          ),
        ),
        findsOneWidget,
      );
      expect(
        tester.getSize(byKey('job.late.notPaid')).height,
        greaterThanOrEqualTo(44),
      );

      await tap(tester, 'job.late.notPaid');
      expect(byKey('job.late.dialog'), findsOneWidget);
      await tap(tester, 'job.late.dialog.no');
      expect(repo.jobCalls, isEmpty);

      await tap(tester, 'job.late.notPaid');
      await tap(tester, 'job.late.dialog.yes');
      expect(repo.jobCalls, ['payment/not-received']);
      expect(byKey('job.status.unresolved'), findsOneWidget);
      expect(byKey('job.late'), findsNothing);
    });

    testWidgets('after the window: label only, no Not paid', (tester) async {
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: withJob(
          _timeoutClosed(until: testNow.subtract(const Duration(minutes: 1))),
        ),
        goTo: AppRoutes.riderHome,
      );
      await pumpFor(tester);
      expect(byKey('job.late'), findsNothing);
      expect(
        find.descendant(
          of: byKey('job.status.completed'),
          matching: find.text('Completed, payment not confirmed'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('order detail offers Not paid, then shows the review state', (
      tester,
    ) async {
      final riderRepo = FakeRiderRepository(
        profile: riderProfileFixture(online: true),
      )..job = _timeoutClosed(until: testNow.add(const Duration(hours: 1)));
      final orders = FakeOrdersRepository()
        ..fixedDetails['order-9'] = OrderDetails(
          order: _timeoutClosed(until: testNow.add(const Duration(hours: 1))),
          senderName: 'Grace W.',
        );
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: riderRepo,
        orders: orders,
        goTo: AppRoutes.orderDetailFor('order-9', asRider: true),
      );
      expect(byKey('status.completed'), findsOneWidget);
      expect(find.text('Completed, payment not confirmed'), findsWidgets);
      expect(byKey('orderDetail.late'), findsOneWidget);

      await tap(tester, 'orderDetail.late.notPaid');
      orders.fixedDetails['order-9'] = OrderDetails(
        order: jobFixture(status: 'unresolved'),
        senderName: 'Grace W.',
      );
      await tap(tester, 'orderDetail.late.dialog.yes');
      await tester.pumpAndSettle();
      expect(riderRepo.jobCalls, ['payment/not-received']);
      // The unresolved order now also shows the rider's settle card below; back to the top.
      await tester.drag(find.byType(Scrollable).last, const Offset(0, 2000));
      await tester.pumpAndSettle();
      expect(byKey('status.unresolved'), findsOneWidget);
      expect(byKey('orderDetail.unresolvedRider'), findsOneWidget);
      expect(byKey('orderDetail.late'), findsNothing);
    });

    testWidgets('the sender never gets Not paid on a timeout-closed order', (
      tester,
    ) async {
      final orders = FakeOrdersRepository()
        ..fixedDetails['order-9'] = OrderDetails(
          order: _timeoutClosed(until: testNow.add(const Duration(hours: 1))),
        );
      await pumpBookingApp(
        tester,
        orders: orders,
        clock: () => testNow,
        goTo: AppRoutes.orderDetailFor('order-9'),
      );
      expect(find.text('Completed, payment not confirmed'), findsOneWidget);
      expect(byKey('orderDetail.late'), findsNothing);
    });
  });

  group('payment timeout: sender tracking', () {
    testWidgets('a timeout-closed order says payment was not confirmed', (
      tester,
    ) async {
      await pumpBookingApp(
        tester,
        repo: FakeBookingRepository()..order = _timeoutClosed(),
        clock: () => testNow,
        goTo: AppRoutes.trackingFor('order-9'),
        extra: const TrackingArgs(riderId: 'rider-1', riderName: 'Moses O.'),
      );
      expect(byKey('tracking.unconfirmed'), findsOneWidget);
    });

    testWidgets('realtime completion without the outcome reloads the order', (
      tester,
    ) async {
      final booking = FakeBookingRepository()
        ..order = jobFixture(status: 'payment_requested');
      final orders = FakeOrdersRepository();
      final h = await pumpBookingApp(
        tester,
        repo: booking,
        orders: orders,
        clock: () => testNow,
        goTo: AppRoutes.trackingFor('order-9'),
        extra: const TrackingArgs(riderId: 'rider-1', riderName: 'Moses O.'),
      );
      expect(byKey('tracking.unconfirmed'), findsNothing);
      booking.order = _timeoutClosed();
      h.emit('order.updated', {'order_id': 'order-9', 'status': 'completed'});
      await tester.pumpAndSettle();
      expect(byKey('tracking.unconfirmed'), findsOneWidget);
    });
  });
}
