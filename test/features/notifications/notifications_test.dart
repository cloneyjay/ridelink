import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ridelink/core/routing/app_router.dart';
import 'package:ridelink/features/booking/data/booking_models.dart';
import 'package:ridelink/features/notifications/data/notification_repository.dart';
import 'package:ridelink/features/notifications/notification_text.dart';
import 'package:ridelink/features/orders/data/order_models.dart';
import 'package:ridelink/l10n/app_localizations.dart';

import '../../support/booking_fakes.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('en');
    await initializeDateFormatting('sw');
  });

  Finder byKey(String k) => find.byKey(Key(k));
  final en = lookupAppLocalizations(const Locale('en'));
  final sw = lookupAppLocalizations(const Locale('sw'));

  group('localized text by type', () {
    const types = {
      'payment_requested': {'order_id': 'o', 'amount': 350},
      'payment_sent': {'order_id': 'o', 'amount': 350},
      'payment_confirmed': {'order_id': 'o', 'amount': 350},
      'payment_unresolved': {'order_id': 'o', 'amount': 350},
      'pickup_arrived': {'order_id': 'o'},
      'pickup_timeout': {'order_id': 'o'},
      'pickup_timeout_rider': {'order_id': 'o'},
      'receiver_location_shared': {'order_id': 'o'},
      'document_expiring': {
        'doc_type': 'psv_insurance',
        'expires_on': '2026-10-20',
        'days_left': 7,
      },
      'document_expired': {
        'doc_type': 'police_clearance',
        'expired_on': '2026-10-01',
      },
    };

    test('every known type renders its own EN and SW text', () {
      for (final entry in types.entries) {
        final n = notificationFixture(type: entry.key, data: entry.value);
        for (final l in [en, sw]) {
          final text = notificationText(n, l);
          expect(text.title, isNot('Server title'), reason: entry.key);
          expect(text.body, isNot('Server body'), reason: entry.key);
        }
      }
    });

    test('amounts and documents are filled in', () {
      final pay = notificationText(
        notificationFixture(data: const {'order_id': 'o', 'amount': 350}),
        en,
      );
      expect(pay.body, en.notifPaymentRequestedBody('KES 350'));
      final doc = notificationText(
        notificationFixture(
          type: 'document_expiring',
          data: const {
            'doc_type': 'psv_insurance',
            'expires_on': '2026-10-20',
            'days_left': 1,
          },
        ),
        en,
      );
      expect(doc.title, en.notifDocumentExpiringTitle(en.docPsvInsurance, 1));
    });

    test('unknown types and missing data fall back to the server text', () {
      final unknown = notificationText(
        notificationFixture(type: 'brand_new_type'),
        sw,
      );
      expect(unknown, (title: 'Server title', body: 'Server body'));
      final partial = notificationText(
        notificationFixture(type: 'document_expired', data: const {}),
        en,
      );
      expect(partial.title, 'Server title');
    });

    test('realtime payloads parse like list rows', () {
      final n = AppNotification.fromJson({
        'id': 'n-9',
        'type': 'pickup_arrived',
        'title': 't',
        'body': 'b',
        'data': {'order_id': 'order-3'},
        'created_at': '2026-10-13T09:40:00Z',
      });
      expect(n.orderId, 'order-3');
      expect(n.isRead, isFalse);
    });
  });

  group('notifications screen', () {
    FakeNotificationRepository withItems() =>
        FakeNotificationRepository()
          ..items = [
            notificationFixture(id: 'n-1'),
            notificationFixture(
              id: 'n-2',
              type: 'brand_new_type',
              title: 'Fresh server title',
              orderId: null,
              data: const {},
            ),
            notificationFixture(id: 'n-3', type: 'pickup_arrived', read: true),
          ];

    testWidgets('bell shows the unread count; realtime adds to it', (
      tester,
    ) async {
      final h = await pumpBookingApp(tester, notifications: withItems());
      expect(byKey('notifications.bell'), findsOneWidget);
      expect(tester.widget<Text>(byKey('notifications.badge.count')).data, '2');
      h.emit('notification.created', {
        'id': 'n-4',
        'order_id': 'order-9',
        'type': 'payment_confirmed',
        'title': 'Payment confirmed',
        'body': 'x',
        'data': {'order_id': 'order-9', 'amount': 214},
        'created_at': '2026-10-13T09:50:00Z',
      });
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(byKey('notifications.badge.count')).data, '3');

      await tapKeyAndSettle(tester, 'notifications.bell');
      final l = l10nOf(tester);
      expect(byKey('screen.notifications'), findsOneWidget);
      expect(find.text(l.notifPaymentConfirmedBody), findsOneWidget);
      expect(find.text(l.notifPaymentRequestedBody('KES 214')), findsOneWidget);
      expect(find.text('Fresh server title'), findsOneWidget);
      expect(byKey('notification.n-3.unread'), findsNothing);
      expect(byKey('notification.n-1.unread'), findsOneWidget);
    });

    testWidgets('tapping marks read and deep-links to live tracking', (
      tester,
    ) async {
      final h = await pumpBookingApp(
        tester,
        repo: FakeBookingRepository()
          ..order = jobFixture(status: 'payment_requested'),
        notifications: withItems(),
        clock: () => testNow,
        goTo: AppRoutes.notifications,
      );
      await tapKeyAndSettle(tester, 'notification.n-1');
      expect(h.notifications.readCalls, ['n-1']);
      expect(byKey('screen.tracking'), findsOneWidget);
    });

    testWidgets("a rider's live order opens the rider side", (tester) async {
      final orders = FakeOrdersRepository()
        ..fixedDetails['order-9'] = OrderDetails(
          order: jobFixture(status: 'cash_pending'),
          senderName: 'Grace W.',
        );
      await pumpBookingApp(
        tester,
        orders: orders,
        notifications: withItems(),
        clock: () => testNow,
        goTo: AppRoutes.notifications,
      );
      await tapKeyAndSettle(tester, 'notification.n-1');
      expect(byKey('screen.riderHome'), findsWidgets);
    });

    testWidgets('a finished order opens its history detail', (tester) async {
      await pumpBookingApp(
        tester,
        repo: FakeBookingRepository()
          ..order = Order(
            id: 'order-9',
            serviceType: ServiceType.delivery,
            status: 'completed',
            pickupAddress: 'A',
            dropoffAddress: 'B',
            senderId: testUserId,
            agreedPrice: 214,
          ),
        notifications: withItems(),
        goTo: AppRoutes.notifications,
      );
      await tapKeyAndSettle(tester, 'notification.n-3');
      expect(byKey('screen.orderDetail'), findsOneWidget);
    });

    testWidgets('document notices open the documents screen', (tester) async {
      final repo = FakeNotificationRepository()
        ..items = [
          notificationFixture(
            id: 'd-1',
            type: 'document_expired',
            orderId: null,
            data: const {
              'doc_type': 'psv_insurance',
              'expired_on': '2026-10-01',
            },
          ),
        ];
      await pumpBookingApp(
        tester,
        notifications: repo,
        goTo: AppRoutes.notifications,
      );
      final l = l10nOf(tester);
      expect(
        find.text(l.notifDocumentExpiredTitle(l.docPsvInsurance)),
        findsOneWidget,
      );
      await tapKeyAndSettle(tester, 'notification.d-1');
      expect(repo.readCalls, ['d-1']);
      expect(byKey('screen.riderDocuments'), findsOneWidget);
    });

    testWidgets('empty and failed states', (tester) async {
      final repo = FakeNotificationRepository()
        ..listError = apiError(500, 'internal_error');
      await pumpBookingApp(
        tester,
        notifications: repo,
        goTo: AppRoutes.notifications,
      );
      expect(byKey('notifications.error'), findsOneWidget);
      repo.listError = null;
      await tapKeyAndSettle(tester, 'notifications.retry');
      expect(byKey('notifications.empty'), findsOneWidget);
    });
  });
}
