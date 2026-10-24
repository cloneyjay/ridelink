import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../common/confirm_dialog.dart';
import '../rider/rider_labels.dart' show formatDateTime;

/// The rider's "Not paid" confirmation, shared by the drop-off and the late report.
Future<bool> confirmNotPaid(BuildContext context, {required String keyPrefix}) {
  final l = AppLocalizations.of(context);
  return confirmDialog(
    context,
    keyPrefix: keyPrefix,
    title: l.paymentNotReceivedConfirmTitle,
    body: l.paymentNotReceivedConfirmBody,
    confirmLabel: l.paymentNotReceivedButton,
    cancelLabel: l.goBackButton,
  );
}

/// Rider, on an order the payment timeout closed, while the late-report window is open:
/// why it closed and "Not paid" (POST /payment/not-received moves it to `unresolved`).
class LateReportCard extends StatelessWidget {
  const LateReportCard({
    super.key,
    required this.keyPrefix,
    required this.deadline,
    required this.busy,
    required this.onReport,
  });

  /// Keys: `<keyPrefix>`, `<keyPrefix>.notPaid`, dialog `<keyPrefix>.dialog`.
  final String keyPrefix;

  /// `late_report_until`: the window is a platform setting.
  final DateTime deadline;
  final bool busy;

  /// Called after the rider confirms.
  final Future<void> Function() onReport;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Container(
      key: Key(keyPrefix),
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: c.surfaceSunken,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.statusCompletedUnconfirmed,
            style: AppTextStyles.labelLg.copyWith(color: c.ink),
          ),
          const SizedBox(height: AppSpacing.s1),
          Text(
            l.lateReportBody(formatDateTime(l, deadline)),
            style: AppTextStyles.body.copyWith(color: c.ink),
          ),
          const SizedBox(height: AppSpacing.s3),
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppLayout.minTapTarget,
            ),
            child: OutlinedButton(
              key: Key('$keyPrefix.notPaid'),
              onPressed: busy
                  ? null
                  : () async {
                      final ok = await confirmNotPaid(
                        context,
                        keyPrefix: '$keyPrefix.dialog',
                      );
                      if (ok) await onReport();
                    },
              child: busy
                  ? SizedBox.square(
                      dimension: AppSpacing.s4,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: c.brand500,
                      ),
                    )
                  : Text(l.paymentNotReceivedButton),
            ),
          ),
        ],
      ),
    );
  }
}
