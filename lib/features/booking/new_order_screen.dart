import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/error_messages.dart';
import '../../core/providers.dart';
import '../../core/routing/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../payments/payment_widgets.dart' show ChoiceRow;
import '../restrictions/restriction_providers.dart';
import 'booking_labels.dart';
import 'booking_routes.dart';
import 'confirm_pickup_screen.dart';
import 'data/booking_models.dart';
import 'default_pickup.dart';
import 'order_form.dart';
import 'place_search_screen.dart';
import 'widgets/booking_widgets.dart';

final itemCategoriesProvider = FutureProvider.autoDispose<List<ItemCategory>>(
  (ref) async => (await ref.watch(bookingRepositoryProvider).itemCategories())
      .where((c) => !c.isProhibited)
      .toList(),
  retry: (_, _) => null,
);

/// Screen 4: route, plus receiver and item declaration for deliveries.
class NewOrderScreen extends ConsumerStatefulWidget {
  const NewOrderScreen({super.key, required this.service});

  final ServiceType service;

  @override
  ConsumerState<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends ConsumerState<NewOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _receiver = TextEditingController();
  final _description = TextEditingController();
  final _weight = TextEditingController();
  PickupChoice? _pickup;
  Place? _dropoff;
  bool _locating = false;
  bool _confirming = false;

  /// Bumped on every pickup change so a late GPS result never overwrites the sender's choice.
  int _pickupVersion = 0;
  String? _categoryId;
  ValueBand? _band;
  Payer _payer = Payer.sender;
  bool _attempted = false;
  bool _submitting = false;
  String? _error;

  bool get _isDelivery => widget.service == ServiceType.delivery;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_defaultPickup());
    });
  }

  /// Seeds the pickup from the current location when it is accurate enough; otherwise the
  /// pickup stays empty for search.
  Future<void> _defaultPickup() async {
    final version = _pickupVersion;
    final l = AppLocalizations.of(context);
    setState(() => _locating = true);
    try {
      final fix = await pickupFix(
        cached: ref.read(lastKnownLocationProvider),
        service: ref.read(locationServiceProvider),
        now: ref.read(clockProvider)(),
        onFresh: (f) => ref.read(lastKnownLocationProvider.notifier).set(f),
      );
      if (fix == null || !mounted || version != _pickupVersion) return;
      final place = await placeAt(
        repo: ref.read(bookingRepositoryProvider),
        point: fix.point,
        language: l.localeName,
        fallbackLabel: l.currentLocationLabel,
      );
      if (!mounted || version != _pickupVersion) return;
      _setPickup(PickupChoice(place));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _setPickup(PickupChoice? choice) => setState(() {
    _pickupVersion++;
    _locating = false;
    _pickup = choice;
  });

  @override
  void dispose() {
    _receiver.dispose();
    _description.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _choose({required bool pickup}) async {
    final l = AppLocalizations.of(context);
    final place = await pickPlace(
      context,
      title: pickup ? l.pickupLabel : l.dropoffLabel,
    );
    if (place == null || !mounted) return;
    if (pickup) {
      _setPickup(PickupChoice(place));
    } else {
      setState(() => _dropoff = place);
    }
  }

  Future<void> _submit() async {
    setState(() {
      _attempted = true;
      _error = null;
    });
    final formOk = _formKey.currentState?.validate() ?? false;
    if (!formOk || _pickup == null || _dropoff == null) return;
    if (!_pickup!.confirmed) {
      if (_confirming) return;
      _confirming = true;
      final Place? confirmed;
      try {
        confirmed = await confirmPickup(
          context,
          service: widget.service,
          pickup: _pickup!.place,
        );
      } finally {
        _confirming = false;
      }
      if (confirmed == null || !mounted) return;
      _setPickup(PickupChoice(confirmed, confirmed: true));
    }

    setState(() => _submitting = true);
    try {
      final order = await ref
          .read(bookingRepositoryProvider)
          .createOrder(
            buildCreateOrderInput(
              service: widget.service,
              pickup: _pickup!.place,
              dropoff: _dropoff!,
              receiverName: _receiver.text,
              categoryId: _categoryId,
              description: _description.text,
              weightText: _weight.text,
              valueBand: _band,
              payer: _payer,
            ),
          );
      if (!mounted) return;
      context.go(
        AppRoutes.ridersFor(order.id),
        extra: RiderListArgs(order: order),
      );
    } catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context);
        final blocked = openBlockScreen(context, ref, e);
        setState(() {
          _submitting = false;
          _error = blocked
              ? null
              : apiErrorText(e, l, fallback: l.createOrderFailed);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Scaffold(
      key: const Key('screen.newOrder'),
      appBar: AppBar(
        title: Text(_isDelivery ? l.newDeliveryTitle : l.newRideTitle),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppLayout.screenPadding),
            children: [
              RouteFields(
                pickup: _pickup?.place.label,
                pickupLoading: _locating && _pickup == null,
                dropoff: _dropoff?.label,
                onPickup: () => _choose(pickup: true),
                onDropoff: () => _choose(pickup: false),
                pickupError: _attempted && _pickup == null
                    ? l.errorPickupRequired
                    : null,
                dropoffError: _attempted && _dropoff == null
                    ? l.errorDropoffRequired
                    : null,
              ),
              if (_isDelivery) ...[
                const SizedBox(height: AppSpacing.s6),
                _SectionTitle(l.receiverSectionTitle),
                const SizedBox(height: AppSpacing.s3),
                TextFormField(
                  key: const Key('order.receiver'),
                  controller: _receiver,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l.receiverNameLabel,
                    prefixIcon: Icon(Icons.person_outline, color: c.inkMuted),
                  ),
                  validator: (v) => validateReceiverName(v, l),
                ),
                const SizedBox(height: AppSpacing.s6),
                _SectionTitle(l.itemSectionTitle),
                const SizedBox(height: AppSpacing.s3),
                _CategoryField(
                  selected: _categoryId,
                  onChanged: (id) => setState(() => _categoryId = id),
                ),
                const SizedBox(height: AppSpacing.s3),
                TextFormField(
                  key: const Key('order.description'),
                  controller: _description,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: l.descriptionLabel),
                  validator: (v) => validateDescription(v, l),
                ),
                const SizedBox(height: AppSpacing.s3),
                TextFormField(
                  key: const Key('order.weight'),
                  controller: _weight,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: l.weightLabel),
                  validator: (v) => validateWeight(v, l),
                ),
                const SizedBox(height: AppSpacing.s4),
                _ValueBandField(
                  selected: _band,
                  onChanged: (b) => setState(() => _band = b),
                ),
                const SizedBox(height: AppSpacing.s6),
                _SectionTitle(l.whoPaysTitle),
                const SizedBox(height: AppSpacing.s3),
                for (final p in Payer.values) ...[
                  ChoiceRow(
                    key: Key('order.payer.${p.wire}'),
                    selected: p == _payer,
                    title: p == Payer.sender
                        ? l.payerSenderOption
                        : l.payerReceiverOption,
                    icon: p == Payer.sender
                        ? Icons.person_outline
                        : Icons.person_pin_circle_outlined,
                    onTap: _submitting
                        ? null
                        : () => setState(() => _payer = p),
                  ),
                  if (p != Payer.values.last)
                    const SizedBox(height: AppSpacing.s2),
                ],
                if (_payer == Payer.receiver) ...[
                  const SizedBox(height: AppSpacing.s3),
                  NoteRow(
                    l.receiverPaysDisclosure,
                    key: const Key('order.receiverPaysNote'),
                  ),
                ],
              ],
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.s4),
                InlineError(_error!, key: const Key('order.error')),
              ],
              const SizedBox(height: AppSpacing.s6),
              PrimaryButton(
                key: const Key('order.submit'),
                label: l.findRidersButton,
                loading: _submitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTextStyles.labelLg.copyWith(color: context.colors.ink),
  );
}

class _CategoryField extends ConsumerWidget {
  const _CategoryField({required this.selected, required this.onChanged});

  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final categories = ref.watch(itemCategoriesProvider);
    return categories.when(
      loading: () =>
          const SizedBox(height: AppLayout.minTapTarget, child: LoadingView()),
      error: (_, _) => Row(
        key: const Key('order.categoriesError'),
        children: [
          Expanded(
            child: Text(
              l.categoriesLoadFailed,
              style: AppTextStyles.bodySm.copyWith(color: c.statusError),
            ),
          ),
          TextButton(
            onPressed: () => ref.invalidate(itemCategoriesProvider),
            child: Text(l.retryButton),
          ),
        ],
      ),
      data: (items) => DropdownButtonFormField<String>(
        key: const Key('order.category'),
        initialValue: selected,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: l.categoryLabel,
          prefixIcon: Icon(Icons.category_outlined, color: c.inkMuted),
        ),
        items: [
          for (final cat in items)
            DropdownMenuItem(
              value: cat.id,
              child: Text(
                categoryLabel(l, cat.code),
                key: Key('order.category.${cat.code}'),
              ),
            ),
        ],
        onChanged: onChanged,
        validator: (v) => validateCategory(v, l),
      ),
    );
  }
}

