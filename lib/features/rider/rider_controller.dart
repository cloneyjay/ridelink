import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart' show AppLifecycleListener;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/location/geo_point.dart';
import '../../core/location/location_service.dart';
import '../../core/location/location_tracker.dart';
import '../../core/providers.dart';
import '../../core/realtime/realtime_event.dart';
import '../../l10n/app_localizations.dart';
import '../booking/data/booking_models.dart';
import '../restrictions/data/restriction_models.dart';
import '../restrictions/restriction_providers.dart';
import 'data/rider_models.dart';

/// Why the rider can't go online right now.
sealed class OnlineBlock {
  const OnlineBlock();
}

class BlockNotVerified extends OnlineBlock {
  const BlockNotVerified();
}

class BlockDocuments extends OnlineBlock {
  const BlockDocuments(this.documents);
  final List<DocType> documents;
}

class BlockPaused extends OnlineBlock {
  const BlockPaused({required this.until, this.reason, this.failures = 0});
  final DateTime until;
  final String? reason;
  final int failures;
}

class BlockLocation extends OnlineBlock {
  const BlockLocation(this.result);
  final LocationResult result;
}

/// 403 `account_suspended`: offline until the suspension ends (D6).
class BlockSuspended extends OnlineBlock {
  const BlockSuspended(this.status);
  final AccountStatus status;
}

class BlockError extends OnlineBlock {
  const BlockError(this.error);

  /// An [ApiException] or other failure; shown through apiErrorText.
  final Object error;
}

/// How an offer left the screen without being accepted.
enum OfferEnd { expired, declined, taken, cancelled }

/// Result of Accept, for the offer screen's message.
enum AcceptResult {
  accepted,
  needsLocation,
  paused,
  suspended,
  unavailable,
  conflict,
  failed,
}

class RiderState {
  const RiderState({
    this.loading = true,
    this.loadFailed = false,
    this.profile,
    this.verification,
    this.offer,
    this.job,
    this.block,
    this.toggling = false,
    this.lastOfferEnd,
    this.conflict,
  });

  final bool loading;
  final bool loadFailed;

  /// Null once loaded means the user isn't registered as a rider.
  final RiderProfile? profile;
  final Verification? verification;
  final RiderOffer? offer;
  final Order? job;
  final OnlineBlock? block;
  final bool toggling;
  final OfferEnd? lastOfferEnd;

  /// One-shot: an order action lost a race (409); the home shows it while state is re-read.
  final ApiException? conflict;

  bool get registered => profile != null;
  bool get online => profile?.isOnline ?? false;

  RiderState copyWith({
    bool? loading,
    bool? loadFailed,
    RiderProfile? profile,
    Verification? verification,
    RiderOffer? offer,
    bool clearOffer = false,
    Order? job,
    bool clearJob = false,
    OnlineBlock? block,
    bool clearBlock = false,
    bool? toggling,
    OfferEnd? lastOfferEnd,
    bool clearOfferEnd = false,
    ApiException? conflict,
    bool clearConflict = false,
  }) => RiderState(
    loading: loading ?? this.loading,
    loadFailed: loadFailed ?? this.loadFailed,
    profile: profile ?? this.profile,
    verification: verification ?? this.verification,
    offer: clearOffer ? null : (offer ?? this.offer),
    job: clearJob ? null : (job ?? this.job),
    block: clearBlock ? null : (block ?? this.block),
    toggling: toggling ?? this.toggling,
    lastOfferEnd: clearOfferEnd ? null : (lastOfferEnd ?? this.lastOfferEnd),
    conflict: clearConflict ? null : (conflict ?? this.conflict),
  );
}

/// Rider side state: profile, online status, location sharing, the pending offer and the
/// active job. Kept alive app-wide so location keeps flowing while online.
final riderControllerProvider = NotifierProvider<RiderController, RiderState>(
  RiderController.new,
);

class RiderController extends Notifier<RiderState> {
  static const locationInterval = Duration(seconds: 10);
  static const _minSendGap = Duration(seconds: 8);

  StreamSubscription<GeoPoint>? _tracking;
  DateTime? _lastSent;
  late LocationTracker _tracker;

