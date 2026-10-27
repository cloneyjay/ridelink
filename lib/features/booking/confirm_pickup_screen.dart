import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/location/geo_point.dart';
import '../../core/map/ridelink_map.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text_styles.dart';
import 'booking_labels.dart';
import 'data/booking_models.dart';
import 'default_pickup.dart';
import 'place_search_screen.dart';
import 'widgets/booking_widgets.dart';

/// Opens Confirm pickup for [pickup]; returns the confirmed pickup, or null if dismissed.
Future<Place?> confirmPickup(
  BuildContext context, {
  required ServiceType service,
  required Place pickup,
}) => Navigator.of(context).push<Place>(
  MaterialPageRoute(
    builder: (_) => ConfirmPickupScreen(service: service, initial: pickup),
  ),
);

/// Map centred on the pickup under a fixed pin; the sender pans the map to the exact spot.
class ConfirmPickupScreen extends ConsumerStatefulWidget {
  const ConfirmPickupScreen({
    super.key,
    required this.service,
    required this.initial,
  });

  static const debounce = Duration(milliseconds: 400);

  final ServiceType service;
  final Place initial;

  @override
  ConsumerState<ConfirmPickupScreen> createState() =>
      ConfirmPickupScreenState();
}

class ConfirmPickupScreenState extends ConsumerState<ConfirmPickupScreen> {
  late Place _place = widget.initial;
  RideLinkMapController? _map;
  Timer? _debounce;
  int _seq = 0;
  bool _resolving = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  static bool _same(GeoPoint a, GeoPoint b) =>
      (a.lat - b.lat).abs() < 1e-6 && (a.lng - b.lng).abs() < 1e-6;

  /// Map came to rest with [center] under the pin: that point becomes the pickup.
  @visibleForTesting
  void handleCameraIdle(GeoPoint center) {
    if (_same(center, _place.location)) return;
    _debounce?.cancel();
    final seq = ++_seq;
    setState(() {
      _resolving = true;
      _place = Place(
        placeId: '',
        name: _place.name,
        address: _place.address,
        location: center,
        localLabel: _place.localLabel,
      );
    });
    _debounce = Timer(
      ConfirmPickupScreen.debounce,
      () => _resolve(center, seq),
    );
  }

  Future<void> _resolve(GeoPoint center, int seq) async {
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    final place = await placeAt(
      repo: ref.read(bookingRepositoryProvider),
      point: center,
      language: l.localeName,
      fallbackLabel: l.pinnedLocationLabel,
    );
    if (!mounted || seq != _seq) return;
    setState(() {
      _place = place;
      _resolving = false;
    });
  }

  Future<void> _searchInstead() async {
    final l = AppLocalizations.of(context);
    final place = await pickPlace(context, title: l.pickupLabel);
    if (place == null || !mounted) return;
    _debounce?.cancel();
    _seq++;
    setState(() {
      _place = place;
      _resolving = false;
    });
    unawaited(_map?.moveTo(place.location));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasMap = ref.watch(mapAvailableProvider);
    final accent = serviceAccent(c, widget.service);
    return Scaffold(
      key: const Key('screen.confirmPickup'),
      appBar: AppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: hasMap
                ? Stack(
                    children: [
                      Positioned.fill(child: _mapView()),
                      IgnorePointer(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.s10,
                            ),
                            child: Icon(
                              Icons.location_on,
                              key: const Key('confirmPickup.pin'),
                              color: accent,
                              size: AppSpacing.s10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : const MapPlaceholder(),
          ),
          _Panel(
            service: widget.service,
            label: _place.label,
            resolving: _resolving,
            showHelper: hasMap,
            onConfirm: () => Navigator.of(context).pop(_place),
            onSearch: _searchInstead,
          ),
        ],
      ),
    );
  }

  Widget _mapView() {
    return RideLinkMap(
      key: const Key('confirmPickup.map'),
      initialCenter: widget.initial.location,
      initialZoom: 17,
      onCreated: (controller) => _map = controller,
      onCameraIdle: handleCameraIdle,
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.service,
    required this.label,
    required this.resolving,
    required this.showHelper,
    required this.onConfirm,
    required this.onSearch,
  });

  final ServiceType service;
  final String label;
  final bool resolving;
  final bool showHelper;
  final VoidCallback onConfirm;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppLayout.sheetTopRadius),
        ),
        boxShadow: context.shadows.lg,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppLayout.screenPadding,
            AppSpacing.s5,
            AppLayout.screenPadding,
            AppSpacing.s4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                service == ServiceType.ride
                    ? l.confirmPickupRideTitle
                    : l.confirmPickupDeliveryTitle,
                key: const Key('confirmPickup.title'),
                style: AppTextStyles.displaySm.copyWith(color: c.ink),
              ),
              if (showHelper) ...[
                const SizedBox(height: AppSpacing.s1),
                Text(
                  l.confirmPickupHelper,
                  key: const Key('confirmPickup.helper'),
                  style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
                ),
              ],
              const SizedBox(height: AppSpacing.s4),
              Container(
                padding: const EdgeInsets.all(AppSpacing.s3),
                decoration: BoxDecoration(
                  color: serviceTint(c, service),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: serviceAccent(c, service),
                      size: AppSpacing.s5,
                    ),
                    const SizedBox(width: AppSpacing.s3),
                    Expanded(
                      child: Text(
                        label,
                        key: const Key('confirmPickup.label'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(color: c.ink),
                      ),
                    ),
                    if (resolving) ...[
                      const SizedBox(width: AppSpacing.s2),
                      SizedBox.square(
                        key: const Key('confirmPickup.resolving'),
                        dimension: AppSpacing.s4,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: c.inkMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              PrimaryButton(
                key: const Key('confirmPickup.confirm'),
                label: l.confirmPickupButton,
                loading: resolving,
                onPressed: onConfirm,
              ),
              const SizedBox(height: AppSpacing.s2),
              TextButton(
                key: const Key('confirmPickup.search'),
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppLayout.minTapTarget),
                ),
                onPressed: onSearch,
                child: Text(l.searchInsteadButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
