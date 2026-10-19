import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/format/money.dart';
import '../../../core/providers.dart';
import '../../../core/routing/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';
import '../../booking/widgets/booking_widgets.dart';
import '../data/rider_models.dart';
import '../rider_controller.dart';
import '../widgets/rider_offer_watcher.dart';
import 'settings_validation.dart';

String _num(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

/// Rider pricing and settings: pickup radius, max distance, per-km rates, max weight.
/// No ad preview (frontend decision 7).
class RiderSettingsScreen extends ConsumerStatefulWidget {
  const RiderSettingsScreen({super.key});

  @override
  ConsumerState<RiderSettingsScreen> createState() =>
      _RiderSettingsScreenState();
}

class _RiderSettingsScreenState extends ConsumerState<RiderSettingsScreen> {
  final _controllers = {
    for (final f in SettingsField.values) f: TextEditingController(),
  };
  RiderLimits? _limits;
  bool _loading = true;
  bool _failed = false;
  bool _saving = false;
  Map<SettingsField, SettingsError> _errors = const {};
  String? _serverError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final repo = ref.read(riderRepositoryProvider);
    try {
      final results = await Future.wait<Object?>([repo.me(), repo.limits()]);
      final profile = results[0] as RiderProfile?;
      final limits = results[1]! as RiderLimits;
      if (!mounted) return;
      if (profile != null) {
        _controllers[SettingsField.pickupRadius]!.text = _num(
          profile.pickupRadiusKm,
        );
        _controllers[SettingsField.maxDistance]!.text = _num(
          profile.maxDistanceKm,
        );
        _controllers[SettingsField.deliveryRate]!.text = _num(
          profile.deliveryPricePerKm,
        );
        _controllers[SettingsField.rideRate]!.text = _num(
          profile.ridePricePerKm,
        );
        _controllers[SettingsField.maxWeight]!.text = _num(profile.maxWeightKg);
      }
      setState(() {
        _limits = limits;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _save() async {
    final limits = _limits;
    if (limits == null) return;
    final raw = {for (final e in _controllers.entries) e.key: e.value.text};
    final errors = validateSettings(raw, limits);
    setState(() {
      _errors = errors;
      _serverError = null;
    });
    if (errors.isNotEmpty) return;
    double v(SettingsField f) => parseNumber(raw[f]!)!;
    setState(() => _saving = true);
    final l = AppLocalizations.of(context);
    try {
      final profile = await ref
          .read(riderRepositoryProvider)
          .updateSettings(
            RiderSettingsInput(
              pickupRadiusKm: v(SettingsField.pickupRadius),
              maxDistanceKm: v(SettingsField.maxDistance),
              deliveryPricePerKm: v(SettingsField.deliveryRate),
              ridePricePerKm: v(SettingsField.rideRate),
              maxWeightKg: v(SettingsField.maxWeight),
            ),
          );
      if (!mounted) return;
      if (ref.exists(riderControllerProvider)) {
        ref.read(riderControllerProvider.notifier).profileUpdated(profile);
      }
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: const Key('settings.saved'),
          content: Text(l.settingsSaved),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _serverError = apiErrorText(e, l, fallback: l.settingsSaveFailed);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _serverError = l.settingsSaveFailed;
      });
    }
  }

  String? _errorText(AppLocalizations l, SettingsField f, RiderLimits limits) =>
      switch (_errors[f]) {
        null => null,
        SettingsError.required => l.settingsRequired,
        SettingsError.notNumber => l.settingsNotNumber,
        SettingsError.mustBePositive => l.settingsMustBePositive,
        SettingsError.tooHigh =>
          f == SettingsField.pickupRadius
              ? l.settingsRadiusTooHigh(formatKm(limits.maxPickupRadiusKm))
              : l.settingsTooHigh,
        SettingsError.tooLow => l.settingsDistanceTooLow(
          formatKm(limits.minMaxDistanceKm),
        ),
        SettingsError.outOfRange => () {
          final r = f == SettingsField.deliveryRate
              ? limits.deliveryRate
              : limits.rideRate;
          return l.settingsRateRange(
            formatKesRate(r.min),
            formatKesRate(r.max),
          );
        }(),
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final limits = _limits;

    Widget field(
      SettingsField f, {
      required String label,
      required String helper,
      required String suffix,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s4),
      child: TextField(
        key: Key('settings.${f.name}'),
        controller: _controllers[f],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          helperMaxLines: 2,
          suffixText: suffix,
          errorText: limits == null ? null : _errorText(l, f, limits),
          errorMaxLines: 2,
        ),
      ),
    );

    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s3, top: AppSpacing.s2),
      child: Text(title, style: AppTextStyles.labelLg.copyWith(color: c.ink)),
    );

    return RiderOfferWatcher(
      child: Scaffold(
        key: const Key('screen.riderSettings'),
        appBar: AppBar(
          leading: BackButton(
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.riderHome),
          ),
          title: Text(l.settingsTitle),
        ),
        body: SafeArea(
          child: _loading
              ? const LoadingView()
              : _failed || limits == null
              ? MessageView(
                  key: const Key('settings.error'),
                  icon: Icons.wifi_off,
                  title: l.settingsLoadFailed,
                  actionLabel: l.retryButton,
                  actionKey: const Key('settings.retry'),
                  onAction: _load,
                )
              : ListView(
                  padding: const EdgeInsets.all(AppLayout.screenPadding),
                  children: [
                    section(l.settingsDistanceSection),
                    field(
                      SettingsField.pickupRadius,
                      label: l.settingsPickupRadius,
                      helper: l.settingsPickupRadiusHelp(
                        formatKm(limits.maxPickupRadiusKm),
                      ),
                      suffix: l.unitKm,
                    ),
                    field(
                      SettingsField.maxDistance,
                      label: l.settingsMaxDistance,
                      helper: l.settingsMaxDistanceHelp(
                        formatKm(limits.minMaxDistanceKm),
                      ),
                      suffix: l.unitKm,
                    ),
                    section(l.settingsRatesSection),
                    NoteRow(l.settingsRatesNote),
                    const SizedBox(height: AppSpacing.s3),
                    field(
                      SettingsField.deliveryRate,
                      label: l.settingsDeliveryRate,
                      helper: l.settingsRateRange(
                        formatKesRate(limits.deliveryRate.min),
                        formatKesRate(limits.deliveryRate.max),
                      ),
                      suffix: l.unitPerKm,
                    ),
                    field(
                      SettingsField.rideRate,
                      label: l.settingsRideRate,
                      helper: l.settingsRateRange(
                        formatKesRate(limits.rideRate.min),
                        formatKesRate(limits.rideRate.max),
                      ),
                      suffix: l.unitPerKm,
                    ),
                    section(l.settingsLoadSection),
                    field(
                      SettingsField.maxWeight,
                      label: l.settingsMaxWeight,
                      helper: l.settingsMaxWeightHelp,
                      suffix: l.unitKg,
                    ),
                    if (_serverError != null) ...[
                      InlineError(
                        _serverError!,
                        key: const Key('settings.serverError'),
                      ),
                      const SizedBox(height: AppSpacing.s3),
                    ],
                    PrimaryButton(
                      key: const Key('settings.save'),
                      label: l.settingsSave,
                      loading: _saving,
                      onPressed: _save,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
