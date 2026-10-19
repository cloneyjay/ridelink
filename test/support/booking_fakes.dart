import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ridelink/core/auth/auth_api.dart';
import 'package:ridelink/core/auth/session.dart';
import 'package:ridelink/core/auth/session_manager.dart';
import 'package:ridelink/core/config/app_config.dart';
import 'package:ridelink/core/location/geo_point.dart';
import 'package:ridelink/core/location/location_service.dart';
import 'package:ridelink/core/maps/maps_config.dart';
import 'package:ridelink/core/mode/app_mode.dart';
import 'package:ridelink/core/providers.dart';
import 'package:ridelink/core/realtime/realtime_event.dart';
import 'package:ridelink/core/routing/app_router.dart';
import 'package:ridelink/core/routing/rider_intent.dart';
import 'package:ridelink/features/booking/data/booking_models.dart';
import 'package:ridelink/core/storage/local_store.dart';
import 'package:ridelink/features/booking/data/booking_repository.dart';
import 'package:ridelink/features/orders/data/order_models.dart';
import 'package:ridelink/features/shell/account_repository.dart';
import 'package:ridelink/l10n/app_localizations.dart';
import 'package:ridelink/theme/app_theme.dart';

import 'auth_harness.dart';
import 'fakes.dart';
import 'phase3_fakes.dart';
import 'rider_fakes.dart';

export 'phase3_fakes.dart';
export 'rider_fakes.dart';

const westlands = Place(
  placeId: 'p-westlands',
  name: 'Westlands Mall',
  address: 'Waiyaki Way, Nairobi',
  location: GeoPoint(-1.2648, 36.8025),
);

const cbd = Place(
  placeId: 'p-cbd',
  name: 'Moi Avenue',
  address: 'CBD, Nairobi',
  location: GeoPoint(-1.2833, 36.8219),
);

const categoriesFixture = [
  ItemCategory(
    id: 'cat-docs',
    code: 'documents',
    status: 'allowed',
    requiresExtraCheck: false,
  ),
  ItemCategory(
    id: 'cat-food',
    code: 'food',
    status: 'allowed',
    requiresExtraCheck: false,
  ),
  ItemCategory(
    id: 'cat-weapons',
    code: 'weapons',
    status: 'prohibited',
    requiresExtraCheck: true,
  ),
];

Order orderFixture({
  String id = 'order-1',
  ServiceType service = ServiceType.delivery,
  String status = 'created',
  double? distanceKm = 4.8,
  bool estimated = false,
}) => Order(
  id: id,
  serviceType: service,
  status: status,
  pickupAddress: westlands.label,
  dropoffAddress: cbd.label,
  pickupLocation: westlands.location,
  dropoffLocation: cbd.location,
  receiverName: service == ServiceType.delivery ? 'Grace W.' : null,
  distanceKm: distanceKm,
  distanceEstimated: estimated,
);

RiderQuote riderFixture({
  String id = 'rider-1',
  String name = 'Moses O.',
  int total = 214,
  double pickupKm = 0.8,
  int windowMins = 10,
  double rating = 4.9,
  int ratingCount = 120,
  double? onTime = 0.98,
  int? completed = 340,
  bool minimumFare = false,
  double riderKm = 0,
}) => RiderQuote(
  riderId: id,
  displayName: name,
  hasPhoto: false,
  ratingAverage: rating,
  ratingCount: ratingCount,
  onTimeRate: onTime,
  completed: completed,
  pickupDistanceKm: pickupKm,
  pickupWindowMins: windowMins,
  total: total,
  currency: 'KES',
  breakdown: QuoteBreakdown(
    baseFare: 80,
    platformKm: 4.8,
    platformAmount: 77,
    riderKm: riderKm,
    riderRate: 25,
    riderAmount: (riderKm * 25).round(),
    minimumFareApplied: minimumFare,
  ),
);

Offer offerFixture({
  String id = 'offer-1',
  String orderId = 'order-1',
  String riderId = 'rider-1',
  Duration window = const Duration(seconds: 60),
}) {
  final offered = DateTime.utc(2026, 10, 13, 9, 42);
  return Offer(
    id: id,
    orderId: orderId,
    riderId: riderId,
    offeredAt: offered,
    expiresAt: offered.add(window),
    quotedTotal: 214,
    pickupWindowMins: 10,
  );
}

