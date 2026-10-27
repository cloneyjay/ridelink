import 'package:flutter/material.dart';

import '../../theme/app_dimensions.dart';
import '../location/geo_point.dart';
import '../version/client_info.dart';

/// The one place that names the map tile provider (OpenFreeMap, founder decision 2026-10-27).
abstract final class MapConfig {
  static const lightStyleUrl = 'https://tiles.openfreemap.org/styles/positron';
  static const darkStyleUrl = 'https://tiles.openfreemap.org/styles/dark';

  static String styleFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkStyleUrl : lightStyleUrl;

  /// Nairobi CBD, used until a real position is known.
  static const fallbackCenter = GeoPoint(-1.2864, 36.8172);

  static const markerRadius = AppSpacing.s2;
  static const markerStrokeWidth = AppSpacing.s1 / 2;

  /// OpenFreeMap asks every app to send a User-Agent that identifies it.
  static String userAgent(ClientInfo info) =>
      'RideLink/${info.appVersion} (${info.platform})';
}
