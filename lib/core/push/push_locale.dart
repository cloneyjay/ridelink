import 'dart:ui';

import '../../l10n/app_localizations.dart';
import '../storage/local_store.dart';

/// The language the app last resolved to, so a background isolate (no BuildContext) shows
/// push text in the same language as the app.
const localeStoreKey = 'ridelink.locale';

Locale resolveAppLocale(Locale? device) =>
    AppLocalizations.supportedLocales.firstWhere(
      (s) => s.languageCode == device?.languageCode,
      orElse: () => const Locale('en'),
    );

Future<void> saveAppLocale(LocalStore store, Locale locale) async {
  if (store.getString(localeStoreKey) == locale.languageCode) return;
  await store.setString(localeStoreKey, locale.languageCode);
}

/// The saved app language, else the device language, else English.
AppLocalizations localizationsFor({String? saved, Locale? device}) {
  final locale = saved != null && saved.isNotEmpty
      ? resolveAppLocale(Locale(saved))
      : resolveAppLocale(device);
  return lookupAppLocalizations(locale);
}
