import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/realtime/realtime_event.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_dimensions.dart';
import '../../booking/widgets/booking_widgets.dart';
import 'public_profile_models.dart';
import 'public_profile_providers.dart';
import 'public_profile_view.dart';

/// A sender's public profile as a rider sees it (offer or active order only). When the
/// server stops allowing it (404: the offer or order ended) the screen closes itself.
class SenderProfileScreen extends ConsumerStatefulWidget {
  const SenderProfileScreen({super.key, required this.senderId});

  final String senderId;

  static Future<void> open(BuildContext context, String senderId) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SenderProfileScreen(senderId: senderId),
        ),
      );

  @override
  ConsumerState<SenderProfileScreen> createState() =>
      _SenderProfileScreenState();
}

class _SenderProfileScreenState extends ConsumerState<SenderProfileScreen> {
  bool _closing = false;

  void _close() {
    if (_closing || !mounted) return;
    _closing = true;
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    Navigator.of(context).maybePop();
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const Key('senderProfile.unavailable'),
          content: Text(l.publicProfileUnavailable),
        ),
      );
  }

  void _reload() =>
      ref.invalidate(senderPublicProfileProvider(widget.senderId));

  @override
  Widget build(BuildContext context) {
    final provider = senderPublicProfileProvider(widget.senderId);
    ref.listen<AsyncValue<PublicProfile>>(provider, (_, next) {
      final e = next.error;
      if (e is ApiException && e.statusCode == 404) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _close());
      }
    });
    // An offer or order ending can revoke access: re-check so a 404 closes the screen.
    ref.listen<AsyncValue<RealtimeEvent>>(realtimeEventsProvider, (_, next) {
      final kind = next.value?.kind;
      if (kind == RealtimeEventKind.offerResolved ||
          kind == RealtimeEventKind.orderUpdated) {
        _reload();
      }
    });
    final l = AppLocalizations.of(context);
    final profile = ref.watch(provider);
    final Widget body;
    if (profile.hasValue && !profile.hasError) {
      body = RefreshIndicator(
        onRefresh: () =>
            ref.refresh(provider.future).then((_) {}, onError: (_) {}),
        child: ListView(
          padding: const EdgeInsets.all(AppLayout.screenPadding),
          children: [PublicProfileView(profile: profile.value!)],
        ),
      );
    } else if (profile.hasError) {
      final e = profile.error;
      body = e is ApiException && e.statusCode == 404
          ? const SizedBox.shrink()
          : MessageView(
              key: const Key('senderProfile.error'),
              icon: Icons.wifi_off,
              title: l.publicProfileLoadFailed,
              actionLabel: l.retryButton,
              actionKey: const Key('senderProfile.retry'),
              onAction: _reload,
            );
    } else {
      body = const LoadingView();
    }
    return Scaffold(
      key: const Key('screen.senderProfile'),
      appBar: AppBar(title: Text(l.senderProfileTitle)),
      body: SafeArea(child: body),
    );
  }
}
