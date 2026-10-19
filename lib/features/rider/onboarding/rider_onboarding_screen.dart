import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/providers.dart';
import '../../../core/routing/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';
import '../../booking/widgets/booking_widgets.dart';
import '../rider_controller.dart';

/// Normalizes like the server: upper case, single spaces.
String normalizePlate(String raw) =>
    raw.toUpperCase().trim().split(RegExp(r'\s+')).join(' ');

final _platePattern = RegExp(r'^[A-Z0-9 ]{3,12}$');

bool isValidPlate(String raw) => _platePattern.hasMatch(normalizePlate(raw));

/// Rider registration: vehicle is fixed to boda boda; the rider enters the plate number.
/// Already-registered riders continue straight to the document checklist.
class RiderOnboardingScreen extends ConsumerStatefulWidget {
  const RiderOnboardingScreen({super.key});

  @override
  ConsumerState<RiderOnboardingScreen> createState() =>
      _RiderOnboardingScreenState();
}

class _RiderOnboardingScreenState extends ConsumerState<RiderOnboardingScreen> {
  final _plate = TextEditingController();
  bool _checking = true;
  bool _checkFailed = false;
  bool _submitting = false;
  String? _plateError;
  String? _serverError;

  @override
  void initState() {
    super.initState();
    // The intent has done its job; clear after the frame so the router isn't notified mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(riderIntentProvider).clear();
    });
    _check();
  }

  @override
  void dispose() {
    _plate.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    setState(() {
      _checking = true;
      _checkFailed = false;
    });
    try {
      final profile = await ref.read(riderRepositoryProvider).me();
      if (!mounted) return;
      if (profile != null) {
        context.go(AppRoutes.riderDocuments);
        return;
      }
      setState(() => _checking = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _checkFailed = true;
      });
    }
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    final ok = isValidPlate(_plate.text);
    setState(() {
      _plateError = ok ? null : l.plateInvalid;
      _serverError = null;
    });
    if (!ok) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(riderRepositoryProvider)
          .register(plateNumber: normalizePlate(_plate.text));
      _registered();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 409) {
        _registered();
        return;
      }
      setState(() {
        _submitting = false;
        _serverError = apiErrorText(e, l, fallback: l.registerFailed);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _serverError = l.registerFailed;
      });
    }
  }

  void _registered() {
    if (!mounted) return;
    ref.invalidate(isRiderProvider);
    ref.invalidate(riderControllerProvider);
    context.go(AppRoutes.riderDocuments);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Scaffold(
      key: const Key('screen.riderOnboarding'),
      appBar: AppBar(
        leading: IconButton(
          key: const Key('onboarding.close'),
          tooltip: l.closeTooltip,
          icon: const Icon(Icons.close),
          onPressed: () => context.go(AppRoutes.home),
        ),
        title: Text(l.riderOnboardingTitle),
      ),
      body: SafeArea(
        child: _checking
            ? const LoadingView()
            : _checkFailed
            ? MessageView(
                key: const Key('onboarding.error'),
                icon: Icons.wifi_off,
                title: l.riderLoadFailed,
                actionLabel: l.retryButton,
                actionKey: const Key('onboarding.retry'),
                onAction: _check,
              )
            : ListView(
                padding: const EdgeInsets.all(AppLayout.screenPadding),
                children: [
                  Text(
                    l.registerIntro,
                    style: AppTextStyles.body.copyWith(color: c.inkMuted),
                  ),
                  const SizedBox(height: AppSpacing.s6),
                  Text(
                    l.vehicleLabel,
                    style: AppTextStyles.labelSm.copyWith(color: c.inkMuted),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  SurfaceCard(
                    child: Row(
                      children: [
                        Icon(
                          Symbols.two_wheeler,
                          color: c.ride500,
                          size: AppSpacing.s8,
                        ),
                        const SizedBox(width: AppSpacing.s3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.vehicleBodaBoda,
                                key: const Key('onboarding.vehicle'),
                                style: AppTextStyles.labelLg.copyWith(
                                  color: c.ink,
                                ),
                              ),
                              Text(
                                l.vehicleOnlyBoda,
                                style: AppTextStyles.bodySm.copyWith(
                                  color: c.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s6),
                  TextField(
                    key: const Key('onboarding.plate'),
                    controller: _plate,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 12,
                    decoration: InputDecoration(
                      labelText: l.plateLabel,
                      hintText: l.plateHint,
                      errorText: _plateError,
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  if (_serverError != null) ...[
                    const SizedBox(height: AppSpacing.s3),
                    InlineError(
                      _serverError!,
                      key: const Key('onboarding.serverError'),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s6),
                  PrimaryButton(
                    key: const Key('onboarding.submit'),
                    label: l.registerButton,
                    loading: _submitting,
                    onPressed: _submit,
                  ),
                ],
              ),
      ),
    );
  }
}
