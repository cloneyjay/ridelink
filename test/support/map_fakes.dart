import 'package:flutter/widgets.dart';
import 'package:ridelink/core/location/geo_point.dart';
import 'package:ridelink/core/map/map_engine.dart';

/// Stands in for MapLibre: records what screens asked their maps to draw and do.
class FakeMapEngine implements MapEngine {
  /// The most recently built map's spec.
  MapViewSpec? spec;
  final controllers = <FakeMapController>[];

  /// The controller of the most recently created map.
  FakeMapController get controller => controllers.last;

  List<StyledMapMarker> get markers => spec?.markers ?? const [];

  StyledMapMarker? marker(String id) {
    for (final m in markers) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Simulates the user panning the map so that [center] comes to rest under the centre.
  void settleAt(GeoPoint center) => spec?.onCameraIdle?.call(center);

  @override
  Widget build(BuildContext context, MapViewSpec spec) {
    this.spec = spec;
    return _FakeMapView(engine: this, spec: spec);
  }
}

class FakeMapController implements RideLinkMapController {
  final moves = <({GeoPoint center, double? zoom})>[];

  @override
  Future<void> moveTo(GeoPoint center, {double? zoom}) async =>
      moves.add((center: center, zoom: zoom));
}

class _FakeMapView extends StatefulWidget {
  const _FakeMapView({required this.engine, required this.spec});

  final FakeMapEngine engine;
  final MapViewSpec spec;

  @override
  State<_FakeMapView> createState() => _FakeMapViewState();
}

class _FakeMapViewState extends State<_FakeMapView> {
  @override
  void initState() {
    super.initState();
    final controller = FakeMapController();
    widget.engine.controllers.add(controller);
    widget.spec.onCreated?.call(controller);
  }

  @override
  Widget build(BuildContext context) =>
      const SizedBox.expand(key: Key('fakeMap'));
}
