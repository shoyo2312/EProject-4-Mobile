import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tiktok_mobile/features/auth/data/session_model.dart';
import 'package:tiktok_mobile/features/auth/presentation/auth_provider.dart';

part 'sessions_provider.g.dart';

/// The devices signed in to this account, for the "Devices" screen.
@riverpod
class Sessions extends _$Sessions {
  @override
  Future<List<SessionModel>> build() =>
      ref.read(authRepositoryProvider).sessions();

  /// Signs another device out remotely. This device signs out through
  /// [AuthState.logout] instead, which also clears the local tokens.
  Future<void> signOut(String sessionId) async {
    await ref.read(authRepositoryProvider).signOutSession(sessionId);
    _drop((s) => s.id == sessionId);
  }

  Future<void> signOutOthers() async {
    await ref.read(authRepositoryProvider).signOutOtherSessions();
    _drop((s) => !s.current);
  }

  void _drop(bool Function(SessionModel) test) {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.where((s) => !test(s)).toList());
    }
  }
}
