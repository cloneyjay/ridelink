import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/routing/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';
import '../../booking/widgets/booking_widgets.dart';
import '../data/rider_models.dart';
import '../rider_controller.dart';

/// Overall verification status: pending review / approved / rejected.
class VerificationStatusScreen extends ConsumerStatefulWidget {
  const VerificationStatusScreen({super.key});

  @override
  ConsumerState<VerificationStatusScreen> createState() =>
      _VerificationStatusScreenState();
}

class _VerificationStatusScreenState
    extends ConsumerState<VerificationStatusScreen> {
  Verification? _v;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final v = await ref.read(riderRepositoryProvider).verification();
      if (!mounted) return;
      setState(() {
        _v = v;
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

  void _goHome() {
    ref.invalidate(riderControllerProvider);
    context.go(AppRoutes.riderHome);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final v = _v;
    Widget body;
    if (_loading) {
      body = const LoadingView();
    } else if (_failed || v == null) {
      body = MessageView(
        key: const Key('verification.error'),
        icon: Icons.wifi_off,
        title: l.documentsLoadFailed,
        actionLabel: l.retryButton,
        actionKey: const Key('verification.retry'),
        onAction: _load,
      );
    } else {
      final rejected =
          v.status == VerificationStatus.rejected ||
          v.documents.any((d) => d.status == DocStatus.rejected);
      final (
        String key,
        IconData icon,
        Color color,
        String title,
        String text,
      ) = switch (v.status) {
        VerificationStatus.verified => (
          'verification.approved',
          Icons.verified,
          c.statusSuccess,
          l.verificationApprovedTitle,
          l.verificationApprovedBody,
        ),
        _ when rejected => (
          'verification.rejected',
          Icons.error_outline,
          c.statusError,
          l.verificationRejectedTitle,
          l.verificationRejectedBody,
        ),
        _ when !v.allSubmitted => (
          'verification.incomplete',
          Icons.upload_file,
          c.statusWarning,
          l.verificationIncompleteTitle,
          l.verificationIncompleteBody,
        ),
        _ => (
          'verification.pending',
          Icons.hourglass_top,
          c.statusInfo,
          l.verificationPendingTitle,
          l.verificationPendingBody,
        ),
      };
      final approved = v.status == VerificationStatus.verified;
      body = ListView(
        padding: const EdgeInsets.all(AppLayout.screenPadding),
        children: [
          const SizedBox(height: AppSpacing.s8),
          Icon(icon, size: AppSpacing.s16, color: color),
          const SizedBox(height: AppSpacing.s4),
          Text(
            title,
            key: Key(key),
            textAlign: TextAlign.center,
            style: AppTextStyles.displayMd.copyWith(color: c.ink),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: AppSpacing.s8),
          if (approved)
            PrimaryButton(
              key: const Key('verification.goHome'),
              label: l.goToRiderHome,
              onPressed: _goHome,
            )
          else
            PrimaryButton(
              key: const Key('verification.documents'),
              label: rejected || !v.allSubmitted
                  ? l.fixDocumentsButton
                  : l.viewDocumentsButton,
              onPressed: () => context.go(AppRoutes.riderDocuments),
            ),
          const SizedBox(height: AppSpacing.s3),
          OutlinedButton(
            key: const Key('verification.refresh'),
            onPressed: _load,
            child: Text(l.refreshButton),
          ),
          if (!approved) ...[
            const SizedBox(height: AppSpacing.s3),
            TextButton(
              key: const Key('verification.toSending'),
              onPressed: () => context.go(AppRoutes.home),
              child: Text(l.menuSwitchToSending),
            ),
          ],
        ],
      );
    }
    return Scaffold(
      key: const Key('screen.riderVerification'),
      appBar: AppBar(title: Text(l.verificationTitle)),
      body: SafeArea(child: body),
    );
  }
}
