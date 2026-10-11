import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';

void main() {
  // Fonts are bundled in assets/google_fonts; never download them at runtime.
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const ProviderScope(child: RideLinkApp()));
}
