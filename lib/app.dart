import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'core/push/push_locale.dart';
import 'core/push/push_providers.dart';
import 'core/routing/app_router.dart';
import 'core/version/version_gate.dart';
import 'features/gates/app_gates.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';

class RideLinkApp extends ConsumerStatefulWidget {
  const RideLinkApp({super.key});

  @override
  ConsumerState<RideLinkApp> createState() => _RideLinkAppState();
}

class _RideLinkAppState extends ConsumerState<RideLinkApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    ref.read(userDataLifecycleProvider);
    ref.read(sessionManagerProvider).restore();
    unawaited(ref.read(versionGateProvider.notifier).check());
    _lifecycle = AppLifecycleListener(
      onResume: () {
        ref.read(sessionManagerProvider).ensureFresh();
        unawaited(ref.read(versionGateProvider.notifier).check());
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(realtimeLifecycleProvider);
    ref.watch(pushLifecycleProvider);
    ref.watch(userDataLifecycleProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => AppGates(child: child!),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      // Device locale, falling back to English; remembered for background push text.
      localeResolutionCallback: (locale, supported) {
        final resolved = resolveAppLocale(locale);
        unawaited(ref.read(pushPreferencesProvider).saveLocale(resolved));
        return resolved;
      },
    );
  }
}
