import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridelink/core/auth/auth_api.dart';
import 'package:ridelink/core/auth/session.dart';
import 'package:ridelink/core/auth/session_manager.dart';
import 'package:ridelink/core/config/app_config.dart';
import 'package:ridelink/core/map/ridelink_map.dart';
import 'package:ridelink/core/mode/app_mode.dart';
import 'package:ridelink/core/navigation/url_opener.dart';
import 'package:ridelink/core/providers.dart';
import 'package:ridelink/core/push/notification_permission.dart';
import 'package:ridelink/core/push/push_navigator.dart';
import 'package:ridelink/core/push/push_payload.dart';
import 'package:ridelink/core/push/push_providers.dart';
import 'package:ridelink/core/routing/app_router.dart';
import 'package:ridelink/core/storage/local_store.dart';
import 'package:ridelink/core/version/version_gate.dart';
import 'package:ridelink/features/auth/google_auth.dart';
import 'package:ridelink/features/booking/data/booking_models.dart';
import 'package:ridelink/features/gates/app_gates.dart';
import 'package:ridelink/features/legal/legal_repository.dart';
import 'package:ridelink/features/orders/data/order_models.dart';
import 'package:ridelink/features/profile/delete_account_screen.dart';
import 'package:ridelink/features/rider/data/rider_models.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import 'package:ridelink/theme/app_theme.dart';

import '../support/auth_harness.dart';
import '../support/booking_fakes.dart';
import '../support/fakes.dart';

Finder byKey(String k) => find.byKey(Key(k));

