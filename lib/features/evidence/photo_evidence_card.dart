import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/error_messages.dart';
import '../../core/files/document_picker.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../booking/widgets/booking_widgets.dart';
import '../orders/order_providers.dart';
import 'data/evidence_models.dart';

/// Lowercase hex SHA-256 of the photo bytes, computed on the device before upload.
String sha256OfBytes(List<int> bytes) => sha256.convert(bytes).toString();

String mediaKindTitle(AppLocalizations l, MediaKind k) => switch (k) {
  MediaKind.pickupPhoto => l.evidencePickupPhoto,
  MediaKind.handoverPhoto => l.evidenceHandoverPhoto,
  MediaKind.itemPhoto => l.evidenceItemPhoto,
};

enum _Phase { idle, uploading, failed, done }

/// Screens 9: take a photo with the camera, hash it on the device, upload it into the order's
/// evidence chain. Shows progress, and on failure keeps the photo for a retry.
class PhotoEvidenceCard extends ConsumerStatefulWidget {
  const PhotoEvidenceCard({
    super.key,
    required this.orderId,
    required this.kind,
    required this.hint,
    this.optional = false,
  });

  final String orderId;
  final MediaKind kind;
  final String hint;
  final bool optional;

  @override
  ConsumerState<PhotoEvidenceCard> createState() => _PhotoEvidenceCardState();
}

class _PhotoEvidenceCardState extends ConsumerState<PhotoEvidenceCard> {
  _Phase _phase = _Phase.idle;
  PickedDocument? _photo;
  String? _hash;
  double? _progress;
  String? _error;

  String get _key => 'evidence.${widget.kind.wire}';

  Future<void> _capture() async {
    final photo = await ref
        .read(documentPickerProvider)
        .pick(DocumentSource.camera);
    if (photo == null || !mounted) return;
    _photo = photo;
    _hash = sha256OfBytes(photo.bytes);
    await _upload();
  }

  Future<void> _upload() async {
    final photo = _photo;
    final hash = _hash;
    if (photo == null || hash == null) return;
    final l = AppLocalizations.of(context);
    setState(() {
      _phase = _Phase.uploading;
      _progress = null;
      _error = null;
    });
    try {
      await ref
          .read(evidenceRepositoryProvider)
          .uploadPhoto(
            widget.orderId,
            kind: widget.kind,
            bytes: photo.bytes,
            fileName: photo.name,
            sha256: hash,
            onProgress: (sent, total) {
              if (mounted && total > 0) {
                setState(() => _progress = sent / total);
              }
            },
          );
      if (!mounted) return;
      setState(() => _phase = _Phase.done);
      ref.invalidate(evidenceChainProvider(widget.orderId));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.failed;
        _error = apiErrorText(e, l, fallback: l.evidenceUploadFailed);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final recorded =
        ref
            .watch(evidenceChainProvider(widget.orderId))
            .value
            ?.any((e) => e.mediaKind == widget.kind) ??
        false;
    final done = _phase == _Phase.done || (recorded && _phase == _Phase.idle);
    final title = mediaKindTitle(l, widget.kind);

    Widget action;
    if (done) {
      action = Row(
        key: Key('$_key.done'),
        children: [
          Icon(Icons.check_circle, color: c.statusSuccess),
          const SizedBox(width: AppSpacing.s2),
          Expanded(
            child: Text(
              l.evidencePhotoAdded,
              style: AppTextStyles.label.copyWith(color: c.ink),
            ),
          ),
        ],
      );
    } else if (_phase == _Phase.uploading) {
      action = Column(
        key: Key('$_key.uploading'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.evidenceUploading,
            style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: AppSpacing.s2),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: _progress,
              color: c.brand500,
              backgroundColor: c.surfaceSunken,
            ),
          ),
        ],
      );
    } else if (_phase == _Phase.failed) {
      action = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InlineError(
            _error ?? l.evidenceUploadFailed,
            key: Key('$_key.error'),
          ),
          const SizedBox(height: AppSpacing.s3),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: Key('$_key.retake'),
                  onPressed: _capture,
                  child: Text(l.evidenceRetake),
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: PrimaryButton(
                  key: Key('$_key.retry'),
                  label: l.retryButton,
                  onPressed: _upload,
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      action = OutlinedButton.icon(
        key: Key('$_key.capture'),
        onPressed: _capture,
        icon: const Icon(Icons.photo_camera_outlined),
        label: Text(l.evidenceTakePhoto),
      );
    }

    return Container(
      key: Key(_key),
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: c.surfaceSunken,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.labelLg.copyWith(color: c.ink),
                ),
              ),
              if (widget.optional && !done)
                Text(
                  l.optionalLabel,
                  style: AppTextStyles.labelSm.copyWith(color: c.inkMuted),
                ),
            ],
          ),
          if (!done) ...[
            const SizedBox(height: AppSpacing.s1),
            Text(
              widget.hint,
              style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
            ),
          ],
          const SizedBox(height: AppSpacing.s3),
          action,
        ],
      ),
    );
  }
}
