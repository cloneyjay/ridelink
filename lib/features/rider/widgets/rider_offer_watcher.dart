import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../rider_controller.dart';

/// Brings an online rider back to the rider home when a new offer arrives while they're on
/// another screen. Does nothing until the rider side has been opened this session, so plain
/// senders never trigger rider calls.
class RiderOfferWatcher extends ConsumerWidget {
  const RiderOfferWatcher({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.exists(riderControllerProvider)) {
      ref.listen<String?>(riderControllerProvider.select((s) => s.offer?.id), (
        previous,
        next,
      ) {
        if (next != null && next != previous) context.go(AppRoutes.riderHome);
      });
    }
    return child;
  }
}
