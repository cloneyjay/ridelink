import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/providers.dart';

class LegalDocument {
  const LegalDocument({required this.version, required this.url});

  factory LegalDocument.fromJson(Object? json) {
    final map = json is Map ? json : const {};
    return LegalDocument(
      version: map['version']?.toString() ?? '',
      url: map['url'] as String? ?? '',
    );
  }

  final String version;
  final String url;
}

/// GET /v1/legal: the current Terms of Service and Privacy Policy.
class LegalDocs {
  const LegalDocs({required this.terms, required this.privacy});

  factory LegalDocs.fromJson(Map<String, dynamic> json) => LegalDocs(
    terms: LegalDocument.fromJson(json['terms']),
    privacy: LegalDocument.fromJson(json['privacy']),
  );

  final LegalDocument terms;
  final LegalDocument privacy;
}

abstract class LegalRepository {
  Future<LegalDocs> current();

  /// POST /v1/legal/accept.
  Future<void> accept({
    required String termsVersion,
    required String privacyVersion,
  });
}

class ApiLegalRepository implements LegalRepository {
  ApiLegalRepository(this._api);

  final ApiClient _api;

  @override
  Future<LegalDocs> current() async =>
      LegalDocs.fromJson((await _api.get('legal') as Map).cast());

  @override
  Future<void> accept({
    required String termsVersion,
    required String privacyVersion,
  }) => _api.post(
    'legal/accept',
    data: {'terms_version': termsVersion, 'privacy_version': privacyVersion},
  );
}

final legalRepositoryProvider = Provider<LegalRepository>(
  (ref) => ApiLegalRepository(ref.watch(apiClientProvider)),
);

/// Whether the signed-in user must accept updated terms (`legal_update_required` on
/// GET /v1/profile). A failed check never blocks.
final legalUpdateRequiredProvider = FutureProvider<bool>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return false;
  try {
    final profile = await ref.watch(accountRepositoryProvider).profile();
    return profile.legalUpdateRequired;
  } catch (_) {
    return false;
  }
}, retry: (_, _) => null);