  @override
  RiderState build() {
    _tracker = ref.read(locationTrackerProvider);
    ref.listen<AsyncValue<RealtimeEvent>>(realtimeEventsProvider, (_, next) {
      final event = next.value;
      if (event != null) _onEvent(event);
    });
    // Realtime may have dropped while in the background: re-read the server's state.
    final lifecycle = AppLifecycleListener(onResume: _resync);
    ref.onDispose(lifecycle.dispose);
    ref.onDispose(() => _stopTracking());
    Future.microtask(load);
    return const RiderState();
  }

  DateTime _now() => ref.read(clockProvider)();
  DateTime _serverNow() => ref.read(serverNowProvider)();

  Future<void> load() async {
    state = state.copyWith(loading: true, loadFailed: false);
    final repo = ref.read(riderRepositoryProvider);
    try {
      final profile = await repo.me();
      if (profile == null) {
        state = const RiderState(loading: false);
        return;
      }
      final results = await Future.wait<Object?>([
        repo.verification().then<Object?>((v) => v, onError: (_) => null),
        repo.active(),
      ]);
      final verification = results[0] as Verification?;
      final active = results[1]! as RiderActive;
      state = RiderState(
        loading: false,
        profile: profile,
        verification: verification,
        offer: active.offer,
        job: active.order,
        block: _blockFrom(profile, verification),
      );
      _syncTracking();
    } catch (_) {
      state = state.copyWith(loading: false, loadFailed: true);
    }
  }

  /// Blocks known before tapping the toggle, from GET /riders/me and /verification.
  OnlineBlock? _blockFrom(RiderProfile p, Verification? v) {
    if (p.verificationStatus != VerificationStatus.verified) {
      return const BlockNotVerified();
    }
    if (p.pausedAt(_serverNow())) {
      return BlockPaused(
        until: p.pausedUntil!,
        reason: p.pauseReason,
        failures: p.pauseFailures,
      );
    }
    final missing = v?.notCurrent ?? const [];
    if (missing.isNotEmpty) return BlockDocuments(missing);
    return null;
  }

  Future<void> refreshVerification() async {
    try {
      final v = await ref.read(riderRepositoryProvider).verification();
      final p = state.profile;
      final block = p == null ? null : _blockFrom(p, v);
      state = state.copyWith(
        verification: v,
        block: block,
        clearBlock: block == null,
      );
    } catch (_) {}
  }

  void profileUpdated(RiderProfile profile) {
    state = state.copyWith(profile: profile.copyWith(isOnline: state.online));
  }

  /// Re-reads GET /riders/me/active. [announceEnd] reports a vanished offer as expired; a
  /// conflict re-read has already shown its own message.
  /// [endedOrderId]: the job an action was just run on; if it is no longer active, its final
  /// state from GET /orders/{id} is shown (e.g. cancelled by the sender) until dismissed.
  Future<void> refreshActive({
    bool announceEnd = true,
    String? endedOrderId,
  }) async {
    try {
      final active = await ref.read(riderRepositoryProvider).active();
      final ended = active.order == null && endedOrderId != null
          ? await _finalState(endedOrderId)
          : null;
      final keep = ended ?? _keepTerminal();
      final hadOffer = state.offer;
      final gone =
          announceEnd && hadOffer != null && active.offer?.id != hadOffer.id;
      state = state.copyWith(
        offer: active.offer,
        clearOffer: active.offer == null,
        job: active.order ?? keep,
        clearJob: active.order == null && keep == null,
        lastOfferEnd: gone && active.order == null ? OfferEnd.expired : null,
      );
      _syncTracking();
    } catch (_) {}
  }

  Future<Order?> _finalState(String orderId) async {
    try {
      final order = (await ref.read(ordersRepositoryProvider).details(orderId))
          .order;
      return order.id == orderId && order.isTerminal ? order : null;
    } catch (_) {
      return null;
    }
  }

  // A finished job stays on screen until the rider dismisses it.
  Order? _keepTerminal() {
    final job = state.job;
    return job != null && job.isTerminal ? job : null;
  }

  void _resync() {
    if (state.registered) unawaited(refreshActive());
  }

  void clearOfferEnd() => state = state.copyWith(clearOfferEnd: true);

  void clearConflict() => state = state.copyWith(clearConflict: true);

