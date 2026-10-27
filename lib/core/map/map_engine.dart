import 'package:flutter/widgets.dart';

import '../location/geo_point.dart';

enum MapMarkerKind { pickup, dropoff, rider }

class MapMarker {
  const MapMarker({required this.id, required this.point, required this.kind});

  final String id;
  final GeoPoint point;
  final MapMarkerKind kind;
}

/// A marker with its theme colours already resolved, ready for an engine to draw.
class StyledMapMarker {
  const StyledMapMarker({
    required this.id,
    required this.point,
    required this.fill,
    required this.stroke,
  });

  final String id;
  final GeoPoint point;
  final Color fill;
  final Color stroke;

  @override
  bool operator ==(Object other) =>
      other is StyledMapMarker &&
      other.id == id &&
      other.point == point &&
      other.fill == fill &&
      other.stroke == stroke;

  @override
  int get hashCode => Object.hash(id, point, fill, stroke);
}

abstract class RideLinkMapController {
  /// Animates the camera to [center], keeping the zoom unless [zoom] is given.
  Future<void> moveTo(GeoPoint center, {double? zoom});
}

/// Everything a map engine needs to draw one map; rebuilt whenever the screen rebuilds.
class MapViewSpec {
  const MapViewSpec({
    required this.styleUrl,
    required this.initialCenter,
    required this.initialZoom,
    this.markers = const [],
    this.showMyLocation = false,
    this.onCreated,
    this.onCameraIdle,
  });

  final String styleUrl;
  final GeoPoint initialCenter;
  final double initialZoom;
  final List<StyledMapMarker> markers;
  final bool showMyLocation;
  final ValueChanged<RideLinkMapController>? onCreated;

  /// The camera came to rest with this point at the centre of the map.
  final ValueChanged<GeoPoint>? onCameraIdle;
}

/// The swappable map provider seam: production uses MapLibre, tests use a fake.
abstract class MapEngine {
  Widget build(BuildContext context, MapViewSpec spec);
}
