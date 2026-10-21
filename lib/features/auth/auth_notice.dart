import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A one-off message for the sign-in screen after the session ended on purpose.
enum AuthNotice { accountDeleted }

final authNoticeProvider = NotifierProvider<AuthNoticeNotifier, AuthNotice?>(
  AuthNoticeNotifier.new,
);

class AuthNoticeNotifier extends Notifier<AuthNotice?> {
  @override
  AuthNotice? build() => null;

  void show(AuthNotice notice) => state = notice;

  void clear() => state = null;
}