  /// A 409 on an order action: surface it once and re-read the server's truth. Never retries.
  Future<void> resolveConflict(ApiException e, {String? orderId}) async {
    state = state.copyWith(conflict: e);
    await refreshActive(announceEnd: false, endedOrderId: orderId);
  }

  // ---- online toggle and location ----

  Future<void> setOnline(bool online) async {
    final profile = state.profile;
    if (profile == null || state.toggling) return;
    state = state.copyWith(toggling: true, clearBlock: true);
    final repo = ref.read(riderRepositoryProvider);
    try {
      if (!online) {
        final updated = await repo.setOnline(false);
        state = state.copyWith(
          profile: updated.copyWith(pausedUntil: profile.pausedUntil),
          toggling: false,
        );
        _syncTracking();
        return;
      }
      final location = await ref.read(locationServiceProvider).requestAndGet();
      if (location is! LocationFound) {
        state = state.copyWith(toggling: false, block: BlockLocation(location));
        return;
      }
      await _tracker.requestNotificationPermission();
      // Accepting needs a fresh location, so send one before going online.
      await _send(location.point, force: true);
      final updated = await repo.setOnline(true);
      state = state.copyWith(
        profile: updated.copyWith(clearPause: true),
        toggling: false,
      );
      _syncTracking();
    } on ApiException catch (e) {
      state = state.copyWith(toggling: false, block: _blockFromError(e));
    } catch (e) {
      state = state.copyWith(toggling: false, block: BlockError(e));
    }
  }

  OnlineBlock _blockFromError(ApiException e) {
    if (e.code == accountSuspendedCode) {
      ref.invalidate(accountStatusProvider);
      return BlockSuspended(AccountStatus.fromSuspendedError(e.body));
    }
    if (e.code == 'rider_paused' || e.body['paused_until'] is String) {
      final until = DateTime.tryParse('${e.body['paused_until']}');
      if (until != null) {
        return BlockPaused(
          until: until,
          reason: state.profile?.pauseReason ?? 'missed_pickups',
          failures: state.profile?.pauseFailures ?? 0,
        );
      }
    }
    if (e.code == 'documents_missing' ||
        e.message.startsWith('documents missing or expired')) {
      return BlockDocuments(_documentsFrom(e));
    }
    if (e.code == 'rider_not_verified' ||
        (e.statusCode == 403 && e.message.contains('verified'))) {
      return const BlockNotVerified();
    }
    return BlockError(e);
  }

  static List<DocType> _documentsFrom(ApiException e) {
    final list = e.body['documents'];
    final raw = list is List
        ? list.map((d) => '$d')
        : e.message.contains(':')
        ? e.message.split(':').last.split(',').map((s) => s.trim())
        : const <String>[];
    return [for (final w in raw) ?DocType.fromWire(w)];
  }

  bool get _shouldTrack => state.online || (state.job?.isActiveJob ?? false);

  void _syncTracking() {
    if (_shouldTrack) {
      _startTracking();
    } else {
      _stopTracking();
    }
  }

  void _startTracking() {
    if (_tracking != null) return;
    final l = _strings();
    _tracking = _tracker
        .start(
          notice: TrackingNotice(
            title: l.onlineNotificationTitle,
            body: l.onlineNotificationBody,
            channelName: l.onlineNotificationChannel,
          ),
          interval: locationInterval,
        )
        .listen((p) => _send(p), onError: (Object _) {});
  }

  void _stopTracking() {
    final sub = _tracking;
    _tracking = null;
    if (sub == null) return;
    sub.cancel();
    _tracker.stop();
  }

  bool get isTracking => _tracking != null;

  Future<void> _send(GeoPoint p, {bool force = false}) async {
    final now = _now();
    if (!force &&
        _lastSent != null &&
        now.difference(_lastSent!) < _minSendGap) {
      return;
    }
    _lastSent = now;
    try {
      await ref.read(riderRepositoryProvider).updateLocation(p);
    } catch (_) {
      if (force) rethrow;
    }
  }

  static AppLocalizations _strings() {
    try {
      return lookupAppLocalizations(PlatformDispatcher.instance.locale);
    } catch (_) {
      return lookupAppLocalizations(const Locale('en'));
    }
  }

  // ---- offers ----

