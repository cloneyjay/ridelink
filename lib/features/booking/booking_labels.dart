import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import 'data/booking_models.dart';

String serviceName(AppLocalizations l, ServiceType t) => switch (t) {
  ServiceType.delivery => l.serviceDelivery,
  ServiceType.ride => l.serviceRide,
};

IconData serviceIcon(ServiceType t) => switch (t) {
  ServiceType.delivery => Symbols.package_2,
  ServiceType.ride => Symbols.two_wheeler,
};

Color serviceAccent(AppColors c, ServiceType t) => switch (t) {
  ServiceType.delivery => c.brand500,
  ServiceType.ride => c.ride500,
};

Color serviceTint(AppColors c, ServiceType t) => switch (t) {
  ServiceType.delivery => c.brand100,
  ServiceType.ride => c.ride100,
};

String valueBandLabel(AppLocalizations l, ValueBand b) => switch (b) {
  ValueBand.under500 => l.valueBandUnder500,
  ValueBand.from500To2000 => l.valueBand500To2000,
  ValueBand.from2000To5000 => l.valueBand2000To5000,
  ValueBand.from5000To10000 => l.valueBand5000To10000,
};

/// Localized category name by server code; unknown codes fall back to the code itself.
String categoryLabel(AppLocalizations l, String code) => switch (code) {
  'documents' => l.categoryDocuments,
  'food' => l.categoryFood,
  'electronics' => l.categoryElectronics,
  'clothing' => l.categoryClothing,
  'fragile' => l.categoryFragile,
  'medication' => l.categoryMedication,
  'cash' => l.categoryCash,
  'alcohol' => l.categoryAlcohol,
  'other' => l.categoryOther,
  _ =>
    code.isEmpty
        ? code
        : '${code[0].toUpperCase()}${code.substring(1).replaceAll('_', ' ')}',
};

/// "Moses O." -> "MO".
String initialsOf(String name) {
  final parts = name
      .split(RegExp(r'\s+'))
      .map((p) => p.replaceAll('.', ''))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '';
  return parts.take(2).map((p) => p[0].toUpperCase()).join();
}
