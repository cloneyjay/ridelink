import '../data/rider_models.dart';

enum SettingsField {
  pickupRadius,
  maxDistance,
  deliveryRate,
  rideRate,
  maxWeight,
}

enum SettingsError {
  required,
  notNumber,
  mustBePositive,
  tooHigh,
  tooLow,
  outOfRange,
}

/// Parses "1.8" or "1,8"; null when not a number.
double? parseNumber(String raw) =>
    double.tryParse(raw.trim().replaceAll(',', '.'));

// Column capacities on the server; not product caps.
const _maxWeightKg = 1000000.0;
const _maxDistanceKm = 1000000.0;

/// Checks every field against GET /riders/me/limits (pricing decisions 5, 13, 15).
Map<SettingsField, SettingsError> validateSettings(
  Map<SettingsField, String> raw,
  RiderLimits limits,
) {
  final errors = <SettingsField, SettingsError>{};
  for (final field in SettingsField.values) {
    final text = raw[field] ?? '';
    if (text.trim().isEmpty) {
      errors[field] = SettingsError.required;
      continue;
    }
    final v = parseNumber(text);
    if (v == null) {
      errors[field] = SettingsError.notNumber;
      continue;
    }
    if (v <= 0) {
      errors[field] = SettingsError.mustBePositive;
      continue;
    }
    final error = switch (field) {
      SettingsField.pickupRadius =>
        v > limits.maxPickupRadiusKm ? SettingsError.tooHigh : null,
      SettingsField.maxDistance =>
        v < limits.minMaxDistanceKm
            ? SettingsError.tooLow
            : v >= _maxDistanceKm
            ? SettingsError.tooHigh
            : null,
      SettingsField.deliveryRate =>
        limits.deliveryRate.contains(v) ? null : SettingsError.outOfRange,
      SettingsField.rideRate =>
        limits.rideRate.contains(v) ? null : SettingsError.outOfRange,
      SettingsField.maxWeight =>
        v >= _maxWeightKg ? SettingsError.tooHigh : null,
    };
    if (error != null) errors[field] = error;
  }
  return errors;
}