  Future<AcceptResult> acceptOffer() async {
    final offer = state.offer;
    if (offer == null) return AcceptResult.unavailable;
    final repo = ref.read(riderRepositoryProvider);
    try {
      // Acceptance fixes the pickup window from a fresh position.
      final location = await ref.read(locationServiceProvider).current();
      if (location is LocationFound) await _send(location.point, force: true);
    } catch (_) {}
    try {
      final order = await repo.acceptOffer(offer.orderId);
      state = state.copyWith(clearOffer: true, job: order);
      _syncTracking();
      return AcceptResult.accepted;
    } on ApiException catch (e) {
      if (e.isConflict) {
        await resolveConflict(e);
        return AcceptResult.conflict;
      }
      switch (e.statusCode) {
        case 422:
          return AcceptResult.needsLocation;
        case 403:
          state = state.copyWith(block: _blockFromError(e));
          if (state.block is BlockPaused) {
            state = state.copyWith(clearOffer: true);
            return AcceptResult.paused;
          }
          if (state.block is BlockSuspended) {
            state = state.copyWith(clearOffer: true);
            return AcceptResult.suspended;
          }
          return AcceptResult.failed;
        case 404:
          state = state.copyWith(
            clearOffer: true,
            lastOfferEnd: OfferEnd.taken,
          );
          return AcceptResult.unavailable;
      }
      return AcceptResult.failed;
    } catch (_) {
      return AcceptResult.failed;
    }
  }

  Future<bool> declineOffer() async {
    final offer = state.offer;
    if (offer == null) return true;
    try {
      await ref.read(riderRepositoryProvider).declineOffer(offer.orderId);
      state = state.copyWith(clearOffer: true, lastOfferEnd: OfferEnd.declined);
      return true;
    } on ApiException catch (e) {
      if (e.isConflict) {
        await resolveConflict(e);
        return true;
      }
      if (e.statusCode == 404 || e.statusCode == 422) {
        state = state.copyWith(
          clearOffer: true,
          lastOfferEnd: OfferEnd.expired,
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ---- job ----

  /// Runs a job action; on success the returned order replaces the job. A 409 is resolved
  /// by re-reading the server ([resolveConflict]) and returns false; other failures throw
  /// [ApiException].
  Future<bool> runJob(Future<Order> Function(String orderId) call) async {
    final job = state.job;
    if (job == null) return true;
    try {
      _setJob(await call(job.id));
      return true;
    } on ApiException catch (e) {
      if (!e.isConflict) rethrow;
      await resolveConflict(e, orderId: job.id);
      return false;
    }
  }

  void _setJob(Order order) {
    state = state.copyWith(job: order);
    _syncTracking();
  }

  /// Leave a finished job and go back to the idle home.
  void dismissJob() {
    state = state.copyWith(clearJob: true);
    _syncTracking();
  }

  // ---- realtime ----

  void _onEvent(RealtimeEvent event) {
    if (!state.registered) return;
    final data = event.data;
    switch (event.kind) {
      case RealtimeEventKind.connected:
        _resync();
      case RealtimeEventKind.offerReceived:
        unawaited(refreshActive());
      case RealtimeEventKind.offerResolved:
        final offer = state.offer;
        if (offer == null) return;
        final matches =
            data['offer_id'] == offer.id ||
            (data['offer_id'] == null && data['order_id'] == offer.orderId);
        if (!matches) return;
        // Any outcome, known or not, ends this offer (a sender cancel may arrive with no
        // order.updated): dismiss it and let the server say what is current.
        final outcome = data['outcome'];
        state = state.copyWith(
          clearOffer: true,
          lastOfferEnd: switch (outcome) {
            'accepted' => null,
            'declined' => OfferEnd.declined,
            'cancelled' => OfferEnd.cancelled,
            // "expired" and any outcome this build doesn't know.
            _ => OfferEnd.expired,
          },
        );
        unawaited(refreshActive(announceEnd: false));
      case RealtimeEventKind.orderUpdated:
        final orderId = data['order_id'];
        final job = state.job;
        if (job != null && job.id == orderId) {
          _setJob(job.applyUpdate(data));
          return;
        }
        final offer = state.offer;
        if (offer != null &&
            offer.orderId == orderId &&
            data['status'] == 'cancelled') {
          state = state.copyWith(
            clearOffer: true,
            lastOfferEnd: OfferEnd.cancelled,
          );
        }
      default:
        return;
    }
  }
}
