import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_dimensions.dart';
import 'confirm_pickup_screen.dart';
import 'data/booking_models.dart';
import 'place_search_screen.dart';
import 'widgets/booking_widgets.dart';

/// Changes pickup and/or drop-off while the order is still "created"; pops the updated order.
class EditRouteScreen extends ConsumerStatefulWidget {
  const EditRouteScreen({super.key, required this.order});

  final Order order;

  @override
  ConsumerState<EditRouteScreen> createState() => _EditRouteScreenState();
}

class _EditRouteScreenState extends ConsumerState<EditRouteScreen> {
  Place? _pickup;
  bool _pickupConfirmed = false;
  Place? _dropoff;
  bool _saving = false;
  String? _error;

  Place? _current({required bool pickup}) {
    final o = widget.order;
    final location = pickup ? o.pickupLocation : o.dropoffLocation;
    if (location == null) return null;
    final address = pickup ? o.pickupAddress : o.dropoffAddress;
    return Place(placeId: '', name: '', address: address, location: location);
  }

  Place? get _effectivePickup => _pickup ?? _current(pickup: true);
  Place? get _effectiveDropoff => _dropoff ?? _current(pickup: false);

  Future<void> _choose({required bool pickup}) async {
    final l = AppLocalizations.of(context);
    final place = await pickPlace(
      context,
      title: pickup ? l.pickupLabel : l.dropoffLabel,
    );
    if (place == null || !mounted) return;
    setState(() {
      if (pickup) {
        _pickup = place;
        _pickupConfirmed = false;
      } else {
        _dropoff = place;
      }
    });
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    // A changed pickup is confirmed on the map first; the order's existing pickup already was.
    if (_pickup != null && !_pickupConfirmed) {
      final confirmed = await confirmPickup(
        context,
        service: widget.order.serviceType,
        pickup: _pickup!,
      );
      if (confirmed == null || !mounted) return;
      setState(() {
        _pickup = confirmed;
        _pickupConfirmed = true;
      });
    }
    final pickup = _effectivePickup;
    final dropoff = _effectiveDropoff;
    if (pickup == null || dropoff == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await ref
          .read(bookingRepositoryProvider)
          .updateRoute(
            widget.order.id,
            RouteInput(pickup: pickup, dropoff: dropoff),
          );
      if (mounted) context.pop(updated);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.statusCode == 422 || e.statusCode == 409
            ? l.routeLocked
            : l.routeUpdateFailed;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = l.routeUpdateFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final changed = _pickup != null || _dropoff != null;
    return Scaffold(
      key: const Key('screen.editRoute'),
      appBar: AppBar(title: Text(l.editRouteTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppLayout.screenPadding),
          children: [
            RouteFields(
              pickup: _effectivePickup?.label,
              dropoff: _effectiveDropoff?.label,
              onPickup: () => _choose(pickup: true),
              onDropoff: () => _choose(pickup: false),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.s4),
              InlineError(_error!, key: const Key('editRoute.error')),
            ],
            const SizedBox(height: AppSpacing.s6),
            PrimaryButton(
              key: const Key('editRoute.save'),
              label: l.saveRouteButton,
              loading: _saving,
              onPressed: changed ? _save : null,
            ),
          ],
        ),
      ),
    );
  }
}
