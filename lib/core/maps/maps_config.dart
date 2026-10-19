import 'package:flutter/services.dart';

/// Whether the Android build carries a Maps SDK key (MAPS_API_KEY in android/local.properties).
abstract class MapsConfig {
  Future<bool> hasMapsKey();
}

class PlatformMapsConfig implements MapsConfig {
  static const _channel = MethodChannel('ridelink/config');

  @override
  Future<bool> hasMapsKey() async {
    try {
      return await _channel.invokeMethod<bool>('hasMapsKey') ?? false;
    } catch (_) {
      return false;
    }
  }
}
