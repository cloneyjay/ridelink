import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/format/money.dart';
import '../../../core/location/geo_point.dart';
import '../../../core/providers.dart';
import '../../../core/realtime/realtime_event.dart';
import '../../../core/routing/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';
import '../../booking/booking_labels.dart';
import '../../booking/data/booking_models.dart';
import '../../booking/widgets/booking_widgets.dart';
import '../../common/confirm_dialog.dart';
import '../../evidence/data/evidence_models.dart';
import '../../evidence/photo_evidence_card.dart';
import '../../notifications/notifications_screen.dart';
import '../../orders/data/order_models.dart';
import '../../orders/order_providers.dart';
import '../../payments/data/payment_models.dart';
import '../../payments/late_report_card.dart';
import '../../payments/payment_validation.dart';
import '../../payments/payment_widgets.dart';
import '../../ratings/rating_sheet.dart';
import '../../tracking/terms_sheet.dart';
import '../rider_controller.dart';
import '../rider_labels.dart';
import 'job_logic.dart';

/// The rider's active job: to pickup (deadline countdown, arrival fallback), status steps,
/// and the rider-led payment step: Arrived requests payment, then Payment received (method,
/// optional M-Pesa code) completes the order, or Not paid sends it to review.
class RiderJobView extends ConsumerStatefulWidget {
  const RiderJobView({super.key, required this.order});

  final Order order;

  @override
  ConsumerState<RiderJobView> createState() => _RiderJobViewState();
}

class _RiderJobViewState extends ConsumerState<RiderJobView> {
  Timer? _ticker;
  bool _busy = false;
  String? _error;
  final _photoCard = GlobalKey<PhotoEvidenceCardState>();

  /// Photos uploaded from this screen, before the evidence chain reloads.
  final _uploaded = <MediaKind>{};

