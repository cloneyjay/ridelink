import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import 'data/rider_models.dart';

String docName(AppLocalizations l, DocType t) => switch (t) {
  DocType.riderPhoto => l.docRiderPhoto,
  DocType.nationalId => l.docNationalId,
  DocType.drivingLicence => l.docDrivingLicence,
  DocType.policeClearance => l.docPoliceClearance,
  DocType.psvInsurance => l.docPsvInsurance,
  DocType.logbookOrSaleAgreement => l.docLogbook,
  DocType.bikeRearPhoto => l.docBikeRearPhoto,
};

String docHint(AppLocalizations l, DocType t) => switch (t) {
  DocType.riderPhoto => l.docRiderPhotoHint,
  DocType.nationalId => l.docNationalIdHint,
  DocType.drivingLicence => l.docDrivingLicenceHint,
  DocType.policeClearance => l.docPoliceClearanceHint,
  DocType.psvInsurance => l.docPsvInsuranceHint,
  DocType.logbookOrSaleAgreement => l.docLogbookHint,
  DocType.bikeRearPhoto => l.docBikeRearPhotoHint,
};

String docStatusLabel(AppLocalizations l, DocStatus s) => switch (s) {
  DocStatus.missing => l.docStatusMissing,
  DocStatus.pending => l.docStatusPending,
  DocStatus.approved => l.docStatusApproved,
  DocStatus.rejected => l.docStatusRejected,
};

String rejectionReasonText(AppLocalizations l, RejectionCode c) => switch (c) {
  RejectionCode.blurry => l.docRejectionBlurry,
  RejectionCode.wrongDocument => l.docRejectionWrongDocument,
  RejectionCode.expired => l.docRejectionExpired,
  RejectionCode.nameMismatch => l.docRejectionNameMismatch,
  RejectionCode.detailsMismatch => l.docRejectionDetailsMismatch,
  RejectionCode.bikePhoto => l.docRejectionBikePhoto,
  RejectionCode.unverifiable ||
  RejectionCode.suspectedFake => l.docRejectionSuspectedFake,
  RejectionCode.other => l.docRejectionOther,
};

/// Localized reason for the code; unknown codes fall back to the server's English text.
String? docRejectionReason(AppLocalizations l, DocumentState d) {
  final code = d.rejectionCode;
  return code == null ? d.rejectionReason : rejectionReasonText(l, code);
}

/// "14 Oct 2026" in the app's locale.
String formatDate(AppLocalizations l, DateTime d) =>
    DateFormat.yMMMd(l.localeName).format(d);

/// "14 Oct, 15:30" for pause end times (local time).
String formatDateTime(AppLocalizations l, DateTime d) =>
    DateFormat.MMMd(l.localeName).add_Hm().format(d.toLocal());