class _ValueBandField extends StatelessWidget {
  const _ValueBandField({required this.selected, required this.onChanged});

  final ValueBand? selected;
  final ValueChanged<ValueBand> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return FormField<ValueBand>(
      initialValue: selected,
      validator: (v) => validateValueBand(v, l),
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.valueBandLabel,
            style: AppTextStyles.label.copyWith(color: c.ink),
          ),
          const SizedBox(height: AppSpacing.s2),
          for (final band in ValueBand.values)
            _BandOption(
              band: band,
              selected: band == selected,
              onTap: () {
                onChanged(band);
                field.didChange(band);
              },
            ),
          const SizedBox(height: AppSpacing.s1),
          NoteRow(l.valueBandCapNote),
          if (field.hasError)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s1),
              child: Text(
                field.errorText!,
                key: const Key('order.valueBand.error'),
                style: AppTextStyles.bodySm.copyWith(color: c.statusError),
              ),
            ),
        ],
      ),
    );
  }
}

class _BandOption extends StatelessWidget {
  const _BandOption({
    required this.band,
    required this.selected,
    required this.onTap,
  });

  final ValueBand band;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s2),
      child: Material(
        color: selected ? c.brand100 : c.surfaceSunken,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          key: Key('order.valueBand.${band.wire}'),
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppLayout.minTapTarget,
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: selected ? c.brand500 : c.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? c.brand500 : c.inkFaint,
                  size: AppSpacing.s5,
                ),
                const SizedBox(width: AppSpacing.s3),
                Text(
                  valueBandLabel(l, band),
                  style: AppTextStyles.body.copyWith(color: c.ink),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
