// lib/features/auth/presentation/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/auth_repository.dart';
import '../data/user_model.dart';

/// Converts Firebase/plugin failures into short messages suitable for the UI.
String authErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-email' => 'Enter a valid email address.',
      'user-disabled' => 'This account has been disabled. Contact support.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' =>
        'Email or password is incorrect.',
      'email-already-in-use' => 'An account already exists for this email.',
      'weak-password' => 'Choose a stronger password (at least 6 characters).',
      'operation-not-allowed' =>
        'This sign-in method is not enabled for this app.',
      'too-many-requests' =>
        'Too many attempts. Wait a moment, then try again.',
      'network-request-failed' =>
        'Check your internet connection and try again.',
      'popup-closed-by-user' ||
      'cancelled-popup-request' =>
        'Google sign-in was cancelled.',
      'account-exists-with-different-credential' =>
        'This email is registered with a different sign-in method.',
      _ => 'Authentication failed. Please try again.',
    };
  }

  if (error is FirebaseException && error.code == 'network-request-failed') {
    return 'Check your internet connection and try again.';
  }

  return 'Something went wrong. Please try again.';
}

// ── Repository Provider ───────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// ── Firebase Auth State ───────────────────────────────
final firebaseAuthStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

// ── User Model Stream ─────────────────────────────────
final userModelProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(authRepositoryProvider).userModelStream(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

// ── Current user convenience provider ────────────────
/// Alias for userModelProvider — preferred by analytics, settings, leaderboard screens
final currentUserProvider = userModelProvider;

// ── Auth Actions Notifier ─────────────────────────────
class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier(this._repo) : super(const AsyncValue.data(null));

  final AuthRepository _repo;

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.signUpWithEmail(
          email: email,
          password: password,
          displayName: displayName,
        ));
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.signInWithEmail(
          email: email,
          password: password,
        ));
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.signInWithGoogle());
  }

  Future<void> signInAsGuest() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.signInAsGuest());
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.signOut());
  }

  Future<void> sendPasswordReset(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.sendPasswordReset(email));
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
