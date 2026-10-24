import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/error_messages.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../booking/data/booking_models.dart';
import '../booking/widgets/booking_widgets.dart';
import '../orders/data/order_models.dart';
import '../orders/order_providers.dart';
import '../rider/rider_labels.dart';
import 'data/evidence_models.dart';

/// Localized name of a chain event; unknown types are shown humanized.
String evidenceEventName(
  AppLocalizations l,
  String type,
  ServiceType? s,
) => switch (type) {
  'pickup_photo' => l.evidencePickupPhoto,
  'handover_photo' =>
    s == ServiceType.ride ? l.evidenceDropoffPhoto : l.evidenceHandoverPhoto,
  'item_photo' => l.evidenceItemPhoto,
  'payment_requested' => l.evidenceEventPaymentRequested,
  'cash_payment_sent' => l.evidenceEventCashSent,
  'cash_payment_received' => l.evidenceEventCashReceived,
  'cash_payment_disputed' => l.evidenceEventCashDisputed,
  'arrived' => l.statusArrived,
  'handed_over' =>
    s == ServiceType.ride ? l.statusDroppedOff : l.statusHandedOver,
  'completed' => l.statusCompleted,
  'payment_details_viewed' => l.evidenceEventPaymentDetailsViewed,
  'payment_received' => l.evidenceEventPaymentReceived,
  'payment_not_received' => l.evidenceEventPaymentNotReceived,
  'payer_payment_response' => l.evidenceEventPayerResponse,
  'payment_timeout_closed' => l.statusCompletedUnconfirmed,
  _ =>
    type.isEmpty
        ? type
        : '${type[0].toUpperCase()}${type.substring(1).replaceAll('_', ' ')}',
};

/// "3fa9c1d2…9be0" for hash previews.
String shortHash(String hash) => hash.length <= 16
    ? hash
    : '${hash.substring(0, 8)}…${hash.substring(hash.length - 4)}';

sealed class _Verify {
  const _Verify();
}

class _VerifyIdle extends _Verify {
  const _VerifyIdle();
}

class _VerifyBusy extends _Verify {
  const _VerifyBusy();
}

class _VerifyDone extends _Verify {
  const _VerifyDone(this.result);
  final ChainVerification result;
}

class _VerifyFailed extends _Verify {
  const _VerifyFailed(this.message);
  final String message;
}

/// Screen 10: the order's evidence chain as a timeline, photos, and server-side verification.
class EvidenceRecordScreen extends ConsumerStatefulWidget {
  const EvidenceRecordScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<EvidenceRecordScreen> createState() =>
      _EvidenceRecordScreenState();
}

class _EvidenceRecordScreenState extends ConsumerState<EvidenceRecordScreen> {
  _Verify _verify = const _VerifyIdle();