class FakeBookingRepository implements BookingRepository {
  List<PlacePrediction> predictions = const [
    PlacePrediction(
      placeId: 'p-westlands',
      primaryText: 'Westlands Mall',
      secondaryText: 'Waiyaki Way, Nairobi',
    ),
    PlacePrediction(
      placeId: 'p-cbd',
      primaryText: 'Moi Avenue',
      secondaryText: 'CBD, Nairobi',
    ),
  ];
  Map<String, Place> places = {westlands.placeId: westlands, cbd.placeId: cbd};
  Object? autocompleteError;
  Object? detailsError;
  final autocompleteCalls = <({String input, String token, GeoPoint? near})>[];
  final detailsCalls = <({String placeId, String token})>[];

  List<ItemCategory> categories = categoriesFixture;
  Object? categoriesError;

  final createCalls = <CreateOrderInput>[];
  Object? createError;
  Order Function(CreateOrderInput input)? onCreate;

  Order order = orderFixture();
  Object? getOrderError;
  int getOrderCalls = 0;

  final routeCalls = <RouteInput>[];
  Object? routeError;

  RiderList riders = RiderList(
    tripDistanceKm: 4.8,
    distanceEstimated: false,
    riders: [riderFixture()],
  );
  Object? ridersError;
  Completer<RiderList>? ridersGate;
  int ridersCalls = 0;

  Offer offer = offerFixture();
  Object? offerError;
  final offerCalls = <({String orderId, String riderId})>[];

  int cancelCalls = 0;
  Object? cancelError;

  List<Order> myOrdersList = const [];

  /// GET /orders/active.
  List<SenderOrder> activeList = const [];
  Object? activeError;
  int activeCalls = 0;

  /// GET /orders/{id} as the sender; defaults to [order] with no pending offer.
  SenderOrder? senderOrderResult;
  Object? senderOrderError;

  int paymentSentCalls = 0;
  Object? paymentSentError;
  Order Function(String orderId)? onPaymentSent;

  @override
  Future<List<PlacePrediction>> autocomplete({
    required String input,
    required String sessionToken,
    GeoPoint? near,
  }) async {
    autocompleteCalls.add((input: input, token: sessionToken, near: near));
    if (autocompleteError != null) throw autocompleteError!;
    final q = input.toLowerCase();
    return predictions
        .where((p) => p.primaryText.toLowerCase().contains(q))
        .toList();
  }

  @override
  Future<Place> placeDetails({
    required String placeId,
    required String sessionToken,
  }) async {
    detailsCalls.add((placeId: placeId, token: sessionToken));
    if (detailsError != null) throw detailsError!;
    return places[placeId]!;
  }

  @override
  Future<List<ItemCategory>> itemCategories() async {
    if (categoriesError != null) throw categoriesError!;
    return categories;
  }

  @override
  Future<Order> createOrder(CreateOrderInput input) async {
    createCalls.add(input);
    if (createError != null) throw createError!;
    return onCreate?.call(input) ?? orderFixture(service: input.serviceType);
  }

  @override
  Future<Order> getOrder(String orderId) async {
    getOrderCalls++;
    if (getOrderError != null) throw getOrderError!;
    return order;
  }

  @override
  Future<SenderOrder> senderOrder(String orderId) async {
    getOrderCalls++;
    if (senderOrderError != null) throw senderOrderError!;
    if (getOrderError != null) throw getOrderError!;
    return senderOrderResult ?? SenderOrder(order: order);
  }

  @override
  Future<List<SenderOrder>> activeOrders() async {
    activeCalls++;
    if (activeError != null) throw activeError!;
    return activeList;
  }

  @override
  Future<Order> updateRoute(String orderId, RouteInput route) async {
    routeCalls.add(route);
    if (routeError != null) throw routeError!;
    return Order(
      id: orderId,
      serviceType: order.serviceType,
      status: 'created',
      pickupAddress: route.pickup.label,
      dropoffAddress: route.dropoff.label,
      pickupLocation: route.pickup.location,
      dropoffLocation: route.dropoff.location,
      distanceKm: 6.2,
    );
  }

