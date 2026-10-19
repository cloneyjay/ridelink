import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/mode/app_mode.dart';
import 'core/providers.dart';
import 'core/storage/legacy_keys.dart';
import 'core/storage/local_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fonts are bundled in assets/google_fonts; never download them at runtime.
  GoogleFonts.config.allowRuntimeFetching = false;
  // Read before the first frame so the router opens the last-used side directly.
  final prefs = await SharedPreferences.getInstance();
  final localStore = SharedPrefsLocalStore(prefs);
  await removeLegacyKeys(localStore);
  runApp(
    ProviderScope(
      overrides: [
        modeStoreProvider.overrideWithValue(SharedPrefsModeStore(prefs)),
        localStoreProvider.overrideWithValue(localStore),
      ],
      child: const RideLinkApp(),
    ),
  );
}
