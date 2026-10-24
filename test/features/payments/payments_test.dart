import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridelink/core/api/api_exception.dart';
import 'package:ridelink/core/push/push_payload.dart';
import 'package:ridelink/core/push/push_text.dart';
import 'package:ridelink/core/routing/app_router.dart';
import 'package:ridelink/features/booking/data/booking_models.dart';
import 'package:ridelink/features/evidence/evidence_record_screen.dart';
import 'package:ridelink/features/notifications/notification_text.dart';
import 'package:ridelink/features/orders/data/order_models.dart';
import 'package:ridelink/features/payments/data/payment_models.dart';
import 'package:ridelink/features/payments/payment_validation.dart';
import 'package:ridelink/features/rider/data/rider_models.dart';
import 'package:ridelink/features/tracking/tracking_screen.dart';
import 'package:ridelink/l10n/app_localizations.dart';

import '../../support/booking_fakes.dart';

const _till = PaymentMethod(
  type: PayMethod.mpesaTill,
  number: '123456',
  accountName: 'Moses Boda',
);
const _sendMoney = PaymentMethod(
  type: PayMethod.mpesaSendMoney,
  number: '+254712345678',
  accountName: 'Moses Otieno',
);

OrderPayment _payment([List<PaymentMethod> methods = const [_till]]) =>
    OrderPayment(amount: 214, currency: 'KES', cash: true, methods: methods);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Finder byKey(String k) => find.byKey(Key(k));

  Future<void> pumpFor(WidgetTester tester, [int frames = 12]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> reveal(WidgetTester tester, String key) async {
    if (byKey(key).evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        byKey(key),
        200,
        scrollable: find.byType(Scrollable).last,
      );
    }
    await tester.ensureVisible(byKey(key));
    await tester.pump();
  }

  Future<void> tap(WidgetTester tester, String key) async {
    await reveal(tester, key);
    await tester.tap(byKey(key));
    await pumpFor(tester);
  }

  Future<void> type(WidgetTester tester, String key, String text) async {
    await reveal(tester, key);
    await tester.enterText(
      find.descendant(of: byKey(key), matching: find.byType(TextField)),
      text,
    );
    await tester.pump();
  }

  bool enabled(WidgetTester tester, String key) =>
      tester
          .widget<ElevatedButton>(
            find.descendant(
              of: byKey(key),
              matching: find.byType(ElevatedButton),
            ),
          )
          .onPressed !=
      null;

  group('validation mirrors the server', () {
    test('till: digits only, 5 to 8', () {
      expect(normalizeTill(' 12345 '), '12345');
      expect(normalizeTill('12345678'), '12345678');
      expect(normalizeTill('1234'), isNull);
      expect(normalizeTill('123456789'), isNull);
      expect(normalizeTill('12a456'), isNull);
    });

    test('Kenyan mobile normalizes like internal/phone', () {
      const valid = {
        '+254712345678': '+254712345678',
        '254112345678': '+254112345678',
        '0712345678': '+254712345678',
        '0712 345 678': '+254712345678',
        '+254-712-345678': '+254712345678',
      };
      valid.forEach((raw, want) => expect(normalizeKenyanMobile(raw), want));
      for (final bad in [
        '',
        '0812345678',
        '071234567',
        '07123456789',
        '+255712345678',
        '712345678',
        '+254012345678',
      ]) {
        expect(normalizeKenyanMobile(bad), isNull, reason: bad);
      }
    });

    test('account name: trimmed, 2 to 60 characters', () {
      expect(normalizeAccountName('  Moses O  '), 'Moses O');
      expect(normalizeAccountName('M'), isNull);
      expect(normalizeAccountName('a' * 60), 'a' * 60);
      expect(normalizeAccountName('a' * 61), isNull);
    });

    test('M-Pesa code: 10 letters/digits, uppercased, M-Pesa only', () {
      expect(normalizeMpesaCode(' qab1cd2ef3 '), 'QAB1CD2EF3');
      expect(normalizeMpesaCode('QAB1CD2EF'), isNull);
      expect(normalizeMpesaCode('QAB1CD2EF3X'), isNull);
      expect(normalizeMpesaCode('QAB1CD-EF3'), isNull);
      expect(mpesaCodeFor(PayMethod.cash, 'QAB1CD2EF3'), (
        code: null,
        valid: true,
      ));
      expect(mpesaCodeFor(PayMethod.mpesaTill, ''), (code: null, valid: true));
      expect(mpesaCodeFor(PayMethod.mpesaTill, 'abc'), (
        code: null,
        valid: false,
      ));
      expect(mpesaCodeFor(PayMethod.mpesaPochi, 'qab1cd2ef3'), (
        code: 'QAB1CD2EF3',
        valid: true,
      ));
    });

    test('method input: per-type number rules and field errors', () {
      final till = validateMethodInput(PayMethod.mpesaTill, '123456', ' Mo ');
      expect(till.number, '123456');
      expect(till.accountName, 'Mo');
      expect(till.numberError, isNull);
      final pochi = validateMethodInput(
        PayMethod.mpesaPochi,
        '0712345678',
        'Moses',
      );
      expect(pochi.number, '+254712345678');
      final bad = validateMethodInput(PayMethod.mpesaSendMoney, '123456', 'M');
      expect(bad.numberError, PaymentFieldError.phoneInvalid);
      expect(bad.nameError, PaymentFieldError.nameInvalid);
      final empty = validateMethodInput(PayMethod.mpesaTill, ' ', '');
      expect(empty.numberError, PaymentFieldError.required);
      expect(empty.nameError, PaymentFieldError.required);
    });
  });

  group('models', () {
    test('order payment parses; unknown or cash method types are skipped', () {
      final p = OrderPayment.fromJson({
        'amount': 350,
        'currency': 'KES',
        'cash': true,
        'methods': [
          {
            'type': 'mpesa_send_money',
            'number': '+254712345678',
            'account_name': 'Moses',
          },
          {'type': 'bank', 'number': '1', 'account_name': 'x'},
          {'type': 'cash', 'number': '', 'account_name': ''},
          {'type': 'mpesa_till', 'number': '123456', 'account_name': 'Shop'},
        ],
      });
      expect(p.amount, 350);
      expect(p.methods.map((m) => m.type), [
        PayMethod.mpesaTill,
        PayMethod.mpesaSendMoney,
      ]);
      expect(p.choices, [
        PayMethod.cash,
        PayMethod.mpesaTill,
        PayMethod.mpesaSendMoney,
      ]);
    });

    test('payer response JSON', () {
      expect(const PayerResponse.notPaid().toJson(), {'paid': false});
      expect(const PayerResponse.paid(method: PayMethod.cash).toJson(), {
        'paid': true,
        'method': 'cash',
      });
    });

    test('notification copy for the rider-led flow', () {
      final en = lookupAppLocalizations(const Locale('en'));
      final requested = notificationText(
        notificationFixture(data: const {'order_id': 'o', 'amount': 350}),
        en,
      );
      expect(
        requested.body,
        'Your rider has arrived. Pay KES 350 by cash or M-Pesa.',
      );
      final confirmed = notificationText(
        notificationFixture(
          type: 'payment_confirmed',
          data: const {'order_id': 'o', 'amount': 350},
        ),
        en,
      );
      expect(confirmed.body, 'Payment confirmed. Your order is complete.');
      expect(
        en.notifPaymentNotPaidBody,
        'Your rider says this order was not paid. Tell us if you paid.',
      );
      expect(
        en.notifPaymentUnresolvedBody,
        'You reported this order as not paid. RideLink will review this order.',
      );
      final sw = lookupAppLocalizations(const Locale('sw'));
      for (final l in [en, sw]) {
        final answered = notificationText(
          notificationFixture(
            type: 'payer_payment_response',
            data: const {'order_id': 'o'},
          ),
          l,
        );
        expect(answered.title, l.notifPayerResponseTitle);
        expect(answered.body, l.notifPayerResponseBody);
        final push = pushText(
          const PushPayload(type: 'payer_payment_response'),
          l,
        );
        expect(push.title, l.notifPayerResponseTitle);
        final notPaid = notificationText(
          notificationFixture(
            type: 'payment_not_paid',
            data: const {'order_id': 'o'},
          ),
          l,
        );
        expect(notPaid.title, l.notifPaymentNotPaidTitle);
        expect(notPaid.body, l.notifPaymentNotPaidBody);
        expect(
          pushText(const PushPayload(type: 'payment_not_paid'), l).body,
          l.notifPaymentNotPaidBody,
        );
      }
    });

    test('method_types and payer_response parse', () {
      final p = OrderPayment.fromJson({
        'amount': 214,
        'cash': true,
        'methods': <Object>[],
        'method_types': ['mpesa_send_money', 'bank', 'mpesa_till', 'cash'],
        'payer_response': 'pending',
      });
      expect(p.methodTypes, [PayMethod.mpesaTill, PayMethod.mpesaSendMoney]);
      expect(p.payerChoices, [
        PayMethod.cash,
        PayMethod.mpesaTill,
        PayMethod.mpesaSendMoney,
      ]);
      expect(p.payerResponse, PayerResponseState.pending);
      expect(
        OrderPayment.fromJson({'payer_response': 'answered'}).payerResponse,
        PayerResponseState.answered,
      );
      expect(OrderPayment.fromJson({}).payerResponse, isNull);
    });

    test('a null amount in the payment view parses', () {
      final p = OrderPayment.fromJson({
        'amount': null,
        'currency': 'KES',
        'cash': true,
        'methods': <Object>[],
      });
      expect(p.amount, isNull);
      expect(p.choices, [PayMethod.cash]);
    });

    test('server-only evidence events have EN and SW labels', () {
      for (final l in [
        lookupAppLocalizations(const Locale('en')),
        lookupAppLocalizations(const Locale('sw')),
      ]) {
        String name(String type) =>
            evidenceEventName(l, type, ServiceType.delivery);
        expect(name('arrived'), l.statusArrived);
        expect(name('payment_received'), l.evidenceEventPaymentReceived);
        expect(name('handed_over'), l.statusHandedOver);
        expect(name('completed'), l.statusCompleted);
        expect(name('payment_not_received'), l.evidenceEventPaymentNotReceived);
        expect(name('payer_payment_response'), l.evidenceEventPayerResponse);
        expect(
          name('payment_details_viewed'),
          l.evidenceEventPaymentDetailsViewed,
        );
        expect(
          evidenceEventName(l, 'handed_over', ServiceType.ride),
          l.statusDroppedOff,
        );
      }
    });
  });

  group('rider: payment step', () {
    FakeRiderRepository withJob(
      String status, {
      ServiceType service = ServiceType.ride,
    }) {
      final job = jobFixture(
        status: status,
        arrivedAt: testNow,
        service: service,
      );
      return FakeRiderRepository(
        profile: riderProfileFixture(online: true),
        activeResult: RiderActive(order: job),
      )..job = job;
    }

    testWidgets('M-Pesa from the snapshot with an optional, validated code', (
      tester,
    ) async {
      final repo = withJob('payment_requested');
      final orders = FakeOrdersRepository()..paymentResult = _payment();
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: repo,
        orders: orders,
        goTo: AppRoutes.riderHome,
      );
      await pumpFor(tester);
      final l = l10nOf(tester);
      expect(tester.widget<Text>(byKey('job.collectAmount')).data, 'KES 214');
      expect(byKey('job.method.cash'), findsOneWidget);
      expect(byKey('job.method.mpesa_till'), findsOneWidget);
      expect(find.text('123456'), findsOneWidget);
      expect(byKey('job.mpesaCode'), findsNothing);
      // Rides have no handover photo.
      expect(byKey('evidence.handover_photo'), findsNothing);

      await tap(tester, 'job.method.mpesa_till');
      expect(byKey('job.mpesaCode'), findsOneWidget);
      await type(tester, 'job.mpesaCode', 'abc');
      await tap(tester, 'job.paymentReceived');
      expect(find.text(l.mpesaCodeInvalid), findsOneWidget);
      expect(repo.jobCalls, isEmpty);

      await type(tester, 'job.mpesaCode', 'qab1cd2ef3');
      await tap(tester, 'job.paymentReceived');
      expect(repo.jobCalls, ['payment/received']);
      expect(repo.receivedCalls.single.method, PayMethod.mpesaTill);
      expect(repo.receivedCalls.single.mpesaCode, 'QAB1CD2EF3');
      expect(byKey('job.status.completed'), findsOneWidget);
    });

    testWidgets('a failed payment view still lets the rider record cash', (
      tester,
    ) async {
      final repo = withJob('payment_requested');
      final orders = FakeOrdersRepository()
        ..paymentError = apiError(500, 'internal_error');
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: repo,
        orders: orders,
        goTo: AppRoutes.riderHome,
      );
      await pumpFor(tester);
      expect(byKey('job.methodsError'), findsOneWidget);
      expect(byKey('job.method.cash'), findsOneWidget);

      orders
        ..paymentError = null
        ..paymentResult = _payment();
      await tap(tester, 'job.methodsRetry');
      expect(byKey('job.method.mpesa_till'), findsOneWidget);

      await tap(tester, 'job.paymentReceived');
      expect(repo.receivedCalls.single.method, PayMethod.cash);
    });

    testWidgets('in transit: Arrived requests payment in one step', (
      tester,
    ) async {
      final repo = withJob('in_transit');
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: repo,
        goTo: AppRoutes.riderHome,
      );
      await tap(tester, 'job.action.arrivedAtDropoff');
      expect(repo.jobCalls, ['payment/request']);
      expect(byKey('job.collect'), findsOneWidget);
      expect(byKey('job.action.requestPayment'), findsNothing);
    });

    testWidgets('delivery: Payment received waits for the handover photo', (
      tester,
    ) async {
      final repo = withJob('payment_requested', service: ServiceType.delivery);
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: repo,
        goTo: AppRoutes.riderHome,
      );
      await reveal(tester, 'job.paymentReceived');
      expect(enabled(tester, 'job.paymentReceived'), isFalse);
      expect(byKey('job.photoRequired'), findsOneWidget);
      await tap(tester, 'evidence.handover_photo.capture');
      await reveal(tester, 'job.paymentReceived');
      expect(enabled(tester, 'job.paymentReceived'), isTrue);
    });

    testWidgets('legacy cash_pending still settles through Payment received', (
      tester,
    ) async {
      final repo = withJob('cash_pending');
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: repo,
        goTo: AppRoutes.riderHome,
      );
      await tap(tester, 'job.paymentReceived');
      expect(repo.jobCalls, ['payment/received']);
    });
  });

  group('sender: pay your rider', () {
    final args = TrackingArgs(riderId: 'rider-1', riderName: 'Moses O.');

    testWidgets(
      'shows cash and each M-Pesa method with copy, no "I\'ve paid"',
      (tester) async {
        String? copied;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              copied = (call.arguments as Map)['text'] as String?;
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        final orders = FakeOrdersRepository()
          ..paymentResult = _payment([_till, _sendMoney]);
        await pumpBookingApp(
          tester,
          repo: FakeBookingRepository()
            ..order = jobFixture(status: 'payment_requested'),
          orders: orders,
          clock: () => testNow,
          goTo: AppRoutes.trackingFor('order-9'),
          extra: args,
        );
        final l = l10nOf(tester);
        expect(byKey('tracking.payNow'), findsOneWidget);
        expect(find.text(l.payYourRiderTitle), findsOneWidget);
        expect(
          tester.widget<Text>(byKey('tracking.payAmount')).data,
          'KES 214',
        );
        expect(byKey('tracking.pay.cash'), findsOneWidget);
        expect(
          tester.widget<Text>(byKey('tracking.pay.mpesa_till.number')).data,
          '123456',
        );
        expect(find.text(l.nameInMpesa('Moses Boda')), findsOneWidget);
        expect(find.text(l.nameInMpesa('Moses Otieno')), findsOneWidget);
        expect(byKey('tracking.ivePaid'), findsNothing);

        await tapKeyAndSettle(tester, 'tracking.copy.mpesa_send_money');
        // Send Money shows "0712 345 678" and copies digits only.
        expect(find.text('0712 345 678'), findsOneWidget);
        expect(copied, '0712345678');
        expect(byKey('tracking.copied'), findsOneWidget);
      },
    );

    testWidgets('entering payment_requested via realtime fetches the details; '
        'leaving it hides them', (tester) async {
      final orders = FakeOrdersRepository()..paymentResult = _payment();
      final h = await pumpBookingApp(
        tester,
        repo: FakeBookingRepository()..order = jobFixture(status: 'in_transit'),
        orders: orders,
        clock: () => testNow,
        goTo: AppRoutes.trackingFor('order-9'),
        extra: args,
      );
      expect(orders.paymentCalls, 0);
      expect(byKey('tracking.payNow'), findsNothing);

      h.emit('order.updated', {
        'order_id': 'order-9',
        'status': 'payment_requested',
      });
      await tester.pumpAndSettle();
      expect(orders.paymentCalls, 1);
      expect(byKey('tracking.pay.mpesa_till'), findsOneWidget);

      h.emit('order.updated', {'order_id': 'order-9', 'status': 'completed'});
      await tester.pumpAndSettle();
      expect(byKey('tracking.payNow'), findsNothing);
      expect(find.text('123456'), findsNothing);
    });
  });

  group('sender: did you pay?', () {
    OrderPayment notPaid([
      PayerResponseState state = PayerResponseState.pending,
    ]) => OrderPayment(
      amount: 214,
      currency: 'KES',
      cash: true,
      methods: const [],
      methodTypes: const [PayMethod.mpesaPochi],
      payerResponse: state,
    );

    Future<BookingHarness> openUnresolved(
      WidgetTester tester, {
      FakeBookingRepository? repo,
      FakeOrdersRepository? orders,
    }) => pumpBookingApp(
      tester,
      repo: (repo ?? FakeBookingRepository())
        ..order = jobFixture(status: 'unresolved'),
      orders: orders ?? (FakeOrdersRepository()..paymentResult = notPaid()),
      clock: () => testNow,
      goTo: AppRoutes.trackingFor('order-9'),
      extra: const TrackingArgs(riderName: 'Moses O.'),
    );

    testWidgets('Yes offers cash plus the snapshot types only', (tester) async {
      await openUnresolved(tester);
      await tapKeyAndSettle(tester, 'payer.yes');
      expect(byKey('payer.method.cash'), findsOneWidget);
      expect(byKey('payer.method.mpesa_pochi'), findsOneWidget);
      expect(byKey('payer.method.mpesa_till'), findsNothing);
      expect(byKey('payer.method.mpesa_send_money'), findsNothing);
    });

    testWidgets('already answered (server) shows the thanks state', (
      tester,
    ) async {
      await openUnresolved(
        tester,
        orders: FakeOrdersRepository()
          ..paymentResult = notPaid(PayerResponseState.answered),
      );
      expect(byKey('payer.thanks'), findsOneWidget);
      expect(byKey('payer.prompt'), findsNothing);
    });

    testWidgets('not a not-paid order (422) shows nothing', (tester) async {
      await openUnresolved(
        tester,
        orders: FakeOrdersRepository()
          ..paymentError = apiError(422, 'payment_details_hidden'),
      );
      expect(byKey('payer.prompt'), findsNothing);
      expect(byKey('payer.thanks'), findsNothing);
      expect(byKey('payer.loadError'), findsNothing);
    });

    testWidgets('yes + M-Pesa method + code, submitted once', (tester) async {
      final h = await openUnresolved(tester);
      final l = l10nOf(tester);
      await reveal(tester, 'payer.submit');
      expect(enabled(tester, 'payer.submit'), isFalse);

      await tapKeyAndSettle(tester, 'payer.yes');
      await tapKeyAndSettle(tester, 'payer.method.mpesa_pochi');
      await type(tester, 'payer.code', 'short');
      await tapKeyAndSettle(tester, 'payer.submit');
      expect(find.text(l.mpesaCodeInvalid), findsOneWidget);
      expect(h.repo.payerResponses, isEmpty);

      await type(tester, 'payer.code', 'qab1cd2ef3');
      await tapKeyAndSettle(tester, 'payer.submit');
      final r = h.repo.payerResponses.single;
      expect(r.paid, isTrue);
      expect(r.method, PayMethod.mpesaPochi);
      expect(r.mpesaCode, 'QAB1CD2EF3');
      expect(byKey('payer.thanks'), findsOneWidget);
      expect(find.text(l.payerThanks), findsOneWidget);
      expect(byKey('payer.submit'), findsNothing);
    });

    testWidgets('no', (tester) async {
      final h = await openUnresolved(tester);
      await tapKeyAndSettle(tester, 'payer.no');
      expect(byKey('payer.method.cash'), findsNothing);
      await tapKeyAndSettle(tester, 'payer.submit');
      expect(h.repo.payerResponses.single.paid, isFalse);
      expect(byKey('payer.thanks'), findsOneWidget);
    });

    testWidgets('409 (already answered) shows the thanks state', (
      tester,
    ) async {
      final repo = FakeBookingRepository()
        ..payerResponseError = const ApiException(
          statusCode: 409,
          code: 'conflict',
          message: 'already answered',
        );
      await openUnresolved(tester, repo: repo);
      await tapKeyAndSettle(tester, 'payer.no');
      await tapKeyAndSettle(tester, 'payer.submit');
      expect(byKey('payer.thanks'), findsOneWidget);
    });

    testWidgets('other failures keep the prompt with an error', (tester) async {
      final repo = FakeBookingRepository()
        ..payerResponseError = apiError(500, 'internal_error');
      await openUnresolved(tester, repo: repo);
      await tapKeyAndSettle(tester, 'payer.yes');
      await tapKeyAndSettle(tester, 'payer.submit');
      expect(byKey('payer.error'), findsOneWidget);
      expect(find.text(l10nOf(tester).payerResponseFailed), findsOneWidget);
      expect(byKey('payer.prompt'), findsOneWidget);
    });

    testWidgets('the order detail (from the notification) asks too', (
      tester,
    ) async {
      final orders = FakeOrdersRepository()
        ..paymentResult = notPaid()
        ..fixedDetails['order-9'] = OrderDetails(
          order: jobFixture(status: 'unresolved'),
        );
      await pumpBookingApp(
        tester,
        orders: orders,
        clock: () => testNow,
        goTo: AppRoutes.orderDetailFor('order-9'),
      );
      expect(byKey('orderDetail.payerResponse'), findsOneWidget);
      expect(byKey('payer.prompt'), findsOneWidget);
    });

    testWidgets('the rider never sees the payer prompt', (tester) async {
      final orders = FakeOrdersRepository()
        ..fixedDetails['order-9'] = OrderDetails(
          order: jobFixture(status: 'unresolved'),
          senderName: 'Grace W.',
        );
      await pumpBookingApp(
        tester,
        orders: orders,
        clock: () => testNow,
        goTo: AppRoutes.orderDetailFor('order-9', asRider: true),
      );
      expect(byKey('screen.orderDetail'), findsOneWidget);
      expect(byKey('orderDetail.payerResponse'), findsNothing);
    });
  });

  group('rider: payment methods screen', () {
    FakeRiderRepository idle() =>
        FakeRiderRepository(profile: riderProfileFixture(online: true));

    testWidgets('opens from rider home; cash is always on, M-Pesa optional', (
      tester,
    ) async {
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: idle(),
        goTo: AppRoutes.riderHome,
      );
      await tap(tester, 'riderHome.paymentMethods');
      await tester.pumpAndSettle();
      final l = l10nOf(tester);
      expect(byKey('screen.paymentMethods'), findsOneWidget);
      expect(byKey('payMethods.cash'), findsOneWidget);
      expect(find.text(l.cashAlwaysAccepted), findsOneWidget);
      expect(byKey('payMethods.cash.remove'), findsNothing);
      for (final t in PayMethod.mpesa) {
        expect(byKey('payMethods.${t.wire}.add'), findsOneWidget);
      }
    });

    testWidgets('add validates on the client, then saves normalized values', (
      tester,
    ) async {
      final repo = idle();
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: repo,
        goTo: AppRoutes.riderPaymentMethods,
      );
      final l = l10nOf(tester);
      await tapKeyAndSettle(tester, 'payMethods.mpesa_pochi.add');
      expect(byKey('payMethods.sheet'), findsOneWidget);
      await tester.enterText(byKey('payMethods.number'), '0812345678');
      await tester.enterText(byKey('payMethods.name'), 'M');
      await tapKeyAndSettle(tester, 'payMethods.save');
      expect(find.text(l.mpesaPhoneInvalid), findsOneWidget);
      expect(find.text(l.mpesaNameInvalid), findsOneWidget);
      expect(repo.saveMethodCalls, isEmpty);

      await tester.enterText(byKey('payMethods.number'), '0712 345 678');
      await tester.enterText(byKey('payMethods.name'), '  Moses Otieno ');
      await tapKeyAndSettle(tester, 'payMethods.save');
      expect(repo.saveMethodCalls.single, (
        type: PayMethod.mpesaPochi,
        number: '+254712345678',
        accountName: 'Moses Otieno',
      ));
      expect(byKey('payMethods.sheet'), findsNothing);
      expect(byKey('payMethods.saved'), findsOneWidget);
      expect(
        tester.widget<Text>(byKey('payMethods.mpesa_pochi.number')).data,
        '0712 345 678',
      );
      expect(byKey('payMethods.mpesa_pochi.edit'), findsOneWidget);
    });

    testWidgets('till numbers must be 5 to 8 digits', (tester) async {
      final repo = idle();
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: repo,
        goTo: AppRoutes.riderPaymentMethods,
      );
      await tapKeyAndSettle(tester, 'payMethods.mpesa_till.add');
      await tester.enterText(byKey('payMethods.number'), '1234');
      await tester.enterText(byKey('payMethods.name'), 'Shop');
      await tapKeyAndSettle(tester, 'payMethods.save');
      expect(find.text(l10nOf(tester).tillNumberInvalid), findsOneWidget);
      await tester.enterText(byKey('payMethods.number'), '123456');
      await tapKeyAndSettle(tester, 'payMethods.save');
      expect(repo.saveMethodCalls.single.number, '123456');
    });

    testWidgets('edit prefills; remove asks first', (tester) async {
      final repo = idle()..methods[PayMethod.mpesaTill] = _till;
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: repo,
        goTo: AppRoutes.riderPaymentMethods,
      );
      final l = l10nOf(tester);
      expect(find.text(l.nameInMpesa('Moses Boda')), findsOneWidget);

      await tapKeyAndSettle(tester, 'payMethods.mpesa_till.edit');
      expect(
        tester.widget<TextField>(byKey('payMethods.number')).controller!.text,
        '123456',
      );
      Navigator.of(tester.element(byKey('payMethods.sheet'))).pop();
      await tester.pumpAndSettle();

      await tapKeyAndSettle(tester, 'payMethods.mpesa_till.remove');
      expect(byKey('payMethods.removeDialog'), findsOneWidget);
      await tapKeyAndSettle(tester, 'payMethods.removeDialog.no');
      expect(repo.deleteMethodCalls, isEmpty);
      await tapKeyAndSettle(tester, 'payMethods.mpesa_till.remove');
      await tapKeyAndSettle(tester, 'payMethods.removeDialog.yes');
      expect(repo.deleteMethodCalls, [PayMethod.mpesaTill]);
      expect(byKey('payMethods.mpesa_till.add'), findsOneWidget);
    });

    testWidgets('load failure offers a retry', (tester) async {
      final repo = idle()..methodsError = apiError(500, 'internal_error');
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: repo,
        goTo: AppRoutes.riderPaymentMethods,
      );
      expect(byKey('payMethods.error'), findsOneWidget);
      repo.methodsError = null;
      await tapKeyAndSettle(tester, 'payMethods.retry');
      expect(byKey('payMethods.cash'), findsOneWidget);
    });
  });
}