  @override
  Future<RiderList> ridersForOrder(String orderId) async {
    ridersCalls++;
    if (ridersGate != null) return ridersGate!.future;
    if (ridersError != null) throw ridersError!;
    return riders;
  }

  @override
  Future<Uint8List?> riderPhoto(String riderId) async => null;

  @override
  Future<Offer> sendOffer({
    required String orderId,
    required String riderId,
  }) async {
    offerCalls.add((orderId: orderId, riderId: riderId));
    if (offerError != null) throw offerError!;
    return offer;
  }

  @override
  Future<Order> cancelOrder(String orderId) async {
    cancelCalls++;
    if (cancelError != null) throw cancelError!;
    return orderFixture(id: orderId, status: 'cancelled');
  }

  @override
  Future<List<Order>> myOrders() async => myOrdersList;

  @override
  Future<Order> confirmPaymentSent(String orderId) async {
    paymentSentCalls++;
    if (paymentSentError != null) throw paymentSentError!;
    return onPaymentSent?.call(orderId) ??
        order.copyWith(status: 'cash_pending');
  }
}

class FakeAccountRepository implements AccountRepository {
  FakeAccountRepository({this.rider = false, this.error});

  bool rider;
  Object? error;
  int calls = 0;

  Profile profileResult = const Profile(
    id: testUserId,
    email: 'moses@example.com',
    firstName: 'Moses',
    lastName: 'Otieno',
    displayName: 'Moses O.',
  );
  Object? profileError;
  final nameCalls = <({String first, String last})>[];
  Object? nameError;

  @override
  Future<bool> isRider() async {
    calls++;
    if (error != null) throw error!;
    return rider;
  }

  @override
  Future<Profile> profile() async {
    if (profileError != null) throw profileError!;
    return profileResult;
  }

  @override
  Future<Profile> updateName({
    required String firstName,
    required String lastName,
  }) async {
    nameCalls.add((first: firstName, last: lastName));
    if (nameError != null) throw nameError!;
    profileResult = Profile(
      id: profileResult.id,
      email: profileResult.email,
      firstName: firstName,
      lastName: lastName,
      displayName: '$firstName ${lastName[0]}.',
    );
    return profileResult;
  }
}

class FakeLocationService implements LocationService {
  FakeLocationService({
    this.initial = const LocationFound(GeoPoint(-1.2648, 36.8025)),
    LocationResult? afterRequest,
  }) : afterRequest = afterRequest ?? initial;

  LocationResult initial;
  LocationResult afterRequest;
  int requests = 0;
  int reads = 0;
  int appSettingsOpened = 0;
  int locationSettingsOpened = 0;

  @override
  Future<LocationResult> current() async {
    reads++;
    return requests == 0 ? initial : afterRequest;
  }

  @override
  Future<LocationResult> requestAndGet() async {
    requests++;
    return requests == 1 ? initial : afterRequest;
  }

  @override
  Future<void> openAppSettings() async => appSettingsOpened++;

  @override
  Future<void> openLocationSettings() async => locationSettingsOpened++;
}

class FakeMapsConfig implements MapsConfig {
  FakeMapsConfig({this.hasKey = false});

  final bool hasKey;

  @override
  Future<bool> hasMapsKey() async => hasKey;
}

class BookingHarness {
  BookingHarness({
    required this.router,
    required this.repo,
    required this.account,
    required this.location,
    required this.events,
    required this.session,
    required this.riderRepo,
    required this.tracker,
    required this.picker,
    required this.camera,
    required this.mode,
    required this.orders,
    required this.evidence,
    required this.notifications,
    required this.navigation,
    required this.share,
    required this.store,
  });

  final FakeOrdersRepository orders;
  final FakeEvidenceRepository evidence;
  final FakeNotificationRepository notifications;
  final FakeNavigationLauncher navigation;
  final FakeShareService share;
  final MemoryLocalStore store;
  final FakeRiderRepository riderRepo;
  final FakeLocationTracker tracker;
  final FakeDocumentPicker picker;
  final FakeEvidenceCamera camera;
  final AppModeController mode;

  final GoRouter router;
  final FakeBookingRepository repo;
  final FakeAccountRepository account;
  final FakeLocationService location;
  final StreamController<RealtimeEvent> events;
  final SessionManager session;

