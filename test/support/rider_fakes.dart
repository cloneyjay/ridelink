import 'dart:async';

import 'package:ridelink/core/files/document_picker.dart';
import 'package:ridelink/core/files/evidence_camera.dart';
import 'package:ridelink/core/location/geo_point.dart';
import 'package:ridelink/core/location/location_tracker.dart';
import 'package:ridelink/features/booking/data/booking_models.dart';
import 'package:ridelink/features/rider/data/rider_models.dart';
import 'package:ridelink/features/rider/data/rider_repository.dart';

/// Fixed "now" for rider tests: 2026-10-13 09:42 UTC.
final testNow = DateTime.utc(2026, 10, 13, 9, 42);

RiderProfile riderProfileFixture({
  bool online = false,
  VerificationStatus status = VerificationStatus.verified,
  DateTime? pausedUntil,
  String? pauseReason,
  int pauseFailures = 0,
}) => RiderProfile(
  id: 'rider-1',
  plateNumber: 'KMFA 123B',
  isOnline: online,
  verificationStatus: status,
  pickupRadiusKm: 1.8,
  maxDistanceKm: 10,
  deliveryPricePerKm: 16,
  ridePricePerKm: 16,
  maxWeightKg: 20,
  pausedUntil: pausedUntil,
  pauseReason: pauseReason,
  pauseFailures: pauseFailures,
);

Verification verificationFixture({
  VerificationStatus status = VerificationStatus.verified,
  Map<DocType, DocumentState> overrides = const {},
  DocStatus all = DocStatus.approved,
}) => Verification(
  status: status,
  documents: [
    for (final t in DocType.values)
      overrides[t] ??
          DocumentState(
            type: t,
            status: all,
            current: all == DocStatus.approved,
          ),
  ],
);

const limitsFixture = RiderLimits(
  minMaxDistanceKm: 10,
  maxPickupRadiusKm: 3,
  defaultPickupRadiusKm: 1.8,
  deliveryRate: RateRange(16, 32),
  rideRate: RateRange(16, 32),
);

RiderOffer riderOfferFixture({
  String id = 'offer-9',
  String orderId = 'order-9',
  Duration window = const Duration(seconds: 60),
  DateTime? offeredAt,
}) {
  final offered = offeredAt ?? testNow;
  return RiderOffer(
    id: id,
    orderId: orderId,
    offeredAt: offered,
    expiresAt: offered.add(window),
    serviceType: ServiceType.delivery,
    pickupAddress: 'Westlands Mall, Waiyaki Way, Nairobi',
    dropoffAddress: 'Moi Avenue, CBD, Nairobi',
    distanceKm: 4.8,
    quotedTotal: 214,
    pickupDistanceKm: 0.8,
    pickupWindowMins: 10,
  );
}

Order jobFixture({
  String id = 'order-9',
  String status = 'accepted',
  DateTime? acceptedAt,
  DateTime? deadline,
  DateTime? arrivedAt,
  int agreedPrice = 214,
  String? cancelReason,
  ServiceType service = ServiceType.delivery,
}) => Order(
  id: id,
  serviceType: service,
  status: status,
  pickupAddress: 'Westlands Mall, Waiyaki Way, Nairobi',
  dropoffAddress: 'Moi Avenue, CBD, Nairobi',
  pickupLocation: const GeoPoint(-1.2648, 36.8025),
  dropoffLocation: const GeoPoint(-1.2833, 36.8219),
  receiverName: service == ServiceType.delivery ? 'Grace W.' : null,
  distanceKm: 4.8,
  agreedPrice: agreedPrice,
  acceptedAt: acceptedAt ?? testNow,
  pickupWindowMins: 10,
  pickupDeadline: deadline ?? testNow.add(const Duration(minutes: 10)),
  pickupArrivedAt: arrivedAt,
  cancelReason: cancelReason,
);

class FakeRiderRepository implements RiderRepository {
  FakeRiderRepository({
    RiderProfile? profile,
    this.registered = true,
    Verification? verification,
    this.activeResult = const RiderActive(),
  }) : profile = profile ?? riderProfileFixture(),
       verificationResult = verification ?? verificationFixture();

  RiderProfile profile;
  bool registered;
  Object? meError;
  int meCalls = 0;

  final registerCalls = <String>[];
  Object? registerError;

  Verification verificationResult;
  int verificationCalls = 0;
  final uploads =
      <({DocType type, String name, DateTime? expires, DateTime? issued})>[];
  Object? uploadError;

  RiderLimits limitsResult = limitsFixture;
  final settingsCalls = <RiderSettingsInput>[];
  Object? settingsError;

  final onlineCalls = <bool>[];
  Object? onlineError;
  final locationCalls = <GeoPoint>[];

  RiderActive activeResult;
  int activeCalls = 0;

  final acceptCalls = <String>[];
  Object? acceptError;
  final declineCalls = <String>[];
  Object? declineError;

