// lib/features/auth/data/auth_repository.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_model.dart';

/// Handles authentication operations and Firestore user management.
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // ─────────────────────────────────────────────────
  // Auth State
  // ─────────────────────────────────────────────────

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ─────────────────────────────────────────────────
  // Firestore User Document
  // ─────────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  DocumentReference<Map<String, dynamic>> _publicLeaderboardDoc(String uid) {
    return _firestore.collection('leaderboard').doc(uid);
  }

  Map<String, dynamic> _leaderboardData(UserModel user) => {
        'uid': user.uid,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'xp': user.xp,
        'level': user.level,
        'streak': user.streak,
      };

  Future<void> _saveNewUser(UserModel user) async {
    // Keep the private profile write independent from the public projection.
    // A leaderboard rule/configuration problem must not discard the user's data.
    await _userDoc(user.uid).set(user.toMap(), SetOptions(merge: true));
    try {
      await _publicLeaderboardDoc(user.uid).set(_leaderboardData(user));
    } catch (_) {
      // The private user document is the source of truth for app data.
    }
  }

  Future<void> _refreshLeaderboardEntry(UserModel user) =>
      _publicLeaderboardDoc(user.uid).set(_leaderboardData(user));

  /// Role assignment remains server-controlled; this updates only a selected
  /// workspace after Firestore rules verify the member has access.
  Future<void> setActiveWorkspace(String uid, String workspace) async {
    await _userDoc(uid).update({'activeWorkspace': workspace});
  }

  Future<UserModel?> fetchUserModel(String uid) async {
    final doc = await _userDoc(uid).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return UserModel.fromMap(doc.data()!);
  }

  Stream<UserModel?> userModelStream(String uid) {
    return _userDoc(uid).snapshots().asyncMap((snap) async {
      if (!snap.exists || snap.data() == null) {
        final firebaseUser = _auth.currentUser;
        if (firebaseUser == null || firebaseUser.uid != uid) return null;
        final user = _buildNewUser(firebaseUser);
        await _saveNewUser(user);
        return user;
      }

      // Preserve existing DOEET profiles while adding the new workspace
      // fields. This write is deliberately learner-only; privileged roles are
      // still granted exclusively by the Admin SDK function.
      if (!snap.data()!.containsKey('roles')) {
        await _userDoc(uid).set({
          'roles': const ['learner'],
          'activeWorkspace': 'learner',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return UserModel.fromMap(snap.data()!);
    });
  }

  // ─────────────────────────────────────────────────
  // Email / Password
  // ─────────────────────────────────────────────────

  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      throw Exception('Failed to create Firebase user.');
    }

    await firebaseUser.updateDisplayName(displayName);

    final user = _buildNewUser(
      firebaseUser,
      displayName: displayName,
    );

    await _saveNewUser(user);

    return user;
  }

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      throw Exception('Firebase user is null after email sign-in.');
    }

    final existingUser = await fetchUserModel(firebaseUser.uid);

    if (existingUser != null) {
      await _refreshLeaderboardEntry(existingUser);
      return existingUser;
    }

    final user = _buildNewUser(firebaseUser);

    await _saveNewUser(user);

    return user;
  }

  // ─────────────────────────────────────────────────
  // Google Sign-In
  // ─────────────────────────────────────────────────

  Future<UserModel> signInWithGoogle() async {
    final UserCredential userCredential = kIsWeb
        ? await _auth.signInWithPopup(GoogleAuthProvider())
        : await _auth.signInWithProvider(GoogleAuthProvider());

    // UserCredential already provides the `user` property.
    final firebaseUser = userCredential.user;

    if (firebaseUser == null) {
      throw Exception(
        'Firebase user is null after Google sign-in.',
      );
    }

    // Check whether the Firestore user already exists.
    final existingUser = await fetchUserModel(firebaseUser.uid);

    if (existingUser != null) {
      await _refreshLeaderboardEntry(existingUser);
      return existingUser;
    }

    // First Google sign-in: create the Firestore user.
    final user = _buildNewUser(firebaseUser);

    await _saveNewUser(user);

    return user;
  }

  // ─────────────────────────────────────────────────
  // Guest Sign-In
  // ─────────────────────────────────────────────────

  Future<UserModel> signInAsGuest() async {
    // Reuse a guest session if the user taps the action again. This avoids
    // producing an unnecessary anonymous account on every attempt.
    final current = _auth.currentUser;
    if (current != null && current.isAnonymous) {
      final existing = await fetchUserModel(current.uid);
      return existing ?? _buildNewUser(current, displayName: 'Guest Learner');
    }
    final credential = await _auth.signInAnonymously();

    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      throw Exception(
        'Firebase user is null after anonymous sign-in.',
      );
    }

    final existingUser = await fetchUserModel(firebaseUser.uid);

    if (existingUser != null) {
      await _refreshLeaderboardEntry(existingUser);
      return existingUser;
    }

    final user = _buildNewUser(
      firebaseUser,
      displayName: 'Guest Learner',
    );

    // A guest can still explore even if a first-time profile write is delayed
    // by a transient Firestore connection. Their authenticated Firebase
    // session remains valid and the profile is created by userModelStream on
    // the next successful connection.
    try {
      await _saveNewUser(user);
    } catch (_) {}

    return user;
  }

  // ─────────────────────────────────────────────────
  // Password Reset
  // ─────────────────────────────────────────────────

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(
      email: email,
    );
  }

  // ─────────────────────────────────────────────────
  // Sign Out
  // ─────────────────────────────────────────────────

  Future<void> signOut() async {
    // Signing out of Firebase must still work if the native Google plugin
    // cannot clear its cached account state.
    await _auth.signOut();
  }

  // ─────────────────────────────────────────────────
  // Update Profile
  // ─────────────────────────────────────────────────

  Future<void> updateUser(
    String uid,
    Map<String, dynamic> updates,
  ) async {
    await _userDoc(uid).update(updates);
    final user = await fetchUserModel(uid);
    if (user != null) await _refreshLeaderboardEntry(user);
  }

  // ─────────────────────────────────────────────────
  // Add XP
  // ─────────────────────────────────────────────────

  Future<void> addXP(
    String uid,
    int xpToAdd,
  ) async {
    final doc = await _userDoc(uid).get();

    if (!doc.exists || doc.data() == null) {
      throw Exception('User document not found.');
    }

    final user = UserModel.fromMap(doc.data()!);

    final newXP = user.xp + xpToAdd;
    final newLevel = (newXP / 500).floor() + 1;

    final batch = _firestore.batch();
    batch.update(_userDoc(uid), {
      'xp': newXP,
      'level': newLevel,
    });
    batch.set(
      _publicLeaderboardDoc(uid),
      {..._leaderboardData(user), 'xp': newXP, 'level': newLevel},
    );
    await batch.commit();
  }

  // ─────────────────────────────────────────────────
  // Daily Streak
  // ─────────────────────────────────────────────────

  Future<void> updateStreak(String uid) async {
    final doc = await _userDoc(uid).get();

    if (!doc.exists || doc.data() == null) {
      throw Exception('User document not found.');
    }

    final user = UserModel.fromMap(doc.data()!);

    final today = DateTime.now();
    final last = user.lastActiveDate;

    int newStreak = user.streak;

    if (last == null) {
      newStreak = 1;
    } else {
      final diff = today.difference(last).inDays;

      if (diff == 1) {
        // Consecutive day.
        newStreak = user.streak + 1;
      } else if (diff > 1) {
        // Streak broken.
        newStreak = 1;
      }
      // diff == 0 means same day, so leave streak unchanged.
    }

    final longestStreak =
        newStreak > user.longestStreak ? newStreak : user.longestStreak;

    final batch = _firestore.batch();
    batch.update(_userDoc(uid), {
      'streak': newStreak,
      'longestStreak': longestStreak,
      'lastActiveDate': Timestamp.fromDate(today),
    });
    batch.set(
      _publicLeaderboardDoc(uid),
      {..._leaderboardData(user), 'streak': newStreak},
    );
    await batch.commit();
  }

  // ─────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────

  UserModel _buildNewUser(
    User firebaseUser, {
    String? displayName,
  }) {
    return UserModel(
      uid: firebaseUser.uid,
      displayName: displayName ??
          firebaseUser.displayName ??
          firebaseUser.email?.split('@').first ??
          'Learner',
      email: firebaseUser.email ?? '',
      photoURL: firebaseUser.photoURL,
      joinedAt: DateTime.now(),
    );
  }
}
