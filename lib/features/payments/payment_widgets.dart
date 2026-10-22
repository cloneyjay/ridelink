import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import 'data/payment_models.dart';

String payMethodName(AppLocalizations l, PayMethod m) => switch (m) {
  PayMethod.cash => l.payMethodCash,
  PayMethod.mpesaTill => l.payMethodMpesaTill,
  PayMethod.mpesaPochi => l.payMethodMpesaPochi,
  PayMethod.mpesaSendMoney => l.payMethodMpesaSendMoney,
};

IconData payMethodIcon(PayMethod m) => switch (m) {
  PayMethod.cash => Icons.payments_outlined,
  PayMethod.mpesaTill => Icons.storefront_outlined,
  PayMethod.mpesaPochi => Icons.account_balance_wallet_outlined,
  PayMethod.mpesaSendMoney => Icons.send_to_mobile_outlined,
};

/// One selectable option in a single-choice list (radio semantics, 44 dp minimum).
class ChoiceRow extends StatelessWidget {
  const ChoiceRow({
    super.key,
    required this.selected,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.icon,
  });

  final bool selected;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: Material(
        color: selected ? c.brand100 : c.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: selected ? c.brand500 : c.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppLayout.minTapTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s3,
                vertical: AppSpacing.s2,
              ),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: AppSpacing.s5,
                    color: selected ? c.brand700 : c.inkFaint,
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  if (icon != null) ...[
                    Icon(icon, size: AppSpacing.s5, color: c.inkMuted),
                    const SizedBox(width: AppSpacing.s2),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.labelLg.copyWith(color: c.ink),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
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
          ),
        ),
      ),
    );
  }
}

/// Optional M-Pesa transaction code: letters and digits, up to 10, shown uppercase.
class MpesaCodeField extends StatelessWidget {
  const MpesaCodeField({
    super.key,
    required this.controller,
    this.errorText,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return TextField(
      controller: controller,
      enabled: enabled,
      textCapitalization: TextCapitalization.characters,
      autocorrect: false,
      enableSuggestions: false,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
        LengthLimitingTextInputFormatter(10),
      ],
      decoration: InputDecoration(
        labelText: l.mpesaCodeLabel,
        helperText: l.mpesaCodeHelp,
        helperMaxLines: 2,
        errorText: errorText,
        errorMaxLines: 2,
      ),
    );
  }
}
