import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'geo_point.dart';

/// Text of the persistent Android notification shown while tracking runs.
class TrackingNotice {
  const TrackingNotice({
    required this.title,
    required this.body,
    required this.channelName,
  });

  final String title;
  final String body;
  final String channelName;
}

/// Continuous position updates for an online rider. On Android this runs as a foreground
/// service with a persistent notification (frontend decision 12), so it keeps working with
/// the screen off.
abstract class LocationTracker {
  /// Starts (or restarts) tracking; positions arrive about every [interval].
  Stream<GeoPoint> start({
    required TrackingNotice notice,
    required Duration interval,
  });

  Future<void> stop();

  /// Android 13+ needs runtime permission to show the persistent notification.
  /// Tracking still works when refused; returns whether it was granted.
  Future<bool> requestNotificationPermission();
}

class GeolocatorLocationTracker implements LocationTracker {
  StreamSubscription<Position>? _sub;
  StreamController<GeoPoint>? _out;

  @override
  Stream<GeoPoint> start({
    required TrackingNotice notice,
    required Duration interval,
  }) {
    stop();
    final out = StreamController<GeoPoint>.broadcast();
    _out = out;
    final settings = defaultTargetPlatform == TargetPlatform.android
        ? AndroidSettings(
            accuracy: LocationAccuracy.high,
            intervalDuration: interval,
            foregroundNotificationConfig: ForegroundNotificationConfig(
              notificationTitle: notice.title,
              notificationText: notice.body,
              notificationChannelName: notice.channelName,
              // Monochrome status-bar icon (res/drawable/ic_stat_ridelink.xml).
              notificationIcon: const AndroidResource(name: 'ic_stat_ridelink'),
              setOngoing: true,
              enableWakeLock: true,
            ),
          )
        : const LocationSettings(accuracy: LocationAccuracy.high);
    _sub = Geolocator.getPositionStream(locationSettings: settings).listen(
      (p) => out.add(GeoPoint(p.latitude, p.longitude)),
      onError: (Object e) => out.addError(e),
    );
    return out.stream;
  }

  @override
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    await _out?.close();
    _out = null;
  }

  @override
  Future<bool> requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }
}
