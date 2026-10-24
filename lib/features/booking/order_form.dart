import '../../l10n/app_localizations.dart';
import 'data/booking_models.dart';

String? validateReceiverName(String? value, AppLocalizations l) =>
    (value ?? '').trim().isEmpty ? l.errorReceiverRequired : null;

String? validateDescription(String? value, AppLocalizations l) =>
    (value ?? '').trim().isEmpty ? l.errorDescriptionRequired : null;

/// Optional; when given it must be a number above zero ("0,5" accepted).
String? validateWeight(String? value, AppLocalizations l) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return null;
  final weight = parseWeight(text);
  return weight == null || weight <= 0 ? l.errorWeightInvalid : null;
}

double? parseWeight(String text) {
  final t = text.trim().replaceAll(',', '.');
  return t.isEmpty ? null : double.tryParse(t);
}

String? validateValueBand(ValueBand? band, AppLocalizations l) =>
    band == null ? l.errorValueBandRequired : null;

String? validateCategory(String? categoryId, AppLocalizations l) =>
    categoryId == null ? l.errorCategoryRequired : null;

/// Rides carry only the route; deliveries add the receiver, the declaration and who pays.
CreateOrderInput buildCreateOrderInput({
  required ServiceType service,
  required Place pickup,
  required Place dropoff,
  String? receiverName,
  String? categoryId,
  String? description,
  String? weightText,
  ValueBand? valueBand,
  Payer payer = Payer.sender,
}) {
  final route = RouteInput(pickup: pickup, dropoff: dropoff);
  if (service == ServiceType.ride) {
    return CreateOrderInput(serviceType: service, route: route);
  }
  return CreateOrderInput(
    serviceType: service,
    route: route,
    receiverName: receiverName!.trim(),
    payer: payer,
    declaration: DeclarationInput(
      categoryId: categoryId!,
      description: description!.trim(),
      weightKg: parseWeight(weightText ?? ''),
      valueBand: valueBand!,
    ),
  );
}
