import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import 'public_profile_models.dart';

final senderPublicProfileProvider = FutureProvider.autoDispose
    .family<PublicProfile, String>(
      (ref, id) => ref.watch(publicProfileRepositoryProvider).sender(id),
      retry: (_, _) => null,
    );

final senderPhotoProvider = FutureProvider.autoDispose
    .family<Uint8List?, String>(
      (ref, id) => ref.watch(publicProfileRepositoryProvider).senderPhoto(id),
      retry: (_, _) => null,
    );

final riderPublicProfileProvider = FutureProvider.autoDispose
    .family<PublicProfile, String>(
      (ref, id) => ref.watch(publicProfileRepositoryProvider).rider(id),
      retry: (_, _) => null,
    );

final myPublicProfileProvider = FutureProvider.autoDispose
    .family<PublicProfile, PublicProfileRole>(
      (ref, role) => ref.watch(publicProfileRepositoryProvider).mine(role),
      retry: (_, _) => null,
    );
