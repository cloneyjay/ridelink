import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/routing/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';
import '../../booking/widgets/booking_widgets.dart';
import '../data/rider_models.dart';
import '../rider_controller.dart';
import '../rider_labels.dart';
import 'upload_document_sheet.dart';

/// The 7-item verification checklist with per-document status and upload.
class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  Verification? _verification;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final v = await ref.read(riderRepositoryProvider).verification();
      if (!mounted) return;
      setState(() {
        _verification = v;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _upload(DocType type) async {
    final result = await showUploadDocumentSheet(context, type);
    if (result == null || !mounted) return;
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: const Key('documents.uploaded'),
        content: Text(l.docUploaded(docName(l, type))),
      ),
    );
    await _load();
    if (ref.exists(riderControllerProvider)) {
      await ref.read(riderControllerProvider.notifier).refreshVerification();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final v = _verification;
    final submitted = v == null
        ? 0
        : DocType.values.where((t) => !v.documentFor(t).needsUpload).length;
    return Scaffold(
      key: const Key('screen.riderDocuments'),
      appBar: AppBar(
        leading: BackButton(
          key: const Key('documents.back'),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(AppRoutes.riderHome),
        ),
        title: Text(l.documentsTitle),
      ),
      body: SafeArea(
        child: _loading
            ? const LoadingView()
            : _failed || v == null
            ? MessageView(
                key: const Key('documents.error'),
                icon: Icons.wifi_off,
                title: l.documentsLoadFailed,
                actionLabel: l.retryButton,
                actionKey: const Key('documents.retry'),
                onAction: _load,
              )
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(AppLayout.screenPadding),
                  children: [
                    Text(
                      l.documentsIntro,
                      style: AppTextStyles.body.copyWith(color: c.inkMuted),
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      l.documentsProgress(submitted, DocType.values.length),
                      key: const Key('documents.progress'),
                      style: AppTextStyles.labelLg.copyWith(color: c.ink),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    for (final t in DocType.values) ...[
                      DocumentRow(
                        doc: v.documentFor(t),
                        onTap: () => _upload(t),
                      ),
                      const SizedBox(height: AppSpacing.s3),
                    ],
                    const SizedBox(height: AppSpacing.s3),
                    PrimaryButton(
                      key: const Key('documents.continue'),
                      label: l.documentsContinue,
                      onPressed: v.allSubmitted
                          ? () => context.push(AppRoutes.riderVerification)
                          : null,
                    ),
                    if (!v.allSubmitted) ...[
                      const SizedBox(height: AppSpacing.s2),
                      NoteRow(l.documentsUploadAll),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class DocumentRow extends StatelessWidget {
  const DocumentRow({super.key, required this.doc, required this.onTap});

  final DocumentState doc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final (Color fg, Color bg, IconData icon) = switch (doc.status) {
      DocStatus.missing => (c.inkMuted, c.surfaceSunken, Icons.upload_file),
      DocStatus.pending => (c.statusInfo, c.surfaceSunken, Icons.schedule),
      DocStatus.approved => (c.statusSuccess, c.forest100, Icons.check_circle),
      DocStatus.rejected => (c.statusError, c.statusErrorTint, Icons.error),
    };
    final details = <String>[
      if (doc.status == DocStatus.rejected && doc.rejectionReason != null)
        l.docRejectedReason(doc.rejectionReason!),
      if (doc.expiresOn != null) l.docExpiresOn(formatDate(l, doc.expiresOn!)),
      if (doc.status == DocStatus.pending && doc.current)
        l.docPendingStillValid,
    ];
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        key: Key('documents.row.${doc.type.wire}'),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppLayout.minTapTarget),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: fg),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        docName(l, doc.type),
                        style: AppTextStyles.labelLg.copyWith(color: c.ink),
                      ),
                      const SizedBox(height: AppSpacing.s1),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s2,
                          vertical: AppSpacing.s1,
                        ),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          docStatusLabel(l, doc.status),
                          key: Key('documents.status.${doc.type.wire}'),
                          style: AppTextStyles.labelSm.copyWith(color: fg),
                        ),
                      ),
                      for (final d in details) ...[
                        const SizedBox(height: AppSpacing.s1),
                        Text(
                          d,
                          style: AppTextStyles.bodySm.copyWith(
                            color: doc.status == DocStatus.rejected
                                ? c.statusError
                                : c.inkMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.s2),
                Text(
                  doc.status == DocStatus.missing
                      ? l.docUploadAction
                      : l.docReplaceAction,
                  style: AppTextStyles.label.copyWith(color: c.brand700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