  Future<void> _runVerify() async {
    final l = AppLocalizations.of(context);
    setState(() => _verify = const _VerifyBusy());
    try {
      final result = await ref
          .read(evidenceRepositoryProvider)
          .verify(widget.orderId);
      if (mounted) setState(() => _verify = _VerifyDone(result));
    } catch (e) {
      if (mounted) {
        setState(
          () => _verify = _VerifyFailed(
            apiErrorText(e, l, fallback: l.evidenceVerifyFailed),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final chain = ref.watch(evidenceChainProvider(widget.orderId));
    final details = ref.watch(orderDetailsProvider(widget.orderId)).value;
    final userId = ref.watch(currentUserIdProvider);

    Widget body;
    if (chain.hasError && !chain.hasValue) {
      body = MessageView(
        key: const Key('evidence.loadError'),
        icon: Icons.wifi_off,
        title: l.evidenceLoadFailed,
        actionLabel: l.retryButton,
        actionKey: const Key('evidence.retry'),
        onAction: () => ref.invalidate(evidenceChainProvider(widget.orderId)),
      );
    } else if (!chain.hasValue) {
      body = const LoadingView();
    } else {
      final events = chain.value!;
      body = RefreshIndicator(
        onRefresh: () =>
            ref.refresh(evidenceChainProvider(widget.orderId).future),
        child: ListView(
          padding: const EdgeInsets.all(AppLayout.screenPadding),
          children: [
            NoteRow(l.evidenceIntro, icon: Icons.verified_user_outlined),
            const SizedBox(height: AppSpacing.s4),
            _VerifyCard(state: _verify, onVerify: _runVerify),
            const SizedBox(height: AppSpacing.s6),
            Text(
              l.evidenceTimelineTitle,
              style: AppTextStyles.displaySm.copyWith(color: c.ink),
            ),
            const SizedBox(height: AppSpacing.s3),
            if (events.isEmpty)
              Text(
                l.evidenceEmpty,
                key: const Key('evidence.empty'),
                style: AppTextStyles.body.copyWith(color: c.inkMuted),
              )
            else
              for (final e in events)
                _EventTile(
                  orderId: widget.orderId,
                  event: e,
                  actor: _actorLabel(l, e, details, userId),
                  service: details?.order.serviceType,
                ),
          ],
        ),
      );
    }

    return Scaffold(
      key: const Key('screen.evidence'),
      appBar: AppBar(title: Text(l.evidenceTitle)),
      body: SafeArea(child: body),
    );
  }

  String _actorLabel(
    AppLocalizations l,
    EvidenceEvent e,
    OrderDetails? d,
    String? userId,
  ) {
    final actor = e.actorId;
    if (actor == null) return l.evidenceActorRideLink;
    if (actor == userId) return l.evidenceActorYou;
    if (d == null) return l.evidenceActorOtherParty;
    final ride = d.order.serviceType == ServiceType.ride;
    return roleFor(d, userId) == OrderRole.sender
        ? l.evidenceActorRider
        : (ride ? l.evidenceActorPassenger : l.evidenceActorSender);
  }
}

class _VerifyCard extends StatelessWidget {
  const _VerifyCard({required this.state, required this.onVerify});

  final _Verify state;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final s = state;
    final result = switch (s) {
      _VerifyDone(:final result) => result,
      _ => null,
    };
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (result != null) ...[
            Row(
              key: Key(
                result.valid
                    ? 'evidence.verify.intact'
                    : 'evidence.verify.tampered',
              ),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  result.valid ? Icons.verified : Icons.gpp_bad,
                  color: result.valid ? c.statusSuccess : c.statusError,
                  size: AppSpacing.s8,
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.valid
                            ? l.evidenceIntactTitle
                            : l.evidenceTamperedTitle,
                        style: AppTextStyles.displaySm.copyWith(color: c.ink),
                      ),
                      const SizedBox(height: AppSpacing.s1),
                      Text(
                        result.valid
                            ? l.evidenceIntactBody(result.eventCount)
                            : l.evidenceTamperedBody(result.eventCount),
                        key: const Key('evidence.verify.body'),
                        style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s3),
          ],
          if (s is _VerifyFailed) ...[
            InlineError(s.message, key: const Key('evidence.verify.error')),
            const SizedBox(height: AppSpacing.s3),
          ],
          OutlinedButton.icon(
            key: const Key('evidence.verify'),
            onPressed: s is _VerifyBusy ? null : onVerify,
            icon: s is _VerifyBusy
                ? SizedBox.square(
                    dimension: AppSpacing.s4,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: c.brand500,
                    ),
                  )
                : const Icon(Icons.fact_check_outlined),
            label: Text(
              result == null ? l.evidenceVerifyButton : l.evidenceVerifyAgain,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({
    required this.orderId,
    required this.event,
    required this.actor,
    required this.service,
  });

  final String orderId;
  final EvidenceEvent event;
  final String actor;
  final ServiceType? service;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final time = event.time;
    final mediaId = event.mediaId;
    return Padding(
      key: Key('evidence.event.${event.seq}'),
      padding: const EdgeInsets.only(bottom: AppSpacing.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppSpacing.s8,
            height: AppSpacing.s8,
            decoration: BoxDecoration(
              color: c.brand100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              event.mediaKind != null
                  ? Icons.photo_camera_outlined
                  : Icons.receipt_long_outlined,
              size: AppSpacing.s4,
              color: c.brand700,
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evidenceEventName(l, event.eventType, service),
                  style: AppTextStyles.labelLg.copyWith(color: c.ink),
                ),
                Text(
                  time == null ? actor : '$actor · ${formatDateTime(l, time)}',
                  style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
                ),
                if (event.eventHash.isNotEmpty)
                  Text(
                    l.evidenceHash(shortHash(event.eventHash)),
                    style: AppTextStyles.mono.copyWith(color: c.inkFaint),
                  ),
                if (mediaId != null) ...[
                  const SizedBox(height: AppSpacing.s2),
                  _EvidencePhoto(orderId: orderId, mediaId: mediaId),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Loaded through Go with the session token (no public URL).
class _EvidencePhoto extends ConsumerWidget {
  const _EvidencePhoto({required this.orderId, required this.mediaId});

  final String orderId;
  final String mediaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final key = (orderId: orderId, mediaId: mediaId);
    final photo = ref.watch(evidencePhotoProvider(key));
    const size = AppSpacing.s16 + AppSpacing.s8;
    Widget child;
    if (photo.hasValue) {
      child = Image.memory(
        photo.value!,
        key: Key('evidence.photo.$mediaId'),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            Icon(Icons.broken_image_outlined, color: c.inkFaint),
      );
    } else if (photo.hasError) {
      child = Center(
        child: IconButton(
          key: Key('evidence.photo.$mediaId.retry'),
          tooltip: l.retryButton,
          icon: Icon(Icons.refresh, color: c.inkMuted),
          onPressed: () => ref.invalidate(evidencePhotoProvider(key)),
        ),
      );
    } else {
      child = Center(
        child: SizedBox.square(
          dimension: AppSpacing.s5,
          child: CircularProgressIndicator(strokeWidth: 2, color: c.brand500),
        ),
      );
    }
    return Semantics(
      button: photo.hasValue,
      label: l.evidenceOpenPhoto,
      child: GestureDetector(
        onTap: photo.hasValue
            ? () => showDialog<void>(
                context: context,
                builder: (_) => Dialog(
                  key: const Key('evidence.photoDialog'),
                  clipBehavior: Clip.antiAlias,
                  child: InteractiveViewer(child: Image.memory(photo.value!)),
                ),
              )
            : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            width: size,
            height: size,
            color: c.surfaceSunken,
            child: child,
          ),
        ),
      ),
    );
  }
}
