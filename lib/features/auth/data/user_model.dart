// lib/features/auth/data/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore-backed user model with gamification fields
class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String? photoURL;
  final int xp;
  final int level;
  final int streak;
  final int longestStreak;
  final int totalMinutesWatched;
  final int dailyGoalMinutes;
  final DateTime? lastActiveDate;
  final DateTime joinedAt;
  final bool isPremium;
  final List<String> categories; // user-selected interests

  const UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoURL,
    this.xp = 0,
    this.level = 1,
    this.streak = 0,
    this.longestStreak = 0,
    this.totalMinutesWatched = 0,
    this.dailyGoalMinutes = 30,
    this.lastActiveDate,
    required this.joinedAt,
    this.isPremium = false,
    this.categories = const [],
  });

  /// Firestore → Model
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      displayName: map['displayName'] as String? ?? 'Learner',
      email: map['email'] as String? ?? '',
      photoURL: map['photoURL'] as String?,
      xp: (map['xp'] as num?)?.toInt() ?? 0,
      level: (map['level'] as num?)?.toInt() ?? 1,
      streak: (map['streak'] as num?)?.toInt() ?? 0,
      longestStreak: (map['longestStreak'] as num?)?.toInt() ?? 0,
      totalMinutesWatched:
          (map['totalMinutesWatched'] as num?)?.toInt() ?? 0,
      dailyGoalMinutes: (map['dailyGoalMinutes'] as num?)?.toInt() ?? 30,
      lastActiveDate: (map['lastActiveDate'] as Timestamp?)?.toDate(),
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPremium: map['isPremium'] as bool? ?? false,
      categories: List<String>.from(map['categories'] ?? []),
    );
  }

  /// Model → Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'xp': xp,
      'level': level,
      'streak': streak,
      'longestStreak': longestStreak,
      'totalMinutesWatched': totalMinutesWatched,
      'dailyGoalMinutes': dailyGoalMinutes,
      'lastActiveDate':
          lastActiveDate != null ? Timestamp.fromDate(lastActiveDate!) : null,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'isPremium': isPremium,
      'categories': categories,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? photoURL,
    int? xp,
    int? level,
    int? streak,
    int? longestStreak,
    int? totalMinutesWatched,
    int? dailyGoalMinutes,
    DateTime? lastActiveDate,
    bool? isPremium,
    List<String>? categories,
  }) {
    return UserModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email,
      photoURL: photoURL ?? this.photoURL,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      streak: streak ?? this.streak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalMinutesWatched: totalMinutesWatched ?? this.totalMinutesWatched,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      joinedAt: joinedAt,
      isPremium: isPremium ?? this.isPremium,
      categories: categories ?? this.categories,
    );
  }

  /// XP needed to reach next level
  int get xpForNextLevel => level * 500;

  /// XP remaining to next level (used in analytics)
  int get xpToNextLevel => xpForNextLevel - (xp % xpForNextLevel);

  /// Progress toward next level (0.0–1.0)
  double get levelProgress {
    final xpInCurrentLevel = xp - ((level - 1) * 500);
    return (xpInCurrentLevel / 500).clamp(0.0, 1.0);
  }

  /// Alias for levelProgress (used in analytics)
  double get xpProgress => levelProgress;

  /// Total hours watched
  double get totalHoursWatched => totalMinutesWatched / 60.0;

  /// Alias for streak (used across screens)
  int get streakDays => streak;

  /// Alias for photoURL (some screens use photoUrl)
  String? get photoUrl => photoURL;

  /// Greeting based on display name
  String get firstName => displayName.split(' ').first;
}
