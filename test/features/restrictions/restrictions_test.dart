import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ridelink/core/api/api_exception.dart';
import 'package:ridelink/core/errors/error_messages.dart';
import 'package:ridelink/core/push/push_payload.dart';
import 'package:ridelink/core/routing/app_router.dart';
import 'package:ridelink/features/booking/data/booking_models.dart';
import 'package:ridelink/features/notifications/data/notification_repository.dart';
import 'package:ridelink/features/notifications/notification_text.dart';
import 'package:ridelink/features/orders/data/order_models.dart';
import 'package:ridelink/features/orders/order_labels.dart';
import 'package:ridelink/features/payments/data/payment_models.dart';
import 'package:ridelink/features/restrictions/data/restriction_models.dart';
import 'package:ridelink/features/restrictions/restriction_labels.dart';
import 'package:ridelink/l10n/app_localizations.dart';

import '../../support/booking_fakes.dart';

const _sendMoney = PaymentMethod(
  type: PayMethod.mpesaSendMoney,
  number: '+254712345678',
  accountName: 'Moses Otieno',
);

OutstandingBalance _balance({DateTime? claimedAt}) => OutstandingBalance(
  orderId: 'order-1',
  amount: 350,
  riderFirstName: 'Moses',
  cash: true,
  methods: const [_sendMoney],
  claimedAt: claimedAt,
);