  void emit(String type, Map<String, dynamic> data) {
    events.add(
      RealtimeEvent(
        type: type,
        kind: RealtimeEventKind.fromWire(type),
        data: data,
      ),
    );
  }
}

/// Real router, signed in, all server calls served by fakes.
Future<BookingHarness> pumpBookingApp(
  WidgetTester tester, {
  FakeBookingRepository? repo,
  FakeAccountRepository? account,
  FakeLocationService? location,
  FakeRiderRepository? riderRepo,
  FakeLocationTracker? tracker,
  FakeDocumentPicker? picker,
  FakeEvidenceCamera? camera,
  FakeOrdersRepository? orders,
  FakeEvidenceRepository? evidence,
  FakeNotificationRepository? notifications,
  MemoryLocalStore? store,
  ModeStore? modeStore,
  DateTime Function()? clock,
  String initialLocation = AppRoutes.home,
  String? goTo,
  Object? extra,
  bool settle = true,
}) async {
  final config = AppConfig(apiBaseUrl: Uri.parse('http://test.local'));
  final adapter = FakeAdapter(
    routeHandler({'auth/logout': (_) => emptyResponse(204)}),
  );
  final session = SessionManager(
    storage: FakeTokenStorage(),
    authApi: AuthApi(config, adapter: adapter),
  );
  await session.setSession(Session.fromJson(sessionJson()));
  final intent = RiderIntent();
  final mode = AppModeController(modeStore ?? MemoryModeStore());
  final router = buildRouter(
    session,
    intent,
    initialLocation: initialLocation,
    mode: mode,
  );
  final events = StreamController<RealtimeEvent>.broadcast();
  final bookingRepo = repo ?? FakeBookingRepository();
  final ordersRepo = orders ?? FakeOrdersRepository();
  ordersRepo.orderSource ??= () => bookingRepo.order;
  final harness = BookingHarness(
    router: router,
    repo: bookingRepo,
    account: account ?? FakeAccountRepository(),
    location: location ?? FakeLocationService(),
    events: events,
    session: session,
    riderRepo: riderRepo ?? FakeRiderRepository(),
    tracker: tracker ?? FakeLocationTracker(),
    picker: picker ?? FakeDocumentPicker(),
    camera: camera ?? FakeEvidenceCamera(),
    mode: mode,
    orders: ordersRepo,
    evidence: evidence ?? FakeEvidenceRepository(),
    notifications: notifications ?? FakeNotificationRepository(),
    navigation: FakeNavigationLauncher(),
    share: FakeShareService(),
    store: store ?? MemoryLocalStore(),
  );
  addTearDown(router.dispose);
  addTearDown(events.close);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        authApiProvider.overrideWithValue(AuthApi(config, adapter: adapter)),
        sessionManagerProvider.overrideWithValue(session),
        riderIntentProvider.overrideWithValue(intent),
        googleAuthProvider.overrideWithValue(
          FakeGoogleAuth(isConfigured: false),
        ),
        bookingRepositoryProvider.overrideWithValue(harness.repo),
        accountRepositoryProvider.overrideWithValue(harness.account),
        locationServiceProvider.overrideWithValue(harness.location),
        mapsConfigProvider.overrideWithValue(FakeMapsConfig()),
        realtimeEventsProvider.overrideWith((ref) => events.stream),
        riderRepositoryProvider.overrideWithValue(harness.riderRepo),
        locationTrackerProvider.overrideWithValue(harness.tracker),
        documentPickerProvider.overrideWithValue(harness.picker),
        evidenceCameraProvider.overrideWithValue(harness.camera),
        appModeProvider.overrideWithValue(mode),
        ordersRepositoryProvider.overrideWithValue(harness.orders),
        evidenceRepositoryProvider.overrideWithValue(harness.evidence),
        notificationRepositoryProvider.overrideWithValue(harness.notifications),
        navigationLauncherProvider.overrideWithValue(harness.navigation),
        shareServiceProvider.overrideWithValue(harness.share),
        localStoreProvider.overrideWithValue(harness.store),
        if (clock != null) clockProvider.overrideWithValue(clock),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (goTo != null) {
    router.go(goTo, extra: extra);
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }
  return harness;
}

AppLocalizations l10nOf(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Scaffold).last));

Future<void> tapKeyAndSettle(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
