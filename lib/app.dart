import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'core/routing/app_router.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';

class RideLinkApp extends ConsumerStatefulWidget {
  const RideLinkApp({super.key});

  @override
  ConsumerState<RideLinkApp> createState() => _RideLinkAppState();
}

class _RideLinkAppState extends ConsumerState<RideLinkApp> {
  @override
  void initState() {
    super.initState();
    ref.read(sessionManagerProvider).restore();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(realtimeLifecycleProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: ref.watch(routerProvider),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      // Device locale, falling back to English.
      localeResolutionCallback: (locale, supported) => supported.firstWhere(
        (s) => s.languageCode == locale?.languageCode,
        orElse: () => const Locale('en'),
      ),
    );
  }
}