  /// Every job call in order, e.g. `arrived`, `status:started`, `payment/request`.
  final jobCalls = <String>[];
  Object? jobError;
  Order? job;

  @override
  Future<RiderProfile?> me() async {
    meCalls++;
    if (meError != null) throw meError!;
    return registered ? profile : null;
  }

  @override
  Future<RiderProfile> register({required String plateNumber}) async {
    registerCalls.add(plateNumber);
    if (registerError != null) throw registerError!;
    registered = true;
    profile = riderProfileFixture(status: VerificationStatus.pending);
    return profile;
  }

  @override
  Future<Verification> verification() async {
    verificationCalls++;
    return verificationResult;
  }

  @override
  Future<DocumentState> uploadDocument({
    required DocType type,
    required List<int> bytes,
    required String fileName,
    DateTime? expiresOn,
    DateTime? issuedOn,
  }) async {
    uploads.add((
      type: type,
      name: fileName,
      expires: expiresOn,
      issued: issuedOn,
    ));
    if (uploadError != null) throw uploadError!;
    final doc = DocumentState(type: type, status: DocStatus.pending);
    verificationResult = Verification(
      status: verificationResult.status,
      documents: [
        for (final d in verificationResult.documents) d.type == type ? doc : d,
      ],
    );
    return doc;
  }

  @override
  Future<RiderLimits> limits() async => limitsResult;

  @override
  Future<RiderProfile> updateSettings(RiderSettingsInput input) async {
    settingsCalls.add(input);
    if (settingsError != null) throw settingsError!;
    return profile;
  }

  @override
  Future<RiderProfile> setOnline(bool online) async {
    onlineCalls.add(online);
    if (onlineError != null) throw onlineError!;
    profile = profile.copyWith(isOnline: online);
    return profile;
  }

  @override
  Future<void> updateLocation(GeoPoint point) async => locationCalls.add(point);

  @override
  Future<RiderActive> active() async {
    activeCalls++;
    return activeResult;
  }

  @override
  Future<List<Order>> myOrders() async => const [];

  @override
  Future<Order> acceptOffer(String orderId) async {
    acceptCalls.add(orderId);
    if (acceptError != null) throw acceptError!;
    job = jobFixture(id: orderId);
    return job!;
  }

  @override
  Future<void> declineOffer(String orderId) async {
    declineCalls.add(orderId);
    if (declineError != null) throw declineError!;
  }

  Future<Order> _job(String call, Order Function(Order o) next) async {
    jobCalls.add(call);
    if (jobError != null) throw jobError!;
    job = next(job ?? jobFixture());
    return job!;
  }

  @override
  Future<Order> markArrived(String orderId) =>
      _job('arrived', (o) => o.copyWith(pickupArrivedAt: testNow));

  @override
  Future<Order> updateStatus(String orderId, String status) =>
      _job('status:$status', (o) => o.copyWith(status: status));

  @override
  Future<Order> cancel(String orderId) => _job(
    'status:cancelled',
    (o) => o.copyWith(status: 'cancelled', cancelReason: 'rider'),
  );

  @override
  Future<Order> requestPayment(String orderId) =>
      _job('payment/request', (o) => o.copyWith(status: 'payment_requested'));

  @override
  Future<Order> paymentReceived(String orderId) =>
      _job('payment/received', (o) => o.copyWith(status: 'paid'));

  @override
  Future<Order> paymentNotReceived(String orderId) =>
      _job('payment/not-received', (o) => o.copyWith(status: 'unresolved'));
}

class FakeLocationTracker implements LocationTracker {
  StreamController<GeoPoint>? controller;
  int starts = 0;
  int stops = 0;
  int notificationRequests = 0;
  TrackingNotice? lastNotice;

  bool get running => controller != null;

  @override
  Stream<GeoPoint> start({
    required TrackingNotice notice,
    required Duration interval,
  }) {
    starts++;
    lastNotice = notice;
    controller = StreamController<GeoPoint>.broadcast();
    return controller!.stream;
  }

  @override
  Future<void> stop() async {
    stops++;
    await controller?.close();
    controller = null;
  }

  @override
  Future<bool> requestNotificationPermission() async {
    notificationRequests++;
    return true;
  }

  void emit(GeoPoint p) => controller?.add(p);
}

class FakeDocumentPicker implements DocumentPicker {
  PickedDocument? next = PickedDocument(
    bytes: List.filled(100, 1),
    name: 'doc.jpg',
  );
  final sources = <DocumentSource>[];

  @override
  Future<PickedDocument?> pick(DocumentSource source) async {
    sources.add(source);
    return next;
  }
}

/// Camera-only evidence capture; counts every time the camera opens.
class FakeEvidenceCamera implements EvidenceCamera {
  PickedDocument? next = PickedDocument(
    bytes: List.filled(100, 2),
    name: 'evidence.jpg',
  );
  int shots = 0;

  @override
  Future<PickedDocument?> takePhoto() async {
    shots++;
    return next;
  }
}
