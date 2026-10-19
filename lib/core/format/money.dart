import 'package:intl/intl.dart';

final _grouped = NumberFormat('#,##0', 'en');

/// "KES 350", "KES 1,200" (whole shillings).
String formatKes(num amount) => 'KES ${_grouped.format(amount.round())}';

/// "KES ~350" for estimates.
String formatKesEstimate(num amount) =>
    'KES ~${_grouped.format(amount.round())}';

/// "4.8 km"; whole numbers drop the decimal ("10 km").
String formatKm(num km) {
  final rounded = (km * 10).round() / 10;
  return rounded == rounded.roundToDouble()
      ? '${rounded.toInt()} km'
      : '${rounded.toStringAsFixed(1)} km';
}

/// "KES 16" for per-km rates; keeps cents when present ("KES 16.50").
String formatKesRate(num rate) {
  final cents = (rate * 100).round();
  if (cents % 100 == 0) return formatKes(cents ~/ 100);
  return 'KES ${NumberFormat('#,##0.00', 'en').format(cents / 100)}';
}
