export 'package:tamkeen2/features/contact/domain/contact_message.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'dart:collection';
import 'package:tamkeen2/core/validation/app_validators.dart';

class AccountProfile {
  const AccountProfile({
    required this.firstName,
    required this.lastName,
    required this.school,
    this.schoolId,
    this.schoolGovernorate,
    this.imageUrl,
  });
  final String firstName;
  final String lastName;
  final String school;
  final int? schoolId;
  final String? schoolGovernorate;
  final String? imageUrl;

  String get displayName => '$firstName $lastName'.trim();
  String? get validationError {
    if (AppValidators.name(firstName) != null ||
        AppValidators.name(lastName) != null) {
      return AppCopy.enterFirstAndLastName;
    }
    if (AppValidators.school(school) != null) {
      return AppCopy.selectOrEnterSchool;
    }
    return null;
  }

  AccountProfile get normalized => AccountProfile(
    firstName: firstName.trim(),
    lastName: lastName.trim(),
    school: school.trim(),
    schoolId: schoolId,
    schoolGovernorate: schoolGovernorate,
    imageUrl: imageUrl,
  );
}

class AccountSummaryStats {
  const AccountSummaryStats({
    this.badges,
    this.lessons,
    this.courses,
    this.points,
    this.chapters,
  });
  final int? badges, lessons, courses, points, chapters;
}

class AccountAchievement {
  const AccountAchievement({
    required this.title,
    required this.iconAsset,
    required this.subjectProgress,
    required this.points,
    required this.pointsTotal,
    required this.pointsProgress,
    required this.chapters,
    required this.chaptersTotal,
    required this.chaptersProgress,
    required this.lessons,
    required this.lessonsTotal,
    required this.lessonsProgress,
  });
  final String title, iconAsset;
  final double subjectProgress,
      pointsProgress,
      chaptersProgress,
      lessonsProgress;
  final int points, pointsTotal, chapters, chaptersTotal, lessons, lessonsTotal;
}

class AccountNotification {
  const AccountNotification({
    required this.id,
    required this.title,
    required this.detail,
    required this.dateLabel,
    this.icon = 'announcement',
  });
  final String id;
  final String title;
  final String detail;
  final String dateLabel;
  final String icon;
}

class AccountAlbum {
  const AccountAlbum({
    required this.id,
    required this.title,
    required this.photoCount,
    required this.coverAsset,
    required this.photoAssets,
  });
  final String id;
  final String title;
  final int photoCount;
  final String coverAsset;
  final List<String> photoAssets;
}

class AccountData {
  const AccountData({
    this.profile,
    this.notifications = const [],
    this.albums = const [],
    this.summary,
    this.achievements = const [],
    this.readNotificationIds = const {},
    this.preview = false,
  });
  final AccountProfile? profile;
  final List<AccountNotification> notifications;
  final List<AccountAlbum> albums;
  final AccountSummaryStats? summary;
  final List<AccountAchievement> achievements;
  final Set<String> readNotificationIds;
  final bool preview;

  AccountData copyWith({
    AccountProfile? profile,
    bool clearProfile = false,
    Set<String>? readNotificationIds,
  }) => AccountData(
    profile: clearProfile ? null : profile ?? this.profile,
    notifications: notifications,
    albums: albums,
    summary: summary,
    achievements: achievements,
    readNotificationIds: readNotificationIds ?? this.readNotificationIds,
    preview: preview,
  );

  AccountData get immutable => AccountData(
    profile: profile,
    notifications: List.unmodifiable(notifications),
    albums: List.unmodifiable(albums),
    summary: summary,
    achievements: List.unmodifiable(achievements),
    readNotificationIds: UnmodifiableSetView(readNotificationIds),
    preview: preview,
  );
}
