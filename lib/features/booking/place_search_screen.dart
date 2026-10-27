import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/map/ridelink_map.dart' show PoweredByGeoapify;
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import 'data/booking_models.dart';
import 'data/booking_repository.dart';
import 'data/place_search_session.dart';
import 'widgets/booking_widgets.dart';

/// Opens the place search and returns the chosen place, or null if dismissed.
Future<Place?> pickPlace(BuildContext context, {required String title}) =>
    Navigator.of(context).push<Place>(
      MaterialPageRoute(builder: (_) => PlaceSearchScreen(title: title)),
    );

enum _Phase { idle, loading, results, empty, unavailable, failed }

class PlaceSearchScreen extends ConsumerStatefulWidget {
  const PlaceSearchScreen({super.key, required this.title});

  static const debounce = Duration(milliseconds: 300);

  final String title;

  @override
  ConsumerState<PlaceSearchScreen> createState() => _PlaceSearchScreenState();
}

class _PlaceSearchScreenState extends ConsumerState<PlaceSearchScreen> {
  final _controller = TextEditingController();
  late final PlaceSearchSession _session;
  Timer? _debounce;
  int _seq = 0;
  _Phase _phase = _Phase.idle;
  List<PlacePrediction> _results = const [];
  bool _selecting = false;

  @override
  void initState() {
    super.initState();
    _session = PlaceSearchSession(ref.read(bookingRepositoryProvider));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _session.discard();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final seq = ++_seq;
    if (value.trim().length < PlaceSearchSession.minChars) {
      setState(() {
        _phase = _Phase.idle;
        _results = const [];
      });
      return;
    }
    _debounce = Timer(PlaceSearchScreen.debounce, () => _search(value, seq));
  }

  Future<void> _search(String value, int seq) async {
    setState(() => _phase = _Phase.loading);
    try {
      final results = await _session.search(
        value,
        near: ref.read(lastKnownLocationProvider)?.point,
      );
      if (!mounted || seq != _seq) return;
      setState(() {
        _results = results;
        _phase = results.isEmpty ? _Phase.empty : _Phase.results;
      });
    } on MapsUnavailableException {
      if (mounted && seq == _seq) setState(() => _phase = _Phase.unavailable);
    } catch (_) {
      if (mounted && seq == _seq) setState(() => _phase = _Phase.failed);
    }
  }

  Future<void> _select(PlacePrediction prediction) async {
    if (_selecting) return;
    setState(() => _selecting = true);
    try {
      final place = await _session.select(prediction);
      if (mounted) Navigator.of(context).pop(place);
    } on MapsUnavailableException {
      if (mounted) {
        setState(() {
          _selecting = false;
          _phase = _Phase.unavailable;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _selecting = false;
          _phase = _Phase.failed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Scaffold(
      key: const Key('screen.placeSearch'),
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppLayout.screenPadding),
              child: TextField(
                key: const Key('placeSearch.input'),
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: _onChanged,
                decoration: InputDecoration(
                  hintText: l.placeSearchHint,
                  prefixIcon: Icon(Icons.search, color: c.inkMuted),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: l.clearSearch,
                          icon: Icon(Icons.close, color: c.inkMuted),
                          onPressed: () {
                            _controller.clear();
                            _onChanged('');
                          },
                        ),
                ),
              ),
            ),
            if (_selecting) LinearProgressIndicator(color: c.brand500),
            Expanded(child: _body(l, c)),
          ],
        ),
      ),
    );
  }

  Widget _body(AppLocalizations l, AppColors c) {
    switch (_phase) {
      case _Phase.idle:
        return _hint(l.placeSearchMinChars, Icons.edit_location_alt);
      case _Phase.loading:
        return const LoadingView();
      case _Phase.empty:
        return _hint(l.placeSearchNoResults, Icons.search_off);
      case _Phase.unavailable:
        return MessageView(
          key: const Key('placeSearch.unavailable'),
          icon: Icons.location_disabled,
          title: l.placeSearchUnavailable,
        );
      case _Phase.failed:
        return MessageView(
          key: const Key('placeSearch.failed'),
          icon: Icons.wifi_off,
          title: l.placeSearchFailed,
          actionLabel: l.retryButton,
          onAction: () => _onChanged(_controller.text),
        );
      case _Phase.results:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _resultList(c)),
            const PoweredByGeoapify(),
          ],
        );
    }
  }

  Widget _resultList(AppColors c) => ListView.separated(
    itemCount: _results.length,
    separatorBuilder: (_, _) => const Divider(),
    itemBuilder: (context, i) {
      final p = _results[i];
      return ListTile(
        key: Key('placeSearch.result.${p.placeId}'),
        minTileHeight: AppLayout.minTapTarget,
        leading: Icon(Icons.location_on_outlined, color: c.inkMuted),
        title: Text(
          p.primaryText,
          style: AppTextStyles.body.copyWith(color: c.ink),
        ),
        subtitle: p.secondaryText.isEmpty
            ? null
            : Text(
                p.secondaryText,
                style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
              ),
        onTap: _selecting ? null : () => _select(p),
      );
    },
  );

  Widget _hint(String text, IconData icon) => Padding(
    key: const Key('placeSearch.hint'),
    padding: const EdgeInsets.all(AppSpacing.s6),
    child: Column(
      children: [
        Icon(icon, color: context.colors.inkFaint),
        const SizedBox(height: AppSpacing.s2),
        Text(
          text,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySm.copyWith(color: context.colors.inkMuted),
        ),
      ],
    ),
  );
}
