import '../../core/location/geo_point.dart';
import '../../core/location/location_service.dart';
import 'data/booking_models.dart';
import 'data/booking_repository.dart';

/// A GPS fix is only good enough for a pickup within this radius.
const maxPickupAccuracyM = 100.0;

/// The address lookup gives up after this and falls back, so it never hangs the flow.
const reverseLookupTimeout = Duration(seconds: 5);

/// A cached fix older than this is re-read before it becomes the pickup.
const pickupFixMaxAge = Duration(minutes: 2);

bool isAccurateForPickup(double? accuracyM) =>
    accuracyM != null && accuracyM <= maxPickupAccuracyM;

/// The pickup and whether the sender has confirmed it on the map. Any change starts unconfirmed.
class PickupChoice {
  const PickupChoice(this.place, {this.confirmed = false});

  final Place place;
  final bool confirmed;
}

/// A current, accurate-enough fix: the cached one when fresh, otherwise a new read (no prompt).
/// [onFresh] receives every new read so the shared cache stays current.
Future<LocationFix?> pickupFix({
  required LocationFix? cached,
  required LocationService service,
  required DateTime now,
  required void Function(LocationFix fix) onFresh,
}) async {
  if (cached != null &&
      now.difference(cached.at) <= pickupFixMaxAge &&
      isAccurateForPickup(cached.accuracyM)) {
    return cached;
  }
  final result = await service.current();
  if (result is! LocationFound) return null;
  final fix = LocationFix(
    point: result.point,
    accuracyM: result.accuracyM,
    at: now,
  );
  onFresh(fix);
  return isAccurateForPickup(fix.accuracyM) ? fix : null;
}

/// The address at [point]; when none can be had, a place at [point] that shows
/// [fallbackLabel] locally and is stored on the order as coordinates.
Future<Place> placeAt({
  required BookingRepository repo,
  required GeoPoint point,
  required String language,
  required String fallbackLabel,
}) async {
  Place? found;
  try {
    found = await repo
        .reverseGeocode(point: point, language: language)
        .timeout(reverseLookupTimeout);
  } catch (_) {
    found = null;
  }
  if (found == null || !found.hasAddress) {
    return Place(
      placeId: '',
      name: '',
      address: '',
      location: point,
      localLabel: fallbackLabel,
    );
  }
  return Place(
    placeId: found.placeId,
    name: found.name,
    address: found.address,
    location: point,
  );
}
