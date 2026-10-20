import 'package:geolocator/geolocator.dart';

import 'geo_point.dart';

sealed class LocationResult {
  const LocationResult();
}

class LocationFound extends LocationResult {
  const LocationFound(this.point, {this.accuracyM});
  final GeoPoint point;

  /// Horizontal accuracy radius in metres; null when the platform did not report it.
  final double? accuracyM;
}

/// A position with when it was read, so callers can tell whether it is still fresh.
class LocationFix {
  const LocationFix({required this.point, required this.at, this.accuracyM});

  final GeoPoint point;
  final DateTime at;
  final double? accuracyM;
}

/// Permission denied but can still be requested.
class LocationDenied extends LocationResult {
  const LocationDenied();
}

/// Permission permanently denied: only the app settings can change it.
class LocationDeniedForever extends LocationResult {
  const LocationDeniedForever();
}

class LocationServiceOff extends LocationResult {
  const LocationServiceOff();
}

/// Location could not be read (no plugin, timeout, hardware error).
class LocationUnavailable extends LocationResult {
  const LocationUnavailable();
}

abstract class LocationService {
  /// Reads the current position without prompting.
  Future<LocationResult> current();

  /// Prompts for permission if allowed, then reads the position.
  Future<LocationResult> requestAndGet();

  Future<void> openAppSettings();
  Future<void> openLocationSettings();
}

class GeolocatorLocationService implements LocationService {
  @override
  Future<LocationResult> current() => _read(prompt: false);

  @override
  Future<LocationResult> requestAndGet() => _read(prompt: true);

  Future<LocationResult> _read({required bool prompt}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationServiceOff();
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && prompt) {
        permission = await Geolocator.requestPermission();
      }
      switch (permission) {
        case LocationPermission.denied:
          return const LocationDenied();
        case LocationPermission.deniedForever:
          return const LocationDeniedForever();
        case LocationPermission.unableToDetermine:
          return const LocationUnavailable();
        case LocationPermission.whileInUse:
        case LocationPermission.always:
          final p = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              timeLimit: Duration(seconds: 15),
            ),
          );
          return LocationFound(
            GeoPoint(p.latitude, p.longitude),
            accuracyM: p.accuracy,
          );
      }
    } catch (_) {
      return const LocationUnavailable();
    }
  }

  @override
  Future<void> openAppSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (_) {}
  }

  @override
  Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (_) {}
  }
}
