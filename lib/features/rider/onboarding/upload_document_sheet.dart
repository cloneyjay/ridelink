import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/files/document_picker.dart';
import '../../../core/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';
import '../../booking/widgets/booking_widgets.dart';
import '../data/rider_models.dart';
import '../rider_labels.dart';

const maxDocumentBytes = 10 * 1024 * 1024;

bool _isPdf(String name) => name.toLowerCase().endsWith('.pdf');

/// Client-side checks mirroring the server, returning an error message or null.
String? validatePickedDocument(
  AppLocalizations l,
  DocType type,
  PickedDocument file,
) {
  if (file.bytes.length > maxDocumentBytes) return l.docTooLarge;
  if (type.imageOnly && _isPdf(file.name)) return l.docImageOnly;
  return null;
}

/// Opens the upload sheet; resolves with the new document state, or null if dismissed.
Future<DocumentState?> showUploadDocumentSheet(
  BuildContext context,
  DocType type,
) => showModalBottomSheet<DocumentState>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => UploadDocumentSheet(type: type),
);

class UploadDocumentSheet extends ConsumerStatefulWidget {
  const UploadDocumentSheet({super.key, required this.type});

  final DocType type;

  @override
  ConsumerState<UploadDocumentSheet> createState() =>
      _UploadDocumentSheetState();
}

class _UploadDocumentSheetState extends ConsumerState<UploadDocumentSheet> {
  PickedDocument? _file;
  DateTime? _date;
  String? _error;
  bool _uploading = false;

  DocType get _type => widget.type;
  bool get _needsDate => _type.needsExpiry || _type.needsIssueDate;

  Future<void> _pick(DocumentSource source) async {
    final l = AppLocalizations.of(context);
    try {
      final file = await ref.read(documentPickerProvider).pick(source);
      if (file == null || !mounted) return;
      setState(() {
        _file = file;
        _error = validatePickedDocument(l, _type, file);
      });
    } catch (_) {
      if (mounted) setState(() => _error = l.docPickFailed);
    }
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(ref.read(clockProvider)());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? today,
      firstDate: _type.needsIssueDate
          ? DateTime(today.year - 1, today.month, today.day)
          : today,
      lastDate: _type.needsIssueDate
          ? today
          : DateTime(today.year + 10, today.month, today.day),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _upload() async {
    final l = AppLocalizations.of(context);
    final file = _file;
    if (file == null) return;
    if (_needsDate && _date == null) {
      setState(() => _error = l.docDateRequired);
      return;
    }
    final invalid = validatePickedDocument(l, _type, file);
    if (invalid != null) {
      setState(() => _error = invalid);
      return;
    }
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(riderRepositoryProvider)
          .uploadDocument(
            type: _type,
            bytes: file.bytes,
            fileName: file.name,
            expiresOn: _type.needsExpiry ? _date : null,
            issuedOn: _type.needsIssueDate ? _date : null,
          );
      if (mounted) Navigator.of(context).pop(result);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _error = e.statusCode == 413
            ? l.docTooLarge
            : apiErrorText(e, l, fallback: l.docUploadFailed);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _error = l.docUploadFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final source = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(
        Size.fromHeight(AppLayout.minTapTarget),
      ),
      textStyle: WidgetStatePropertyAll(AppTextStyles.label),
    );
    return SafeArea(
      child: SingleChildScrollView(
        key: const Key('upload.sheet'),
        padding: EdgeInsets.fromLTRB(
          AppLayout.screenPadding,
          0,
          AppLayout.screenPadding,
          AppSpacing.s4 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              docName(l, _type),
              style: AppTextStyles.displaySm.copyWith(color: c.ink),
            ),
            const SizedBox(height: AppSpacing.s1),
            Text(
              docHint(l, _type),
              style: AppTextStyles.bodySm.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: AppSpacing.s2),
            NoteRow(_type.imageOnly ? l.docFormatsImage : l.docFormatsAny),
            if (_needsDate) ...[
              const SizedBox(height: AppSpacing.s4),
              OutlinedButton.icon(
                key: const Key('upload.date'),
                style: source,
                onPressed: _uploading ? null : _pickDate,
                icon: const Icon(Icons.event),
                label: Text(
                  _date == null
                      ? (_type.needsExpiry
                            ? l.docChooseExpiry
                            : l.docChooseIssued)
                      : (_type.needsExpiry
                            ? l.docExpiresOn(formatDate(l, _date!))
                            : l.docIssuedOn(formatDate(l, _date!))),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.s4),
            OutlinedButton.icon(
              key: const Key('upload.camera'),
              style: source,
              onPressed: _uploading ? null : () => _pick(DocumentSource.camera),
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(l.docTakePhoto),
            ),
            const SizedBox(height: AppSpacing.s2),
            OutlinedButton.icon(
              key: const Key('upload.gallery'),
              style: source,
              onPressed: _uploading
                  ? null
                  : () => _pick(DocumentSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(l.docChooseGallery),
            ),
            if (!_type.imageOnly) ...[
              const SizedBox(height: AppSpacing.s2),
              OutlinedButton.icon(
                key: const Key('upload.file'),
                style: source,
                onPressed: _uploading ? null : () => _pick(DocumentSource.file),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: Text(l.docChooseFile),
              ),
            ],
            if (_file != null) ...[
              const SizedBox(height: AppSpacing.s4),
              InfoChip(
                _file!.name,
                key: const Key('upload.fileName'),
                icon: Icons.attach_file,
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.s3),
              InlineError(_error!, key: const Key('upload.error')),
            ],
            const SizedBox(height: AppSpacing.s4),
            PrimaryButton(
              key: const Key('upload.submit'),
              label: l.docUploadButton,
              loading: _uploading,
              onPressed: _file == null ? null : _upload,
            ),
          ],
        ),
      ),
    );
  }
}
