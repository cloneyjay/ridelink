import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../location/geo_point.dart';
import '../version/client_info.dart';
import 'map_config.dart';
import 'map_engine.dart';
import 'maplibre_engine.dart';

export 'map_engine.dart';

/// The map engine for this platform, or null where none runs (the map placeholder shows).
final mapEngineProvider = Provider<MapEngine?>((ref) {
  if (kIsWeb) return null;
  final mobile =
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  if (!mobile) return null;
  return MapLibreEngine(
    userAgent: MapConfig.userAgent(ref.watch(clientInfoProvider)),
  );
});

final mapAvailableProvider = Provider<bool>(
  (ref) => ref.watch(mapEngineProvider) != null,
);

/// The app's only map widget: theme-matched tiles, RideLink markers and visible attribution.
class RideLinkMap extends ConsumerWidget {
  const RideLinkMap({
    super.key,
    required this.initialCenter,
    required this.initialZoom,
    this.markers = const [],
    this.showMyLocation = false,
    this.onCreated,
    this.onCameraIdle,
    this.attributionAlignment = AlignmentDirectional.bottomStart,
    this.attributionPadding = EdgeInsets.zero,
  });

  final GeoPoint initialCenter;
  final double initialZoom;
  final List<MapMarker> markers;
  final bool showMyLocation;
  final ValueChanged<RideLinkMapController>? onCreated;
  final ValueChanged<GeoPoint>? onCameraIdle;

  /// Where the attribution sits; screens move it clear of anything drawn over the map.
  final AlignmentDirectional attributionAlignment;
  final EdgeInsets attributionPadding;

  static Color markerFill(AppColors c, MapMarkerKind kind) => switch (kind) {
    MapMarkerKind.pickup => c.forest500,
    MapMarkerKind.dropoff => c.brand500,
    MapMarkerKind.rider => c.ride500,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(mapEngineProvider);
    if (engine == null) return const MapPlaceholder();
    final c = context.colors;
    final spec = MapViewSpec(
      styleUrl: MapConfig.styleFor(Theme.of(context).brightness),
      initialCenter: initialCenter,
      initialZoom: initialZoom,
      markers: [
        for (final m in markers)
          StyledMapMarker(
            id: m.id,
            point: m.point,
            fill: markerFill(c, m.kind),
            stroke: c.surfaceRaised,
          ),
      ],
      showMyLocation: showMyLocation,
      onCreated: onCreated,
      onCameraIdle: onCameraIdle,
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        engine.build(context, spec),
        Align(
          alignment: attributionAlignment,
          child: Padding(
            padding: attributionPadding,
            child: const MapAttribution(),
          ),
        ),
      ],
    );
  }
}

/// Required tile and data credit; always visible on top of the map.
class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      key: const Key('map.attribution'),
      margin: const EdgeInsets.all(AppSpacing.s1),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s2,
        vertical: AppSpacing.s1 / 2,
      ),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        AppLocalizations.of(context).mapAttribution,
        style: AppTextStyles.labelSm.copyWith(color: c.inkMuted),
      ),
    );
  }
}

/// Credit for the place search provider, shown wherever its results are listed.
class PoweredByGeoapify extends StatelessWidget {
  const PoweredByGeoapify({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      key: const Key('placeSearch.poweredBy'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppLayout.screenPadding,
        vertical: AppSpacing.s2,
      ),
      child: Text(
        AppLocalizations.of(context).placeSearchPoweredBy,
        textAlign: TextAlign.end,
        style: AppTextStyles.labelSm.copyWith(color: c.inkMuted),
      ),
    );
  }
}

/// Shown instead of the map where no map engine runs.
class MapPlaceholder extends StatelessWidget {
  const MapPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ColoredBox(
      key: const Key('home.mapPlaceholder'),
      color: c.surfaceSunken,
      child: Align(
        alignment: const Alignment(0, -0.4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: AppSpacing.s12, color: c.inkFaint),
            const SizedBox(height: AppSpacing.s2),
            Text(
              AppLocalizations.of(context).mapUnavailable,
              style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