String location(BookingHarness h) =>
    h.router.routerDelegate.currentConfiguration.uri.toString();

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('delete account', () {
    Future<BookingHarness> openDelete(
      WidgetTester tester, {
      FakeAccountRepository? account,
    }) async {
      final h = await pumpBookingApp(
        tester,
        account: account,
        riderRepo: FakeRiderRepository(registered: false),
        goTo: AppRoutes.profile,
      );
      await tapKeyAndSettle(tester, 'profile.deleteAccount');
      return h;
    }

    Future<void> typeAndConfirm(WidgetTester tester, String word) async {
      await tapKeyAndSettle(tester, 'deleteAccount.continue');
      await tester.enterText(byKey('deleteAccount.confirmField'), word);
      await tester.pump();
    }

    bool confirmEnabled(WidgetTester tester) =>
        tester.widget<TextButton>(byKey('deleteAccount.confirm')).onPressed !=
        null;

    testWidgets('explains what is deleted and what is kept', (tester) async {
      await openDelete(tester);
      final l = l10nOf(tester);
      expect(byKey('screen.deleteAccount'), findsOneWidget);
      expect(find.text(l.deleteAccountDeletedBody), findsOneWidget);
      expect(find.text(l.deleteAccountKeptBody), findsOneWidget);
    });

    testWidgets('requires typing the confirmation word', (tester) async {
      final h = await openDelete(tester);
      await typeAndConfirm(tester, 'DELET');
      expect(confirmEnabled(tester), isFalse);
      await tester.enterText(byKey('deleteAccount.confirmField'), ' delete ');
      await tester.pump();
      expect(confirmEnabled(tester), isTrue);
      await tapKeyAndSettle(tester, 'deleteAccount.keep');
      expect(h.account.deleteCalls, 0);
      expect(deleteConfirmationMatches('FUTA', 'FUTA'), isTrue);
      expect(deleteConfirmationMatches('DELETE', 'FUTA'), isFalse);
    });

    testWidgets('409 account_has_active_order is explained, still signed in', (
      tester,
    ) async {
      final account = FakeAccountRepository()
        ..deleteError = apiError(
          409,
          'account_has_active_order',
          'finish your order first',
        );
      final h = await openDelete(tester, account: account);
      await typeAndConfirm(tester, 'DELETE');
      await tapKeyAndSettle(tester, 'deleteAccount.confirm');
      expect(h.account.deleteCalls, 1);
      expect(
        find.text(l10nOf(tester).errCodeAccountHasActiveOrder),
        findsOneWidget,
      );
      expect(h.session.state, isA<SignedIn>());
    });

    testWidgets('success wipes user data, signs out and says so', (
      tester,
    ) async {
      final store = MemoryLocalStore()
        ..values['ridelink.rating_prompted'] = ['order-1']
        ..values['ridelink.notifications_asked'] = '1'
        ..values['ridelink.locale'] = 'sw';
      final modeStore = MemoryModeStore(AppMode.rider);
      final h = await pumpBookingApp(
        tester,
        store: store,
        modeStore: modeStore,
        riderRepo: FakeRiderRepository(registered: false),
        goTo: AppRoutes.profile,
      );
      await tapKeyAndSettle(tester, 'profile.deleteAccount');
      await typeAndConfirm(tester, 'DELETE');
      await tapKeyAndSettle(tester, 'deleteAccount.confirm');
      expect(h.account.deleteCalls, 1);
      expect(h.session.state, isA<SignedOut>());
      expect(byKey('screen.auth'), findsOneWidget);
      expect(byKey('auth.accountDeleted'), findsOneWidget);
      expect(find.text(l10nOf(tester).accountDeletedNotice), findsOneWidget);
      expect(store.values, {'ridelink.locale': 'sw'});
      expect(modeStore.mode, isNull);
      expect(h.mode.mode, AppMode.sender);
    });
  });

  group('terms at sign-up', () {
    testWidgets('the checkbox is required', (tester) async {
      final h = await pumpAuthApp(
        tester,
        initialLocation: AppRoutes.signUp,
        handler: routeHandler({'auth/signup': (o) => emptyResponse(202)}),
      );
      await tester.enterText(byKey('auth.firstName'), 'Moses');
      await tester.enterText(byKey('auth.lastName'), 'Otieno');
      await tester.enterText(byKey('auth.email'), 'moses@example.com');
      await tester.enterText(byKey('auth.password'), 'correcthorsebattery');
      await tapSubmit(tester);
      expect(byKey('signUp.legal.error'), findsOneWidget);
      expect(
        find.text(l10n(tester).errCodeLegalAcceptanceRequired),
        findsOneWidget,
      );
      expect(h.count('auth/signup'), 0);
    });

    testWidgets('both documents open in the browser', (tester) async {
      final h = await pumpAuthApp(
        tester,
        initialLocation: AppRoutes.signUp,
        handler: routeHandler({}),
      );
      await tapKey(tester, 'signUp.legal.terms');
      await tapKey(tester, 'signUp.legal.privacy');
      expect(h.urls.opened, [
        legalDocsFixture.terms.url,
        legalDocsFixture.privacy.url,
      ]);
    });

    testWidgets('documents that cannot be loaded block sign-up', (
      tester,
    ) async {
      final legal = FakeLegalRepository()..currentError = offlineError;
      final h = await pumpAuthApp(
        tester,
        initialLocation: AppRoutes.signUp,
        handler: routeHandler({'auth/signup': (o) => emptyResponse(202)}),
        legal: legal,
      );
      await tester.enterText(byKey('auth.firstName'), 'Moses');
      await tester.enterText(byKey('auth.lastName'), 'Otieno');
      await tester.enterText(byKey('auth.email'), 'moses@example.com');
      await tester.enterText(byKey('auth.password'), 'correcthorsebattery');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tapKey(tester, 'signUp.legal.checkbox');
      await tapSubmit(tester);
      expect(find.text(l10n(tester).errorNetwork), findsOneWidget);
      expect(h.count('auth/signup'), 0);
    });
  });

  group('terms with Google sign-in', () {
    Future<AuthHarness> pumpGoogle(
      WidgetTester tester,
      FakeHandler googleHandler,
    ) => pumpAuthApp(
      tester,
      google: FakeGoogleAuth(
        result: const GoogleCredential(idToken: 'id-1', rawNonce: 'nonce-1'),
      ),
      handler: routeHandler({'auth/google': googleHandler}),
    );

    testWidgets('ticked: the accepted versions are sent', (tester) async {
      final h = await pumpGoogle(
        tester,
        (o) => jsonResponse(200, sessionJson()),
      );
      await tapKey(tester, 'signIn.legal.checkbox');
      await tapKey(tester, 'auth.google');
      expect(h.lastBody('auth/google'), {
        'id_token': 'id-1',
        'nonce': 'nonce-1',
        'accepted_terms_version': '2026-10-01',
        'accepted_privacy_version': '2026-10-02',
      });
      expect(h.session.state, isA<SignedIn>());
    });

    testWidgets('not ticked: a new account gets legal_acceptance_required', (
      tester,
    ) async {
      final h = await pumpGoogle(
        tester,
        (o) => jsonResponse(400, {
          'error': 'accept the terms',
          'code': 'legal_acceptance_required',
        }),
      );
      await tapKey(tester, 'auth.google');
      expect(h.lastBody('auth/google'), {
        'id_token': 'id-1',
        'nonce': 'nonce-1',
      });
      expect(
        find.text(l10n(tester).errCodeLegalAcceptanceRequired),
        findsOneWidget,
      );
    });
  });

  group('app gates', () {
    Future<
      ({
        SessionManager session,
        FakeAccountRepository account,
        FakeLegalRepository legal,
        FakeUrlOpener urls,
        ProviderContainer container,
      })
    >
    pumpGates(
      WidgetTester tester, {
      bool legalRequired = false,
      FakeAppConfigRepository? config,
      String installed = '1.2.0',
    }) async {
      final appConfig = AppConfig(apiBaseUrl: Uri.parse('http://test.local'));
      final session = SessionManager(
        storage: FakeTokenStorage(),
        authApi: AuthApi(
          appConfig,
          adapter: FakeAdapter(
            routeHandler({'auth/logout': (_) => emptyResponse(204)}),
          ),
        ),
        timer: InertTimer.new,
      );
      await session.setSession(Session.fromJson(sessionJson()));
      final account = FakeAccountRepository()
        ..profileResult = Profile(
          id: testUserId,
          email: 'moses@example.com',
          firstName: 'Moses',
          lastName: 'Otieno',
          displayName: 'Moses O.',
          legalUpdateRequired: legalRequired,
        );
      final legal = FakeLegalRepository();
      final urls = FakeUrlOpener();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(appConfig),
            sessionManagerProvider.overrideWithValue(session),
            mapEngineProvider.overrideWithValue(null),
            accountRepositoryProvider.overrideWithValue(account),
            legalRepositoryProvider.overrideWithValue(legal),
            urlOpenerProvider.overrideWithValue(urls),
            appConfigRepositoryProvider.overrideWithValue(
              config ?? FakeAppConfigRepository(),
            ),
            appVersionProvider.overrideWithValue(installed),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => AppGates(child: child!),
            home: const Scaffold(body: Text('app', key: Key('app.home'))),
          ),
        ),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(AppGates)),
      );
      await container.read(versionGateProvider.notifier).check();
      await tester.pumpAndSettle();
      return (
        session: session,
        account: account,
        legal: legal,
        urls: urls,
        container: container,
      );
    }

    AppLocalizations strings(WidgetTester tester) =>
        AppLocalizations.of(tester.element(find.byType(Scaffold).first));

    testWidgets('terms update blocks until accepted', (tester) async {
      final g = await pumpGates(tester, legalRequired: true);
      expect(byKey('screen.termsUpdate'), findsOneWidget);
      expect(byKey('app.home'), findsNothing);
      expect(find.text(strings(tester).legalUpdateTitle), findsOneWidget);

      await tapKey(tester, 'termsUpdate.terms');
      expect(g.urls.opened, [legalDocsFixture.terms.url]);

      g.account.profileResult = const Profile(
        id: testUserId,
        email: 'moses@example.com',
        firstName: 'Moses',
        lastName: 'Otieno',
        displayName: 'Moses O.',
      );
      await tapKey(tester, 'termsUpdate.accept');
      expect(g.legal.acceptCalls, [
        (terms: '2026-10-01', privacy: '2026-10-02'),
      ]);
      expect(byKey('screen.termsUpdate'), findsNothing);
      expect(byKey('app.home'), findsOneWidget);
    });

    testWidgets('a failed accept keeps the screen and says so', (tester) async {
      final g = await pumpGates(tester, legalRequired: true);
      g.legal.acceptError = offlineError;
      await tapKey(tester, 'termsUpdate.accept');
      expect(byKey('termsUpdate.error'), findsOneWidget);
      expect(byKey('screen.termsUpdate'), findsOneWidget);
    });

    testWidgets('sign out is the alternative', (tester) async {
      final g = await pumpGates(tester, legalRequired: true);
      await tapKey(tester, 'termsUpdate.signOut');
      expect(g.session.state, isA<SignedOut>());
      expect(byKey('screen.termsUpdate'), findsNothing);
    });

    testWidgets('no terms screen when nothing changed', (tester) async {
      await pumpGates(tester);
      expect(byKey('app.home'), findsOneWidget);
      expect(byKey('screen.termsUpdate'), findsNothing);
    });

    RemoteAppConfig minimum(String v) => RemoteAppConfig(
      minSupportedVersion: v,
      storeUrl: 'https://play.google.com/store/apps/details?id=x',
    );

    testWidgets('below the minimum: update required, button opens the store', (
      tester,
    ) async {
      final g = await pumpGates(
        tester,
        installed: '1.1.0',
        config: FakeAppConfigRepository(config: minimum('1.2.0')),
      );
      expect(byKey('screen.updateRequired'), findsOneWidget);
      expect(byKey('app.home'), findsNothing);
      await tapKey(tester, 'update.open');
      expect(g.urls.opened, [
        'https://play.google.com/store/apps/details?id=x',
      ]);
    });

    testWidgets('update required wins over the terms screen', (tester) async {
      await pumpGates(
        tester,
        legalRequired: true,
        installed: '1.1.0',
        config: FakeAppConfigRepository(config: minimum('1.2.0')),
      );
      expect(byKey('screen.updateRequired'), findsOneWidget);
      expect(byKey('screen.termsUpdate'), findsNothing);
    });

    testWidgets('equal or above the minimum, or offline: the app opens', (
      tester,
    ) async {
      for (final (installed, config) in [
        ('1.2.0', FakeAppConfigRepository(config: minimum('1.2.0'))),
        ('1.3.0', FakeAppConfigRepository(config: minimum('1.2.0'))),
        ('0.0.1', FakeAppConfigRepository(error: offlineError)),
      ]) {
        await pumpGates(tester, installed: installed, config: config);
        expect(byKey('app.home'), findsOneWidget, reason: installed);
        expect(byKey('screen.updateRequired'), findsNothing);
      }
    });
  });

  group('notification permission', () {
    testWidgets('riders see why first; "Not now" never blocks the app', (
      tester,
    ) async {
      final permission = FakeNotificationPermission();
      final h = await pumpBookingApp(
        tester,
        modeStore: MemoryModeStore(AppMode.rider),
        initialLocation: AppRoutes.riderHome,
        extraOverrides: [
          notificationPermissionProvider.overrideWithValue(permission),
        ],
      );
      expect(byKey('notifPermission.dialog'), findsOneWidget);
      await tapKeyAndSettle(tester, 'notifPermission.notNow');
      expect(permission.requests, 0);
      expect(h.store.values, isNotEmpty, reason: 'asked once per install');
      expect(byKey('riderHome.onlineSwitch'), findsOneWidget);
      expect(byKey('riderHome.notificationsOff'), findsOneWidget);

      await tapKeyAndSettle(tester, 'riderHome.notificationsOn');
      expect(permission.requests, 1);
      expect(byKey('riderHome.notificationsOff'), findsNothing);
    });

    testWidgets('denied: a gentle reminder that opens the settings', (
      tester,
    ) async {
      final permission = FakeNotificationPermission(
        afterRequest: NotificationPermissionStatus.permanentlyDenied,
      );
      await pumpBookingApp(
        tester,
        modeStore: MemoryModeStore(AppMode.rider),
        initialLocation: AppRoutes.riderHome,
        extraOverrides: [
          notificationPermissionProvider.overrideWithValue(permission),
        ],
      );
      await tapKeyAndSettle(tester, 'notifPermission.continue');
      expect(permission.requests, 1);
      expect(byKey('riderHome.notificationsOff'), findsOneWidget);
      expect(find.text(l10nOf(tester).notifOffReminder), findsOneWidget);
      await tapKeyAndSettle(tester, 'riderHome.notificationsOn');
      expect(permission.settingsOpened, 1);
      await tester.tap(byKey('riderHome.onlineSwitch'));
      await tester.pumpAndSettle();
      expect(byKey('screen.riderHome'), findsOneWidget);
    });

    testWidgets('senders are asked directly, once', (tester) async {
      final permission = FakeNotificationPermission();
      final h = await pumpBookingApp(
        tester,
        riderRepo: FakeRiderRepository(registered: false),
        extraOverrides: [
          notificationPermissionProvider.overrideWithValue(permission),
        ],
      );
      expect(byKey('notifPermission.dialog'), findsNothing);
      expect(permission.requests, 1);
      h.router.go(AppRoutes.history);
      await tester.pumpAndSettle();
      h.router.go(AppRoutes.home);
      await tester.pumpAndSettle();
      expect(permission.requests, 1);
    });
  });

  testWidgets('rider documents show the data-protection notice', (
    tester,
  ) async {
    await pumpBookingApp(tester, goTo: AppRoutes.riderDocuments);
    expect(byKey('documents.privacyNotice'), findsOneWidget);
    expect(find.text(l10nOf(tester).documentsPrivacyNotice), findsOneWidget);
  });

  group('tapping a push', () {
    PushNavigator navigatorFor(BookingHarness h) => PushNavigator(
      router: h.router,
      mode: h.mode,
      bookingRepo: h.repo,
      riderRepo: h.riderRepo,
      flags: SessionFlags(),
    );

    testWidgets('an offer opens the rider home', (tester) async {
      final h = await pumpBookingApp(tester);
      await navigatorFor(h)
          .open(const PushPayload(type: offerReceivedType, orderId: 'order-1'));
      await tester.pumpAndSettle();
      expect(location(h), AppRoutes.riderHome);
    });

    testWidgets('a rider push for another order opens its detail', (
      tester,
    ) async {
      final h = await pumpBookingApp(
        tester,
        modeStore: MemoryModeStore(AppMode.rider),
        initialLocation: AppRoutes.riderHome,
      );
      await navigatorFor(h).open(
        const PushPayload(type: 'pickup_timeout_rider', orderId: 'order-9'),
      );
      await tester.pumpAndSettle();
      expect(byKey('screen.orderDetail'), findsOneWidget);
    });

    testWidgets('a rider push for the active job stays on the job', (
      tester,
    ) async {
      final h = await pumpBookingApp(
        tester,
        modeStore: MemoryModeStore(AppMode.rider),
        initialLocation: AppRoutes.riderHome,
        riderRepo: FakeRiderRepository(
          activeResult: RiderActive(
            order: orderFixture(id: 'order-9', status: 'accepted'),
          ),
        ),
      );
      await navigatorFor(h).open(
        const PushPayload(type: 'receiver_location_shared', orderId: 'order-9'),
      );
      await tester.pump();
      expect(location(h), AppRoutes.riderHome);
    });

    testWidgets('a sender push routes from the server state', (tester) async {
      final repo = FakeBookingRepository()
        ..senderOrderResult = SenderOrder(
          order: orderFixture(status: 'created'),
        );
      final h = await pumpBookingApp(tester, repo: repo);
      await navigatorFor(h)
          .open(const PushPayload(type: 'offer.resolved', orderId: 'order-1'));
      await tester.pumpAndSettle();
      expect(location(h), AppRoutes.ridersFor('order-1'));
    });

    testWidgets('document pushes open the documents screen', (tester) async {
      for (final type in [
        'document_approved',
        'document_rejected',
        'document_expiring',
        'document_expired',
      ]) {
        final h = await pumpBookingApp(tester);
        await navigatorFor(h).open(PushPayload(type: type));
        await tester.pumpAndSettle();
        expect(location(h), AppRoutes.riderDocuments, reason: type);
        expect(byKey('screen.riderDocuments'), findsOneWidget, reason: type);
      }
    });

    testWidgets('rider verified push opens the verification status', (
      tester,
    ) async {
      final h = await pumpBookingApp(tester);
      await navigatorFor(h).open(const PushPayload(type: 'rider_verified'));
      await tester.pumpAndSettle();
      expect(location(h), AppRoutes.riderVerification);
    });

    testWidgets('no order id: nothing beyond the normal resume', (
      tester,
    ) async {
      final h = await pumpBookingApp(tester);
      await navigatorFor(h).open(const PushPayload(type: 'something.new'));
      await tester.pumpAndSettle();
      expect(location(h), AppRoutes.home);
    });

    test('taps wait until consumed', () {
      final taps = PushTaps();
      addTearDown(taps.dispose);
      taps.add(PushPayload.decode('{"type":"offer.received","order_id":"o"}'));
      expect(taps.take()?.orderId, 'o');
      expect(taps.take(), isNull);
    });
  });
}
