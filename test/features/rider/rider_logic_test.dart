import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridelink/core/api/api_exception.dart';
import 'package:ridelink/core/auth/session.dart';
import 'package:ridelink/core/files/document_picker.dart';
import 'package:ridelink/core/mode/app_mode.dart';
import 'package:ridelink/core/routing/app_router.dart';
import 'package:ridelink/features/booking/data/booking_models.dart';
import 'package:ridelink/features/rider/data/rider_models.dart';
import 'package:ridelink/features/rider/job/job_logic.dart';
import 'package:ridelink/features/rider/onboarding/rider_onboarding_screen.dart';
import 'package:ridelink/features/rider/onboarding/upload_document_sheet.dart';
import 'package:ridelink/features/rider/settings/settings_validation.dart';
import 'package:ridelink/l10n/app_localizations_en.dart';

import '../../support/fakes.dart';
import '../../support/rider_fakes.dart';

void main() {
  group('job state machine', () {
    test('next action follows the rider-led payment flow', () {
      final steps = {
        jobFixture(): JobAction.arrivedAtPickup,
        jobFixture(arrivedAt: testNow): JobAction.pickedUp,
        jobFixture(status: 'started'): JobAction.startTrip,
        jobFixture(status: 'in_transit'): JobAction.arrivedAtDropoff,
        jobFixture(status: 'arrived'): JobAction.requestPayment,
        jobFixture(status: 'payment_requested'): JobAction.confirmPayment,
        jobFixture(status: 'cash_pending'): JobAction.confirmPayment,
        jobFixture(status: 'paid'): JobAction.handOver,
        jobFixture(status: 'handed_over'): JobAction.complete,
        jobFixture(status: 'completed'): JobAction.none,
        jobFixture(status: 'unresolved'): JobAction.none,
      };
      steps.forEach((order, action) => expect(nextAction(order), action));
    });

    test('plain status actions map to PATCH targets', () {
      expect(statusFor(JobAction.pickedUp), 'started');
      expect(statusFor(JobAction.startTrip), 'in_transit');
      // Arrived at the drop-off goes through POST /payment/request, never PATCH.
      expect(statusFor(JobAction.arrivedAtDropoff), isNull);
      expect(statusFor(JobAction.confirmPayment), isNull);
      expect(statusFor(JobAction.handOver), 'handed_over');
      expect(statusFor(JobAction.complete), 'completed');
      expect(statusFor(JobAction.requestPayment), isNull);
    });

    test('rider may cancel only before pickup', () {
      expect(riderCanCancel(jobFixture()), isTrue);
      expect(riderCanCancel(jobFixture(status: 'started')), isFalse);
    });

    test('cancel grace counts down from acceptance', () {
      final o = jobFixture(acceptedAt: testNow);
      expect(
        cancelGraceLeft(o, testNow.add(const Duration(seconds: 30))),
        const Duration(seconds: 90),
      );
      expect(
        cancelGraceLeft(o, testNow.add(const Duration(minutes: 3))),
        Duration.zero,
      );
    });

    test('tracking steps for the sender', () {
      expect(trackingStep(jobFixture()), TrackingStep.accepted);
      expect(
        trackingStep(jobFixture(arrivedAt: testNow)),
        TrackingStep.atPickup,
      );
      expect(
        trackingStep(jobFixture(status: 'in_transit')),
        TrackingStep.inTransit,
      );
      expect(
        trackingStep(jobFixture(status: 'cash_pending')),
        TrackingStep.payment,
      );
      expect(
        trackingStep(jobFixture(status: 'completed')),
        TrackingStep.delivered,
      );
    });

    test('pickup countdown stops at arrival and never goes negative', () {
      final o = jobFixture(deadline: testNow.add(const Duration(minutes: 8)));
      expect(pickupCountdown(o, testNow), const Duration(minutes: 8));
      expect(minutesLeft(const Duration(minutes: 7, seconds: 1)), 8);
      expect(
        pickupCountdown(o, testNow.add(const Duration(minutes: 9))),
        Duration.zero,
      );
      expect(pickupCountdown(jobFixture(arrivedAt: testNow), testNow), isNull);
      expect(formatClock(const Duration(minutes: 9, seconds: 5)), '9:05');
    });
  });

  group('order realtime updates', () {
    test('applyUpdate patches only the keys present', () {
      final o = jobFixture();
      final updated = o.applyUpdate({
        'order_id': o.id,
        'status': 'accepted',
        'pickup_arrived_at': '2026-10-13T09:47:00Z',
      });
      expect(updated.arrivedAtPickup, isTrue);
      expect(updated.agreedPrice, 214);
      expect(o.applyUpdate({'status': 'cash_pending'}).status, 'cash_pending');
    });

    test('order parses agreed price and pickup fields', () {
      final o = Order.fromJson({
        'id': 'o1',
        'service_type': 'ride',
        'status': 'accepted',
        'pickup_address': 'A',
        'dropoff_address': 'B',
        'agreed_price': 350,
        'pickup_deadline': '2026-10-13T09:52:00Z',
        'pickup_window_mins': 10,
        'cancel_reason': null,
      });
      expect(o.serviceType, ServiceType.ride);
      expect(o.agreedPrice, 350);
      expect(o.pickupWindowMins, 10);
      expect(o.isActiveJob, isTrue);
    });
  });

  group('rider models', () {
    test('active offer parses the flat order summary', () {
      final a = RiderActive.fromJson({
        'offer': {
          'id': 'of1',
          'order_id': 'o1',
          'offered_at': '2026-10-13T09:42:00Z',
          'expires_at': '2026-10-13T09:43:00Z',
          'pickup_distance_km': 0.8,
          'pickup_window_mins': 10,
          'quoted_total': 214,
          'service_type': 'delivery',
          'pickup_address': 'Westlands',
          'dropoff_address': 'CBD',
          'distance_km': 4.8,
        },
        'order': null,
      });
      expect(a.order, isNull);
      expect(a.offer!.quotedTotal, 214);
      expect(a.offer!.window, const Duration(seconds: 60));
      expect(a.offer!.distanceKm, 4.8);
    });

    test('verification tracks submission and documents not in force', () {
      final v = verificationFixture(
        overrides: {
          DocType.psvInsurance: const DocumentState(
            type: DocType.psvInsurance,
            status: DocStatus.rejected,
          ),
        },
      );
      expect(v.allSubmitted, isFalse);
      expect(v.notCurrent, [DocType.psvInsurance]);
      expect(DocType.riderPhoto.imageOnly, isTrue);
      expect(DocType.policeClearance.needsIssueDate, isTrue);
      expect(DocType.drivingLicence.needsExpiry, isTrue);
    });

    test('limits parse rate ranges', () {
      final l = RiderLimits.fromJson({
        'min_max_distance_km': 10,
        'max_pickup_radius_km': 3,
        'default_pickup_radius_km': 1.8,
        'delivery_rate': {'min': 16, 'max': 32},
        'ride_rate': {'min': 16, 'max': 32},
      });
      expect(l.deliveryRate.contains(32), isTrue);
      expect(l.rideRate.contains(33), isFalse);
    });
  });

  group('settings validation against limits', () {
    Map<SettingsField, String> values({
      String radius = '1.8',
      String distance = '10',
      String delivery = '16',
      String ride = '20',
      String weight = '20',
    }) => {
      SettingsField.pickupRadius: radius,
      SettingsField.maxDistance: distance,
      SettingsField.deliveryRate: delivery,
      SettingsField.rideRate: ride,
      SettingsField.maxWeight: weight,
    };

    test('valid values pass; comma decimals accepted', () {
      expect(validateSettings(values(radius: '2,5'), limitsFixture), isEmpty);
    });

    test('each limit is enforced', () {
      final errors = validateSettings(
        values(
          radius: '3.5',
          distance: '8',
          delivery: '40',
          ride: '15',
          weight: '0',
        ),
        limitsFixture,
      );
      expect(errors[SettingsField.pickupRadius], SettingsError.tooHigh);
      expect(errors[SettingsField.maxDistance], SettingsError.tooLow);
      expect(errors[SettingsField.deliveryRate], SettingsError.outOfRange);
      expect(errors[SettingsField.rideRate], SettingsError.outOfRange);
      expect(errors[SettingsField.maxWeight], SettingsError.mustBePositive);
    });

    test('empty and non-numeric', () {
      final errors = validateSettings(
        values(radius: '', weight: 'abc'),
        limitsFixture,
      );
      expect(errors[SettingsField.pickupRadius], SettingsError.required);
      expect(errors[SettingsField.maxWeight], SettingsError.notNumber);
    });
  });

  group('registration and uploads', () {
    test('plate is normalized like the server', () {
      expect(normalizePlate('  kmfa   123b '), 'KMFA 123B');
      expect(isValidPlate('kmfa 123b'), isTrue);
      expect(isValidPlate('ab'), isFalse);
      expect(isValidPlate('KM-123'), isFalse);
    });

    test('picked files are checked before upload', () {
      final l = AppLocalizationsEn();
      final pdf = PickedDocument(bytes: List.filled(10, 0), name: 'id.PDF');
      final big = PickedDocument(
        bytes: List.filled(maxDocumentBytes + 1, 0),
        name: 'big.jpg',
      );
      expect(
        validatePickedDocument(l, DocType.riderPhoto, pdf),
        l.docImageOnly,
      );
      expect(validatePickedDocument(l, DocType.nationalId, pdf), isNull);
      expect(validatePickedDocument(l, DocType.nationalId, big), l.docTooLarge);
    });
  });

  group('api errors and mode', () {
    test('ApiException keeps code and body', () {
      final e = ApiException.fromDio(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          response: Response(
            requestOptions: RequestOptions(path: '/x'),
            statusCode: 403,
            data: {
              'error': 'paused',
              'code': 'rider_paused',
              'paused_until': '2026-10-14T08:00:00Z',
            },
          ),
        ),
      );
      expect(e.code, 'rider_paused');
      expect(e.message, 'paused');
      expect(e.body['paused_until'], '2026-10-14T08:00:00Z');
    });

    test('mode controller persists changes', () {
      final store = MemoryModeStore();
      final c = AppModeController(store);
      expect(c.mode, AppMode.sender);
      c.set(AppMode.rider);
      expect(store.mode, AppMode.rider);
      expect(AppModeController(store).mode, AppMode.rider);
    });

    test('signed-in entry opens the last-used side', () {
      final signedIn = SignedIn(Session.fromJson(sessionJson()));
      expect(
        sessionRedirect(signedIn, AppRoutes.splash, mode: AppMode.rider),
        AppRoutes.riderHome,
      );
      expect(sessionRedirect(signedIn, AppRoutes.splash), AppRoutes.home);
      expect(
        sessionRedirect(
          signedIn,
          AppRoutes.auth,
          mode: AppMode.rider,
          riderIntent: true,
        ),
        AppRoutes.riderOnboarding,
      );
    });
  });
}