AppNotification _notif(String type, [Map<String, dynamic> data = const {}]) =>
    AppNotification(
      id: 'n-1',
      type: type,
      title: 'server title',
      body: 'server body',
      data: data,
    );

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('en');
    await initializeDateFormatting('sw');
  });
  final en = lookupAppLocalizations(const Locale('en'));
  final sw = lookupAppLocalizations(const Locale('sw'));

  Finder byKey(String k) => find.byKey(Key(k));

  group('models', () {
    test('account status: suspension, appeal, strikes', () {
      final s = AccountStatus.fromJson({
        'suspended': true,
        'until': '2026-10-31T12:00:00Z',
        'reason': 'repeated_non_payment',
        'message': 'Two unpaid orders this month',
        'appeal': {'status': 'none', 'can_appeal': true},
        'strikes': [
          {
            'id': 's-1',
            'order_id': 'order-1',
            'reason': 'non_payment',
            'issued_at': '2026-10-01T08:00:00Z',
            'expires_at': '2026-12-30T08:00:00Z',
            'dispute': {'status': 'pending', 'can_dispute': false},
          },
          {'id': 's-2', 'reason': 'mystery'},
        ],
      });
      expect(s.suspended, isTrue);
      expect(s.effectivePhase, SuspensionPhase.active);
      expect(s.permanent, isFalse);
      expect(s.reason, SuspensionReason.repeatedNonPayment);
      expect(s.message, 'Two unpaid orders this month');
      expect(s.appeal.canAppeal, isTrue);
      expect(s.strikes, hasLength(2));
      expect(s.strikes.first.reason, StrikeReason.unpaidOrder);
      expect(s.strikes.first.dispute, DisputeStatus.pending);
      expect(s.strikes.last.reason, isNull);
      expect(s.strikes.last.orderId, isNull);
    });

    test('permanent, hold and intended phases', () {
      expect(
        AccountStatus.fromJson({'suspended': true, 'until': null}).permanent,
        isTrue,
      );
      expect(
        AccountStatus.fromJson({'suspended': true, 'reason': 'safety_incident'})
            .onHold,
        isTrue,
      );
      final intended = AccountStatus.fromJson({
        'suspended': false,
        'status': 'intended',
        'respond_by': '2026-10-26T10:00:00Z',
        'intended': {
          'duration': '30d',
          'respond_by': '2026-10-26T10:00:00Z',
          'response_submitted': false,
          'can_respond': true,
        },
      });
      expect(intended.intended, isTrue);
      expect(intended.canRespond, isTrue);
      expect(intended.respondBy, DateTime.utc(2026, 10, 26, 10));
      final responded = AccountStatus.fromJson({
        'status': 'intended',
        'intended': {'response_submitted': true, 'can_respond': false},
      });
      expect(responded.canRespond, isFalse);
      expect(responded.responseSent, isTrue);
      final waiting = AccountStatus.fromJson({
        'suspended': true,
        'status': 'waiting',
        'until': null,
        'permanent': false,
        'starts_after_current_order': true,
        'reason': 'repeated_no_shows',
      });
      expect(waiting.effectivePhase, SuspensionPhase.active);
      expect(waiting.permanent, isFalse);
      expect(
        AccountStatus.fromJson({
          'suspended': true,
          'until': null,
          'permanent': true,
        }).permanent,
        isTrue,
      );
      final blocked = AccountStatus.fromSuspendedError({
        'reason': 'other',
        'until': null,
        'permanent': false,
        'starts_after_current_order': true,
      });
      expect(blocked.permanent, isFalse);
      expect(blocked.startsAfterCurrentOrder, isTrue);
      expect(
        AccountStatus.fromJson(const {}).effectivePhase,
        SuspensionPhase.none,
      );
    });

    test('balances parse flat or nested payment details', () {
      final flat = parseOutstandingBalances({
        'balances': [
          {
            'order_id': 'order-1',
            'amount': 350,
            'rider_first_name': 'Moses',
            'cash': true,
            'methods': [
              {
                'type': 'mpesa_till',
                'number': '123456',
                'account_name': 'Shop',
              },
            ],
          },
        ],
      });
      expect(flat.single.amount, 350);
      expect(flat.single.methods.single.type, PayMethod.mpesaTill);
      expect(flat.single.claimed, isFalse);
      final nested = parseOutstandingBalances([
        {
          'order_id': 'order-2',
          'amount': 200.0,
          'payment': {'cash': false, 'methods': const []},
          'claim': {
            'status': 'pending',
            'method': 'cash',
            'claimed_at': '2026-10-24T09:00:00Z',
          },
        },
      ]);
      expect(nested.single.cash, isFalse);
      expect(nested.single.claimed, isTrue);
      expect(nested.single.canClaim, isFalse);
      expect(nested.single.choices, [PayMethod.cash]);
      final rejected = parseOutstandingBalances({
        'balances': [
          {
            'order_id': 'order-3',
            'amount': 300,
            'claim': {
              'status': 'rejected',
              'claimed_at': '2026-10-24T09:00:00Z',
            },
          },
        ],
      }).single;
      expect(rejected.claimed, isFalse);
      expect(rejected.claimRejected, isTrue);
      expect(rejected.canClaim, isFalse);
    });

    test('paid claim JSON omits empty extras', () {
      expect(const PaidClaim(method: PayMethod.cash).toJson(), {
        'method': 'cash',
      });
      expect(
        const PaidClaim(
          method: PayMethod.mpesaTill,
          mpesaCode: 'QAB1CD2EF3',
        ).toJson(),
        {'method': 'mpesa_till', 'mpesa_code': 'QAB1CD2EF3'},
      );
    });

    test('order detail reads the open-balance flag', () {
      final d = OrderDetails.fromJson({
        'id': 'order-1',
        'status': 'closed_unpaid',
        'balance_status': 'open',
      });
      expect(d.balanceOpen, isTrue);
      expect(d.order.isTerminal, isTrue);
      expect(
        OrderDetails.fromJson({'id': 'o', 'status': 'closed_unpaid'})
            .balanceOpen,
        isFalse,
      );
    });
  });

  group('copy', () {
    test('suspension summary per phase (EN)', () {
      final until = AccountStatus(
        suspended: true,
        until: DateTime(2026, 10, 31, 12),
        reason: SuspensionReason.strikes,
      );
      expect(
        suspensionSummary(en, until),
        'Your account is suspended until Oct 31 12:00. Reason: Repeated warnings.',
      );
      expect(
        suspensionSummary(
          en,
          const AccountStatus(
            suspended: true,
            reason: SuspensionReason.other,
            message: 'Please contact us',
          ),
        ),
        'Your account is suspended permanently. Reason: Other. Please contact us.',
      );
      expect(
        suspensionSummary(
          en,
          const AccountStatus(
            suspended: true,
            reason: SuspensionReason.fraudOrFakeDocuments,
          ),
        ),
        'Your account is on hold pending review. Reason: Fraud or fake documents.',
      );
      expect(
        suspensionSummary(
          en,
          AccountStatus(
            suspended: false,
            phase: SuspensionPhase.intended,
            reason: SuspensionReason.repeatedNoShows,
            message: 'Five no-shows in a week.',
            respondBy: DateTime(2026, 10, 26, 10),
          ),
        ),
        'RideLink intends to suspend your account. Reason: Repeated no-shows '
        'or cancellations. Five no-shows in a week. You can respond until Oct 26 10:00.',
      );
      expect(
        suspensionSummary(
          en,
          const AccountStatus(
            suspended: true,
            reason: SuspensionReason.repeatedNoShows,
            permanentFlag: false,
            startsAfterCurrentOrder: true,
          ),
        ),
        'Your account will be suspended when your current order ends. '
        'Reason: Repeated no-shows or cancellations.',
      );
    });

    test('every reason category has EN and SW text', () {
      for (final r in SuspensionReason.values) {
        expect(suspensionReasonText(en, r), isNotEmpty);
        expect(suspensionReasonText(sw, r), isNotEmpty);
      }
      expect(
        suspensionReasonText(en, SuspensionReason.harassmentOrAbuse),
        'Harassment or abuse',
      );
    });

    test('closed_unpaid status label', () {
      final o = Order.fromJson({'id': 'o', 'status': 'closed_unpaid'});
      expect(orderStatusLabel(en, o), 'Closed, unpaid');
      expect(orderStatusLabel(sw, o), isNot('Closed, unpaid'));
    });

    test('M6 error codes are localized', () {
      expect(
        apiErrorText(
          const ApiException(
            statusCode: 409,
            code: 'outstanding_balance',
            message: 'x',
          ),
          en,
        ),
        en.errCodeOutstandingBalance,
      );
      expect(
        errorCodeMessage('account_suspended', sw),
        sw.errCodeAccountSuspended,
      );
    });

    test('notification copy for the M6 kinds', () {
      expect(
        notificationText(_notif('balance_created', {'amount': 350}), en).body,
        'You owe your rider KES 350 for this order.',
      );
      expect(
        notificationText(_notif('strike_issued'), en).body,
        'You received a warning on this order.',
      );
      expect(
        notificationText(
          _notif('appeal_decided', {'decision': 'lifted'}),
          en,
        ).body,
        en.appealLifted,
      );
      expect(
        notificationText(
          _notif('account_suspended', {'reason': 'safety_incident'}),
          en,
        ).title,
        'Account on hold',
      );
      expect(
        notificationText(_notif('account_suspended'), en).body,
        en.notifAccountSuspendedBody,
      );
      expect(
        notificationText(_notif('balance_claim_received'), en).body,
        'Your customer says they paid for this order. Please confirm.',
      );
      for (final t in [
        'payment_ruled',
        'balance_settled',
        'suspension_intended',
        'suspension_lifted',
        'strike_dispute_decided',
      ]) {
        expect(notificationText(_notif(t), sw).title, isNot('server title'));
      }
    });

    test('account notices route to the account screens', () {
      expect(accountScreenFor('account_suspended'), AppRoutes.accountStatus);
      expect(accountScreenFor('strike_issued'), AppRoutes.accountStatus);
      expect(accountScreenFor('balance_created'), AppRoutes.settleBalance);
      expect(accountScreenFor('payment_ruled'), isNull);
      expect(riderPushTypes, contains('balance_claim_received'));
    });
  });

  group('sender', () {
    testWidgets('home shows the balance banner and opens the settle screen', (
      tester,
    ) async {
      final r = FakeRestrictionsRepository()..balances = [_balance()];
      await pumpBookingApp(tester, restrictions: r);
      expect(byKey('home.balance'), findsOneWidget);
      expect(
        find.text('You owe KES 350. Pay your rider to book again.'),
        findsOneWidget,
      );
      await tapKeyAndSettle(tester, 'home.balance');
      expect(byKey('screen.settleBalance'), findsOneWidget);
      expect(byKey('balance.order-1.amount'), findsOneWidget);
      expect(find.text('KES 350'), findsOneWidget);
      expect(find.text('You owe Moses for this order'), findsOneWidget);
      expect(find.text('0712 345 678'), findsOneWidget);
      expect(
        find.text('Waiting for your rider to confirm the payment'),
        findsOneWidget,
      );
    });

    testWidgets('copy puts the local mobile number on the clipboard', (
      tester,
    ) async {
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
      final r = FakeRestrictionsRepository()..balances = [_balance()];
      await pumpBookingApp(
        tester,
        restrictions: r,
        goTo: AppRoutes.settleBalance,
      );
      await tapKeyAndSettle(tester, 'balance.order-1.copy.mpesa_send_money');
      expect(copied, '0712345678');
    });

    testWidgets("I've paid sends method and code, then shows the review note", (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final r = FakeRestrictionsRepository()..balances = [_balance()];
      await pumpBookingApp(
        tester,
        restrictions: r,
        goTo: AppRoutes.settleBalance,
      );
      await tapKeyAndSettle(tester, 'balance.order-1.iPaid');
      expect(byKey('balance.order-1.claimNote'), findsOneWidget);
      await tapKeyAndSettle(tester, 'balance.order-1.claim.mpesa_send_money');
      await tester.enterText(
        find.descendant(
          of: byKey('balance.order-1.claimCode'),
          matching: find.byType(TextField),
        ),
        'abc',
      );
      await tapKeyAndSettle(tester, 'balance.order-1.claimSubmit');
      expect(find.text(en.mpesaCodeInvalid), findsOneWidget);
      expect(r.claims, isEmpty);

      await tester.enterText(
        find.descendant(
          of: byKey('balance.order-1.claimCode'),
          matching: find.byType(TextField),
        ),
        'qab1cd2ef3',
      );
      await tapKeyAndSettle(tester, 'balance.order-1.claimSubmit');
      expect(r.claims.single.orderId, 'order-1');
      expect(r.claims.single.claim.toJson(), {
        'method': 'mpesa_send_money',
        'mpesa_code': 'QAB1CD2EF3',
      });
      expect(byKey('balance.order-1.claimed'), findsOneWidget);
      expect(
        find.text(
          "We've asked your rider to confirm. RideLink will review if they don't respond.",
        ),
        findsOneWidget,
      );
      expect(byKey('balance.order-1.iPaid'), findsNothing);
    });

    testWidgets('cash claim sends the optional note', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final r = FakeRestrictionsRepository()..balances = [_balance()];
      await pumpBookingApp(
        tester,
        restrictions: r,
        goTo: AppRoutes.settleBalance,
      );
      await tapKeyAndSettle(tester, 'balance.order-1.iPaid');
      await tester.enterText(
        byKey('balance.order-1.claimNote'),
        ' Paid at the gate ',
      );
      await tapKeyAndSettle(tester, 'balance.order-1.claimSubmit');
      expect(r.claims.single.claim.toJson(), {
        'method': 'cash',
        'note': 'Paid at the gate',
      });
    });

    testWidgets('a rejected claim is not offered again', (tester) async {
      final r = FakeRestrictionsRepository()
        ..balances = [
          OutstandingBalance(
            orderId: 'order-1',
            amount: 350,
            riderFirstName: 'Moses',
            cash: true,
            methods: const [_sendMoney],
            claimedAt: DateTime(2026, 10, 24, 9),
            claimRejected: true,
          ),
        ];
      await pumpBookingApp(
        tester,
        restrictions: r,
        goTo: AppRoutes.settleBalance,
      );
      expect(byKey('balance.order-1.iPaid'), findsNothing);
      expect(byKey('balance.order-1.claimed'), findsNothing);
      expect(
        find.text('Waiting for your rider to confirm the payment'),
        findsOneWidget,
      );
    });

    testWidgets('a settled balance shows the settled state', (tester) async {
      await pumpBookingApp(tester, goTo: AppRoutes.settleBalance);
      expect(byKey('balance.settled'), findsOneWidget);
      expect(find.text('Balance settled'), findsOneWidget);
    });

    testWidgets('409 outstanding_balance on booking opens the settle screen', (
      tester,
    ) async {
      final repo = FakeBookingRepository()
        ..createError = const ApiException(
          statusCode: 409,
          code: 'outstanding_balance',
          message: 'x',
        );
      final r = FakeRestrictionsRepository()..balances = [_balance()];
      await pumpBookingApp(
        tester,
        repo: repo,
        restrictions: r,
        goTo: AppRoutes.newOrderFor(ServiceType.ride),
      );
      await _pickPlace(tester, 'route.pickup', 'West', 'p-westlands');
      await _pickPlace(tester, 'route.dropoff', 'Moi', 'p-cbd');
      await tapKeyAndSettle(tester, 'order.submit');
      await tapKeyAndSettle(tester, 'confirmPickup.confirm');
      expect(byKey('screen.settleBalance'), findsOneWidget);
    });

    testWidgets('403 account_suspended on booking opens the status screen', (
      tester,
    ) async {
      final repo = FakeBookingRepository()
        ..createError = const ApiException(
          statusCode: 403,
          code: 'account_suspended',
          message: 'x',
        );
      await pumpBookingApp(
        tester,
        repo: repo,
        goTo: AppRoutes.newOrderFor(ServiceType.ride),
      );
      await _pickPlace(tester, 'route.pickup', 'West', 'p-westlands');
      await _pickPlace(tester, 'route.dropoff', 'Moi', 'p-cbd');
      await tapKeyAndSettle(tester, 'order.submit');
      await tapKeyAndSettle(tester, 'confirmPickup.confirm');
      expect(byKey('screen.accountStatus'), findsOneWidget);
    });

    testWidgets('receiver pays shows the P6 disclosure', (tester) async {
      await pumpBookingApp(
        tester,
        goTo: AppRoutes.newOrderFor(ServiceType.delivery),
      );
      expect(byKey('order.receiverPaysNote'), findsNothing);
      await tapKeyAndSettle(tester, 'order.payer.receiver');
      expect(
        find.text('If your receiver doesn\'t pay, you will owe the rider.'),
        findsOneWidget,
      );
    });

    testWidgets('suspended home disables booking and shows the notice', (
      tester,
    ) async {
      final r = FakeRestrictionsRepository()
        ..status = AccountStatus(
          suspended: true,
          until: DateTime(2026, 10, 31, 12),
          reason: SuspensionReason.repeatedNonPayment,
          appeal: const AppealState(canAppeal: true),
        );
      await pumpBookingApp(tester, restrictions: r);
      expect(byKey('home.suspended'), findsOneWidget);
      await tester.tap(byKey('home.service.ride'));
      await tester.pumpAndSettle();
      expect(byKey('screen.newOrder'), findsNothing);
      await tapKeyAndSettle(tester, 'home.suspended.details');
      expect(byKey('screen.accountStatus'), findsOneWidget);
    });
  });

  group('account status', () {
    testWidgets('one-time appeal, then the pending state', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final r = FakeRestrictionsRepository()
        ..status = AccountStatus(
          suspended: true,
          until: DateTime(2026, 10, 31, 12),
          reason: SuspensionReason.strikes,
          appeal: const AppealState(canAppeal: true),
        )
        ..statusAfterSend = AccountStatus(
          suspended: true,
          until: DateTime(2026, 10, 31, 12),
          reason: SuspensionReason.strikes,
          appeal: const AppealState(status: AppealStatus.pending),
        );
      await pumpBookingApp(
        tester,
        restrictions: r,
        goTo: AppRoutes.accountStatus,
      );
      expect(find.text('You can appeal.'), findsOneWidget);
      await tapKeyAndSettle(tester, 'account.appeal.submit');
      expect(find.text('Write your appeal'), findsOneWidget);
      expect(r.appeals, isEmpty);
      await tester.enterText(byKey('account.appeal.message'), ' I paid. ');
      await tapKeyAndSettle(tester, 'account.appeal.submit');
      expect(r.appeals, ['I paid.']);
      expect(byKey('account.appeal.pending'), findsOneWidget);
      expect(byKey('account.appealForm'), findsNothing);
    });

    testWidgets('intended suspension takes one response', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final r = FakeRestrictionsRepository()
        ..status = AccountStatus(
          suspended: false,
          phase: SuspensionPhase.intended,
          reason: SuspensionReason.repeatedNoShows,
          respondBy: DateTime(2026, 10, 26, 10),
          canRespond: true,
        )
        ..statusAfterSend = const AccountStatus(
          suspended: false,
          phase: SuspensionPhase.intended,
          reason: SuspensionReason.repeatedNoShows,
          responseSent: true,
        );
      await pumpBookingApp(
        tester,
        restrictions: r,
        goTo: AppRoutes.accountStatus,
      );
      expect(byKey('account.intended'), findsOneWidget);
      expect(find.text('Suspension notice'), findsOneWidget);
      expect(byKey('account.appealForm'), findsNothing);
      await tester.enterText(byKey('account.response.message'), 'I was ill');
      await tapKeyAndSettle(tester, 'account.response.submit');
      expect(r.responses, ['I was ill']);
      expect(byKey('account.responseSent'), findsOneWidget);
    });

    testWidgets('standing lists warnings and takes a dispute', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final strike = Strike(
        id: 's-1',
        orderId: 'order-1',
        reason: StrikeReason.falsePaymentReport,
        issuedAt: DateTime(2026, 10, 20),
        expiresAt: DateTime(2027, 1, 18),
        canDispute: true,
      );
      final r = FakeRestrictionsRepository()
        ..status = AccountStatus(suspended: false, strikes: [strike])
        ..statusAfterSend = AccountStatus(
          suspended: false,
          strikes: [
            Strike(
              id: 's-1',
              orderId: 'order-1',
              reason: StrikeReason.falsePaymentReport,
              issuedAt: DateTime(2026, 10, 20),
              expiresAt: DateTime(2027, 1, 18),
              dispute: DisputeStatus.pending,
            ),
          ],
        );
      await pumpBookingApp(
        tester,
        restrictions: r,
        goTo: AppRoutes.accountStatus,
      );
      expect(byKey('account.active'), findsOneWidget);
      expect(
        find.text('3 warnings in 90 days can lead to a 7-day suspension.'),
        findsOneWidget,
      );
      expect(find.text('Payment report not upheld'), findsOneWidget);
      expect(
        find.text('Issued Oct 20, 2026 · Expires Jan 18, 2027'),
        findsOneWidget,
      );
      await tapKeyAndSettle(tester, 'account.strike.s-1.disputeOpen');
      await tester.enterText(
        byKey('account.strike.s-1.dispute.message'),
        'They never paid',
      );
      await tapKeyAndSettle(tester, 'account.strike.s-1.dispute.submit');
      expect(r.disputes.single.strikeId, 's-1');
      expect(byKey('account.strike.s-1.dispute.pending'), findsOneWidget);
    });

    testWidgets('no warnings', (tester) async {
      await pumpBookingApp(tester, goTo: AppRoutes.accountStatus);
      expect(byKey('account.noStrikes'), findsOneWidget);
    });
  });

  group('rider', () {
    testWidgets('unresolved order: Payment received completes it', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final riderRepo = FakeRiderRepository();
      final orders = FakeOrdersRepository()
        ..fixedDetails['order-9'] = OrderDetails(
          order: jobFixture(status: 'unresolved'),
          senderName: 'Grace W.',
        );
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: riderRepo,
        orders: orders,
        goTo: AppRoutes.orderDetailFor('order-9', asRider: true),
      );
      expect(byKey('orderDetail.settle'), findsOneWidget);
      expect(byKey('orderDetail.settle.forgive'), findsNothing);
      await tapKeyAndSettle(tester, 'orderDetail.settle.submit');
      expect(riderRepo.receivedCalls.single.method, PayMethod.cash);
    });

    testWidgets('closed_unpaid with an open balance: settle or forgive', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final r = FakeRestrictionsRepository();
      final orders = FakeOrdersRepository()
        ..fixedDetails['order-9'] = OrderDetails(
          order: jobFixture(status: 'closed_unpaid'),
          senderName: 'Grace W.',
          balanceOpen: true,
        );
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        orders: orders,
        restrictions: r,
        goTo: AppRoutes.orderDetailFor('order-9', asRider: true),
      );
      expect(byKey('status.closed_unpaid'), findsOneWidget);
      expect(find.text('Closed, unpaid'), findsWidgets);
      expect(byKey('orderDetail.settle'), findsOneWidget);
      await tapKeyAndSettle(tester, 'orderDetail.settle.forgive');
      expect(byKey('orderDetail.settle.forgiveDialog'), findsOneWidget);
      orders.fixedDetails['order-9'] = OrderDetails(
        order: jobFixture(status: 'closed_unpaid'),
        senderName: 'Grace W.',
      );
      await tapKeyAndSettle(tester, 'orderDetail.settle.forgiveDialog.yes');
      expect(r.forgiven, ['order-9']);
      expect(byKey('orderDetail.settle'), findsNothing);
    });

    testWidgets('closed_unpaid without a balance offers nothing', (
      tester,
    ) async {
      final orders = FakeOrdersRepository()
        ..fixedDetails['order-9'] = OrderDetails(
          order: jobFixture(status: 'closed_unpaid'),
          senderName: 'Grace W.',
        );
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        orders: orders,
        goTo: AppRoutes.orderDetailFor('order-9', asRider: true),
      );
      expect(byKey('orderDetail.settle'), findsNothing);
    });

    testWidgets('suspended rider: toggle disabled, notice shown', (
      tester,
    ) async {
      final r = FakeRestrictionsRepository()
        ..status = const AccountStatus(
          suspended: true,
          reason: SuspensionReason.safetyIncident,
        );
      final riderRepo = FakeRiderRepository();
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: riderRepo,
        restrictions: r,
        goTo: AppRoutes.riderHome,
      );
      expect(byKey('riderHome.suspended'), findsOneWidget);
      expect(find.text('Account on hold'), findsOneWidget);
      final toggle = tester.widget<Switch>(byKey('riderHome.onlineSwitch'));
      expect(toggle.onChanged, isNull);
      expect(riderRepo.onlineCalls, isEmpty);
    });

    testWidgets('403 account_suspended when going online shows the block', (
      tester,
    ) async {
      final riderRepo = FakeRiderRepository()
        ..onlineError = ApiException(
          statusCode: 403,
          code: 'account_suspended',
          message: 'x',
          body: {
            'code': 'account_suspended',
            'until': DateTime.utc(2026, 10, 31, 12).toIso8601String(),
            'reason': 'repeated_no_shows',
          },
        );
      await pumpBookingApp(
        tester,
        clock: () => testNow,
        riderRepo: riderRepo,
        goTo: AppRoutes.riderHome,
      );
      await tapKeyAndSettle(tester, 'riderHome.onlineSwitch');
      expect(byKey('riderHome.block.suspended'), findsOneWidget);
      expect(
        find.textContaining('Reason: Repeated no-shows or cancellations.'),
        findsOneWidget,
      );
    });
  });
}

Future<void> _pickPlace(
  WidgetTester tester,
  String fieldKey,
  String query,
  String placeId,
) async {
  await tapKeyAndSettle(tester, fieldKey);
  await tester.enterText(find.byKey(const Key('placeSearch.input')), query);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key('placeSearch.result.$placeId')));
  await tester.pumpAndSettle();
}
