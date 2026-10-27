import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../location/geo_point.dart';
import 'map_config.dart';
import 'map_engine.dart';

/// MapLibre Native rendering OpenFreeMap vector tiles (Android and iOS).
class MapLibreEngine implements MapEngine {
  MapLibreEngine({required this.userAgent});

  final String userAgent;

  static bool _headersSet = false;

  void _ensureHeaders() {
    if (_headersSet) return;
    _headersSet = true;
    unawaited(
      setHttpHeaders({'User-Agent': userAgent}).catchError((Object e) {
        if (kDebugMode) debugPrint('map: user agent not set ($e)');
      }),
    );
  }

  @override
  Widget build(BuildContext context, MapViewSpec spec) {
    _ensureHeaders();
    return _MapLibreView(spec: spec);
  }
}

class _MapLibreView extends StatefulWidget {
  const _MapLibreView({required this.spec});

  final MapViewSpec spec;

  @override
  State<_MapLibreView> createState() => _MapLibreViewState();
}

class _MapLibreViewState extends State<_MapLibreView>
    implements RideLinkMapController {
  MapLibreMapController? _controller;
  bool _styleReady = false;
  final Map<String, Circle> _circles = {};
  final Map<String, StyledMapMarker> _drawn = {};
  Future<void> _sync = Future.value();

  static LatLng _ll(GeoPoint p) => LatLng(p.lat, p.lng);

  @override
  void didUpdateWidget(_MapLibreView old) {
    super.didUpdateWidget(old);
    if (!listEquals(old.spec.markers, widget.spec.markers)) _scheduleSync();
  }

  @override
  Future<void> moveTo(GeoPoint center, {double? zoom}) async {
    await _controller?.animateCamera(
      zoom == null
          ? CameraUpdate.newLatLng(_ll(center))
          : CameraUpdate.newLatLngZoom(_ll(center), zoom),
    );
  }

  void _scheduleSync() {
    _sync = _sync.then((_) => _syncMarkers()).catchError((Object e) {
      if (kDebugMode) debugPrint('map: marker sync failed ($e)');
    });
  }

  // Annotations are serialised through [_sync] so adds and updates never race.
  Future<void> _syncMarkers() async {
    final c = _controller;
    if (c == null || !_styleReady || !mounted) return;
    final wanted = {for (final m in widget.spec.markers) m.id: m};
    for (final id in _drawn.keys.toList()) {
      if (wanted.containsKey(id)) continue;
      _drawn.remove(id);
      final circle = _circles.remove(id);
      if (circle != null) await c.removeCircle(circle);
    }
    for (final m in wanted.values) {
      if (_drawn[m.id] == m) continue;
      final options = CircleOptions(
        geometry: _ll(m.point),
        circleRadius: MapConfig.markerRadius,
        circleColor: m.fill.toHexStringRGB(),
        circleStrokeWidth: MapConfig.markerStrokeWidth,
        circleStrokeColor: m.stroke.toHexStringRGB(),
      );
      final existing = _circles[m.id];
      if (existing == null) {
        _circles[m.id] = await c.addCircle(options);
      } else {
        await c.updateCircle(existing, options);
      }
      _drawn[m.id] = m;
    }
  }

  void _onStyleLoaded() {
    // A new style (first load or a theme switch) starts with no annotations.
    _styleReady = true;
    _circles.clear();
    _drawn.clear();
    _scheduleSync();
  }

  void _onCameraIdle() {
    final target = _controller?.cameraPosition?.target;
    if (target == null) return;
    widget.spec.onCameraIdle?.call(GeoPoint(target.latitude, target.longitude));
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    return MapLibreMap(
      styleString: spec.styleUrl,
      initialCameraPosition: CameraPosition(
        target: _ll(spec.initialCenter),
        zoom: spec.initialZoom,
      ),
      onMapCreated: (c) {
        _controller = c;
        spec.onCreated?.call(this);
      },
      onStyleLoadedCallback: _onStyleLoaded,
      trackCameraPosition: spec.onCameraIdle != null,
      onCameraIdle: spec.onCameraIdle == null ? null : _onCameraIdle,
      myLocationEnabled: spec.showMyLocation,
      annotationOrder: const [AnnotationType.circle],
    );
  }
}