  PayMethod _method = PayMethod.cash;
  final _code = TextEditingController();
  String? _codeError;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && widget.order.status == 'accepted') setState(() {});
    });
    _promptRatingIfDone();
  }

  @override
  void didUpdateWidget(RiderJobView old) {
    super.didUpdateWidget(old);
    if (old.order.id != widget.order.id) _uploaded.clear();
    if (old.order.id != widget.order.id ||
        old.order.status != widget.order.status) {
      _method = PayMethod.cash;
      _code.clear();
      _codeError = null;
    }
    if (old.order.status != widget.order.status ||
        old.order.pickupArrivedAt != widget.order.pickupArrivedAt) {
      _error = null;
      _promptRatingIfDone();
    }
    // A realtime update may not say how payment ended (confirmed or timeout).
    if (old.order.status != widget.order.status &&
        widget.order.status == 'completed' &&
        widget.order.paymentConfirmation == null) {
      final id = widget.order.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.invalidate(orderDetailsProvider(id));
      });
    }
  }

  /// The job, with how payment ended taken from GET /orders/{id} when realtime didn't say.
  Order _withPaymentOutcome(Order o, OrderDetails? details) {
    final fetched = details?.order;
    if (o.paymentConfirmation != null ||
        fetched == null ||
        fetched.id != o.id ||
        fetched.status != o.status) {
      return o;
    }
    return o.copyWith(
      paymentConfirmation: (fetched.paymentConfirmation,),
      lateReportUntil: (fetched.lateReportUntil,),
    );
  }

  /// Completion asks the rider to rate the sender, once.
  void _promptRatingIfDone() {
    if (widget.order.status != 'completed') return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        maybePromptRating(
          context,
          ref,
          order: widget.order,
          role: OrderRole.rider,
        );
      }
    });
  }

  Future<void> _navigate(GeoPoint to) async {
    final l = AppLocalizations.of(context);
    final ok = await ref.read(navigationLauncherProvider).navigateTo(to);
    if (!ok && mounted) {
      showSnack(
        context,
        l.navigateFailed,
        key: const Key('job.navigateFailed'),
      );
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _code.dispose();
    super.dispose();
  }

  DateTime get _now => ref.read(serverNowProvider)();

  Future<void> _run(Future<Order> Function(String id) call) async {
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // A lost race (409) is shown by the rider home after re-reading the job.
      await ref.read(riderControllerProvider.notifier).runJob(call);
      if (mounted) setState(() => _busy = false);
    } on ApiException catch (e) {
      if (!mounted) return;
      final missing = e.code == 'evidence_photo_required'
          ? MediaKind.fromWire(e.body['kind'] as String?)
          : null;
      setState(() {
        _busy = false;
        _error = apiErrorText(e, l, fallback: l.jobActionFailed);
        if (missing != null) _uploaded.remove(missing);
      });
      if (missing != null) {
        ref.invalidate(evidenceChainProvider(widget.order.id));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_photoCard.currentState?.capture());
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = l.jobActionFailed;
      });
    }
  }

  Future<void> _onAction(JobAction action) async {
    final repo = ref.read(riderRepositoryProvider);
    switch (action) {
      case JobAction.arrivedAtPickup:
        await _run(repo.markArrived);
      case JobAction.arrivedAtDropoff || JobAction.requestPayment:
        await _run(repo.requestPayment);
      case JobAction.confirmPayment:
        await _received();
      case JobAction.pickedUp ||
          JobAction.startTrip ||
          JobAction.handOver ||
          JobAction.complete:
        final status = statusFor(action)!;
        await _run((id) => repo.updateStatus(id, status));
      case JobAction.none:
        return;
    }
  }

  /// The selected method if this order still offers it, otherwise cash.
  PayMethod _selectedMethod(OrderPayment? payment) {
    final choices = payment?.choices ?? const [PayMethod.cash];
    return choices.contains(_method) ? _method : PayMethod.cash;
  }

  Future<void> _received() async {
    final l = AppLocalizations.of(context);
    final method = _selectedMethod(
      ref.read(orderPaymentProvider(widget.order.id)).value,
    );
    final check = mpesaCodeFor(method, _code.text);
    if (!check.valid) {
      setState(() => _codeError = l.mpesaCodeInvalid);
      return;
    }
    setState(() => _codeError = null);
    await _run(
      (id) => ref
          .read(riderRepositoryProvider)
          .paymentReceived(id, method: method, mpesaCode: check.code),
    );
  }

  Future<void> _notReceived() async {
    final ok = await confirmNotPaid(
      context,
      keyPrefix: 'job.notReceivedDialog',
    );
    if (ok && mounted) {
      await _run(ref.read(riderRepositoryProvider).paymentNotReceived);
    }
  }

  Future<void> _cancel() async {
    final l = AppLocalizations.of(context);
    final grace = cancelGraceLeft(widget.order, _now);
    final ok = await confirmDialog(
      context,
      keyPrefix: 'job.cancelDialog',
      title: l.riderCancelTitle,
      body: grace > Duration.zero
          ? l.riderCancelWithinGrace(formatClock(grace))
          : l.riderCancelAfterGrace,
      confirmLabel: l.riderCancelConfirm,
      cancelLabel: l.riderCancelKeep,
    );
    if (ok && mounted) await _run(ref.read(riderRepositoryProvider).cancel);
  }

  String _title(AppLocalizations l, Order o) {
    final ride = o.serviceType == ServiceType.ride;
    return switch (o.status) {
      'accepted' => o.arrivedAtPickup ? l.jobAtPickup : l.jobToPickup,
      'started' => ride ? l.jobPassengerPickedUp : l.jobPickedUp,
      'in_transit' => l.jobInTransit,
      'arrived' => l.jobAtDropoff,
      'payment_requested' || 'cash_pending' => l.jobPayment,
      'paid' => l.jobPaid,
      'handed_over' => ride ? l.jobPassengerDroppedOff : l.jobHandedOver,
      'completed' => ride ? l.jobRideComplete : l.jobCompleted,
      'unresolved' => l.paymentUnderReview,
      'cancelled' => l.jobCancelled,
      _ => l.jobTitle,
    };
  }

  String _actionLabel(AppLocalizations l, JobAction a, ServiceType s) {
    final ride = s == ServiceType.ride;
    return switch (a) {
      JobAction.arrivedAtPickup => l.actionArrivedAtPickup,
      JobAction.pickedUp => ride ? l.actionPassengerPickedUp : l.actionPickedUp,
      JobAction.startTrip => l.actionStartTrip,
      JobAction.arrivedAtDropoff => l.actionArrivedAtDropoff,
      JobAction.requestPayment => l.actionRequestPayment,
      JobAction.confirmPayment => l.paymentReceivedButton,
      JobAction.handOver =>
        ride ? l.actionPassengerDroppedOff : l.actionHandOver,
      JobAction.complete => ride ? l.actionCompleteRide : l.actionComplete,
      JobAction.none => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<RealtimeEvent>>(realtimeEventsProvider, (_, next) {
      final data = next.value?.data;
      // The receiver pinned their spot: reload it from GET /orders/{id}.
      if (next.value?.kind == RealtimeEventKind.notificationCreated &&
          data?['type'] == 'receiver_location_shared' &&
          (data?['order_id'] ?? (data?['data'] as Map?)?['order_id']) ==
              widget.order.id) {
        ref.invalidate(orderDetailsProvider(widget.order.id));
      }
    });
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final details = ref.watch(orderDetailsProvider(widget.order.id)).value;
    final o = _withPaymentOutcome(widget.order, details);
    final ride = o.serviceType == ServiceType.ride;
    final canReportLate = o.canReportLate(_now);
    final action = nextAction(o);
    final photoNeeded = requiredPhoto(o, action);
    final photoMissing = photoNeeded != null && !_photoRecorded(o, photoNeeded);
    final countdown = pickupCountdown(o, _now);
    final late = countdown == Duration.zero;
    final amount = o.agreedPrice == null ? null : formatKes(o.agreedPrice!);
    final toDropoff = !{'accepted'}.contains(o.status);
    final navTarget = switch (o.status) {
      'accepted' => o.pickupLocation,
      'started' || 'in_transit' => o.dropoffLocation,
      _ => null,
    };
    final receiver = ride ? null : details?.receiverLocation;

    final collecting = action == JobAction.confirmPayment;

    final children = <Widget>[
      if (amount != null && !collecting)
        SurfaceCard(
          child: Row(
            children: [
              Icon(
                serviceIcon(o.serviceType),
                color: serviceAccent(c, o.serviceType),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Text(
                  l.agreedPrice,
                  style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
                ),
              ),
              Text(
                amount,
                key: const Key('job.price'),
                style: AppTextStyles.displaySm.copyWith(color: c.ink),
              ),
            ],
          ),
        ),
      if (late) ...[
        const SizedBox(height: AppSpacing.s4),
        Text(
          l.jobRunningLate,
          key: const Key('job.late'),
          textAlign: TextAlign.center,
          style: AppTextStyles.displayMd.copyWith(color: c.statusError),
        ),
        const SizedBox(height: AppSpacing.s1),
        Text(
          l.jobRunningLateBody,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
        ),
      ] else if (countdown != null) ...[
        const SizedBox(height: AppSpacing.s4),
        Text(
          l.reachPickupIn,
          textAlign: TextAlign.center,
          style: AppTextStyles.label.copyWith(color: c.inkMuted),
        ),
        Text(
          formatClock(countdown),
          key: const Key('job.pickupCountdown'),
          textAlign: TextAlign.center,
          style: AppTextStyles.displayXl.copyWith(
            color: countdown.inMinutes < 2 ? c.statusError : c.ink,
          ),
        ),
        if (o.pickupDeadline != null)
          Text(
            l.pickupDeadlineAt(formatDateTime(l, o.pickupDeadline!)),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
          ),
        const SizedBox(height: AppSpacing.s2),
        NoteRow(l.arrivalAutoNote),
      ],
      if (o.status == 'accepted' && o.arrivedAtPickup) ...[
        const SizedBox(height: AppSpacing.s4),
        NoteRow(
          ride ? l.jobAtPickupNoteRide : l.jobAtPickupNote,
          icon: Icons.check_circle_outline,
        ),
      ],
      const SizedBox(height: AppSpacing.s4),
      RouteSummary(
        pickup: o.pickupAddress,
        dropoff: o.dropoffAddress,
        trailing: InfoChip(
          toDropoff ? l.headingToDropoff : l.headingToPickup,
          key: const Key('job.heading'),
          icon: Icons.navigation_outlined,
        ),
      ),
      if (navTarget != null) ...[
        const SizedBox(height: AppSpacing.s3),
        OutlinedButton.icon(
          key: Key(toDropoff ? 'job.navigate.dropoff' : 'job.navigate.pickup'),
          onPressed: () => _navigate(navTarget),
          icon: const Icon(Icons.navigation_outlined),
          label: Text(toDropoff ? l.navigateToDropoff : l.navigateToPickup),
        ),
      ],
      if (details?.senderName != null) ...[
        const SizedBox(height: AppSpacing.s3),
        NoteRow(
          ride
              ? l.passengerIs(details!.senderName!)
              : l.senderIs(details!.senderName!),
          key: const Key('job.senderName'),
          icon: Icons.person_outline,
        ),
      ],
      if (o.receiverName != null && o.serviceType == ServiceType.delivery) ...[
        const SizedBox(height: AppSpacing.s3),
        NoteRow(l.receiverIs(o.receiverName!), icon: Icons.person_outline),
      ],
      if (receiver != null && !o.isTerminal) ...[
        const SizedBox(height: AppSpacing.s3),
        _ReceiverSpotCard(
          spot: receiver,
          onNavigate: () => _navigate(receiver.point),
        ),
      ],
      if (collecting) ..._collectPanel(l, c, o),
      ..._photoCards(l, o),
      ..._statusBody(l, c, o, amount),
      if (_error != null) ...[
        const SizedBox(height: AppSpacing.s3),
        InlineError(_error!, key: const Key('job.error')),
      ],
      const SizedBox(height: AppSpacing.s6),
      if (collecting) ...[
        if (photoMissing) ...[
          NoteRow(
            l.jobHandoverPhotoRequired,
            key: const Key('job.photoRequired'),
            icon: Icons.photo_camera_outlined,
          ),
          const SizedBox(height: AppSpacing.s3),
        ],
        PrimaryButton(
          key: const Key('job.paymentReceived'),
          label: l.paymentReceivedButton,
          loading: _busy,
          onPressed: photoMissing ? null : _received,
        ),
        const SizedBox(height: AppSpacing.s3),
        OutlinedButton(
          key: const Key('job.paymentNotReceived'),
          onPressed: _busy ? null : _notReceived,
          child: Text(l.paymentNotReceivedButton),
        ),
      ] else if (action != JobAction.none) ...[
        if (photoMissing) ...[
          NoteRow(
            photoNeeded == MediaKind.pickupPhoto
                ? l.jobPickupPhotoRequired
                : l.jobHandoverPhotoRequired,
            key: const Key('job.photoRequired'),
            icon: Icons.photo_camera_outlined,
          ),
          const SizedBox(height: AppSpacing.s3),
        ],
        PrimaryButton(
          key: Key('job.action.${action.name}'),
          label: _actionLabel(l, action, o.serviceType),
          loading: _busy,
          onPressed: photoMissing ? null : () => _onAction(action),
        ),
      ],
      if (canReportLate) ...[
        LateReportCard(
          keyPrefix: 'job.late',
          deadline: o.lateReportUntil!,
          busy: _busy,
          onReport: () =>
              _run(ref.read(riderRepositoryProvider).paymentNotReceived),
        ),
        const SizedBox(height: AppSpacing.s3),
      ],
      if (o.isTerminal)
        PrimaryButton(
          key: const Key('job.done'),
          label: l.doneButton,
          onPressed: () =>
              ref.read(riderControllerProvider.notifier).dismissJob(),
        ),
      if (riderCanCancel(o)) ...[
        const SizedBox(height: AppSpacing.s3),
        TextButton(
          key: const Key('job.cancel'),
          onPressed: _busy ? null : _cancel,
          child: Text(l.riderCancelButton),
        ),
      ],
      const SizedBox(height: AppSpacing.s3),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpacing.s2,
        children: [
          TextButton.icon(
            key: const Key('job.viewTerms'),
            onPressed: () =>
                showTermsSheet(context, order: o, terms: details?.terms),
            icon: const Icon(Icons.description_outlined),
            label: Text(l.viewTerms),
          ),
          TextButton.icon(
            key: const Key('job.evidence'),
            onPressed: () => context.push(AppRoutes.evidenceFor(o.id)),
            icon: const Icon(Icons.verified_user_outlined),
            label: Text(l.evidenceTitle),
          ),
        ],
      ),
    ];

    return PopScope(
      canPop: false,
      child: Scaffold(
        key: const Key('screen.riderJob'),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(_title(l, o), key: const Key('job.title')),
          actions: const [NotificationBell()],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppLayout.screenPadding),
            children: children,
          ),
        ),
      ),
    );
  }

  bool _photoRecorded(Order o, MediaKind kind) =>
      _uploaded.contains(kind) ||
      (ref
              .watch(evidenceChainProvider(o.id))
              .value
              ?.any((e) => e.mediaKind == kind) ??
          false);

  /// Deliveries: pickup photo at the pickup, handover photo at the drop-off (screen 9).
  /// Rides have no photo steps.
  List<Widget> _photoCards(AppLocalizations l, Order o) {
    final kind = photoStepFor(o);
    if (kind == null) return const [];
    return [
      const SizedBox(height: AppSpacing.s4),
      PhotoEvidenceCard(
        key: _photoCard,
        orderId: o.id,
        kind: kind,
        hint: kind == MediaKind.pickupPhoto
            ? l.evidencePickupPhotoHint
            : l.evidenceHandoverPhotoHint,
        onRecorded: () => setState(() => _uploaded.add(kind)),
      ),
    ];
  }

  /// Amount to collect, how the payer paid (cash plus the order's M-Pesa snapshot) and the
  /// optional M-Pesa code.
  List<Widget> _collectPanel(AppLocalizations l, AppColors c, Order o) {
    final payment = ref.watch(orderPaymentProvider(o.id));
    final data = payment.value;
    final choices = data?.choices ?? const [PayMethod.cash];
    final selected = _selectedMethod(data);
    final numbers = {
      for (final m in data?.methods ?? const <PaymentMethod>[]) m.type: m,
    };
    final amount = o.agreedPrice ?? data?.amount;
    return [
      SurfaceCard(
        key: const Key('job.collect'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.collectPaymentLabel,
              style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
            ),
            if (amount != null)
              Text(
                formatKes(amount),
                key: const Key('job.collectAmount'),
                style: AppTextStyles.displayLg.copyWith(color: c.ink),
              ),
            if (o.serviceType == ServiceType.delivery) ...[
              const SizedBox(height: AppSpacing.s2),
              Align(
                alignment: Alignment.centerLeft,
                child: InfoChip(
                  o.payer == Payer.receiver
                      ? l.payerReceiverOption
                      : l.riderSenderPays,
                  key: Key('job.payer.${o.payer.wire}'),
                  icon: Icons.person_outline,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.s4),
            Text(
              l.paymentHowPaidLabel,
              style: AppTextStyles.labelLg.copyWith(color: c.ink),
            ),
            const SizedBox(height: AppSpacing.s2),
            for (final m in choices) ...[
              ChoiceRow(
                key: Key('job.method.${m.wire}'),
                selected: m == selected,
                title: payMethodName(l, m),
                subtitle: numbers[m] == null
                    ? null
                    : payNumberFor(numbers[m]!).shown,
                icon: payMethodIcon(m),
                onTap: _busy
                    ? null
                    : () => setState(() {
                        _method = m;
                        _codeError = null;
                      }),
              ),
              const SizedBox(height: AppSpacing.s2),
            ],
            if (payment.isLoading)
              LinearProgressIndicator(
                key: const Key('job.methodsLoading'),
                color: c.brand500,
                backgroundColor: c.surfaceSunken,
              ),
            if (payment.hasError && !payment.isLoading) ...[
              InlineError(
                l.paymentMethodsLoadFailed,
                key: const Key('job.methodsError'),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const Key('job.methodsRetry'),
                  onPressed: () => ref.invalidate(orderPaymentProvider(o.id)),
                  child: Text(l.retryButton),
                ),
              ),
            ],
            if (selected.isMpesa) ...[
              const SizedBox(height: AppSpacing.s2),
              MpesaCodeField(
                key: const Key('job.mpesaCode'),
                controller: _code,
                errorText: _codeError,
                enabled: !_busy,
              ),
            ],
          ],
        ),
      ),
    ];
  }

  List<Widget> _statusBody(
    AppLocalizations l,
    AppColors c,
    Order o,
    String? amount,
  ) {
    final ride = o.serviceType == ServiceType.ride;
    String? text = switch (o.status) {
      'arrived' => ride ? l.jobAtDropoffBodyRide : l.jobAtDropoffBody,
      'paid' => ride ? l.jobPaidBodyRide : l.jobPaidBody,
      'completed' when o.canReportLate(_now) => null,
      'completed' when o.closedByTimeout => l.statusCompletedUnconfirmed,
      'completed' => amount == null ? null : l.jobCompletedBody(amount),
      'unresolved' => l.paymentUnderReviewRiderBody,
      'cancelled' => switch (o.cancelReason) {
        'sender' => ride ? l.jobCancelledByPassenger : l.jobCancelledBySender,
        'pickup_timeout' => l.jobCancelledTimeout,
        'rider' => l.jobCancelledByYou,
        _ => l.jobCancelledGeneric,
      },
      _ => null,
    };
    if (text == null) return const [];
    return [
      const SizedBox(height: AppSpacing.s4),
      Container(
        key: Key('job.status.${o.status}'),
        padding: const EdgeInsets.all(AppSpacing.s4),
        decoration: BoxDecoration(
          color: o.status == 'unresolved' || o.status == 'cancelled'
              ? c.statusErrorTint
              : c.surfaceSunken,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(text, style: AppTextStyles.body.copyWith(color: c.ink)),
      ),
    ];
  }
}

/// The receiver's pinned drop-off spot from the receiver link, with a hand-off to Maps.
class _ReceiverSpotCard extends StatelessWidget {
  const _ReceiverSpotCard({required this.spot, required this.onNavigate});

  final ReceiverLocation spot;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Container(
      key: const Key('job.receiverSpot'),
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: c.brand100,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.push_pin_outlined, color: c.brand700),
              const SizedBox(width: AppSpacing.s2),
              Expanded(
                child: Text(
                  l.receiverSpotTitle,
                  style: AppTextStyles.labelLg.copyWith(color: c.ink),
                ),
              ),
            ],
          ),
          if (spot.note != null) ...[
            const SizedBox(height: AppSpacing.s1),
            Text(
              l.receiverSpotNote(spot.note!),
              key: const Key('job.receiverSpot.note'),
              style: AppTextStyles.body.copyWith(color: c.ink),
            ),
          ],
          const SizedBox(height: AppSpacing.s3),
          OutlinedButton.icon(
            key: const Key('job.navigate.receiver'),
            onPressed: onNavigate,
            icon: const Icon(Icons.navigation_outlined),
            label: Text(l.navigateToReceiver),
          ),
        ],
      ),
    );
  }
}
