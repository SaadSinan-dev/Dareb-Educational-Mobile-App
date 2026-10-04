import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/core/storage/key_value_store.dart';
import 'package:tamkeen2/features/account/domain/account_models.dart';
import 'package:tamkeen2/features/account/domain/account_repository.dart';

/// Local preview content. No profile update or contact message reaches a server.
class DemoAccountRepository implements AccountRepository {
  DemoAccountRepository(this.store);
  final KeyValueStore store;
  // DI owns one repository; its per-user queue serializes preference mutations.
  final Map<String, Future<void>> _queue = {};

  static const _photo1 = 'assets/images/gallery_1.png';
  static const _photo2 = 'assets/images/gallery_2.png';
  static const _photo3 = 'assets/images/gallery_3.png';
  static const _photo4 = 'assets/images/gallery_4.png';
  static const albums = <AccountAlbum>[
    AccountAlbum(
      id: 'art',
      title: AppCopy.workAlbumTitle,
      photoCount: 12,
      coverAsset: _photo2,
      photoAssets: [
        _photo2,
        _photo1,
        _photo3,
        _photo4,
        _photo2,
        _photo1,
        _photo4,
        _photo3,
        _photo1,
        _photo2,
        _photo3,
        _photo4,
      ],
    ),
    AccountAlbum(
      id: 'drawing',
      title: AppCopy.drawingAlbumTitle,
      photoCount: 9,
      coverAsset: _photo3,
      photoAssets: [
        _photo3,
        _photo2,
        _photo1,
        _photo4,
        _photo3,
        _photo2,
        _photo1,
        _photo4,
        _photo3,
      ],
    ),
    AccountAlbum(
      id: 'math',
      title: AppCopy.mathematicsAlbumTitle,
      photoCount: 7,
      coverAsset: _photo3,
      photoAssets: [
        _photo3,
        _photo1,
        _photo4,
        _photo2,
        _photo3,
        _photo1,
        _photo4,
      ],
    ),
    AccountAlbum(
      id: 'science',
      title: AppCopy.scienceAlbumTitle,
      photoCount: 12,
      coverAsset: _photo4,
      photoAssets: [
        _photo4,
        _photo3,
        _photo2,
        _photo1,
        _photo4,
        _photo3,
        _photo2,
        _photo1,
        _photo4,
        _photo3,
        _photo2,
        _photo1,
      ],
    ),
    AccountAlbum(
      id: 'statistics',
      title: AppCopy.statisticsAlbumTitle,
      photoCount: 6,
      coverAsset: _photo1,
      photoAssets: [_photo1, _photo2, _photo3, _photo4, _photo1, _photo2],
    ),
    AccountAlbum(
      id: 'algebra',
      title: AppCopy.algebraAlbumTitle,
      photoCount: 7,
      coverAsset: _photo2,
      photoAssets: [
        _photo2,
        _photo1,
        _photo3,
        _photo4,
        _photo2,
        _photo1,
        _photo3,
      ],
    ),
  ];
  static const notifications = <AccountNotification>[
    AccountNotification(
      id: 'new-offer',
      title: AppCopy.newOfferNotification,
      detail: AppCopy.subscriptionDiscountNotification,
      dateLabel: AppCopy.demoNotificationDate,
      icon: 'offer',
    ),
    AccountNotification(
      id: 'service-update-1',
      title: AppCopy.serviceDetailsNotificationTitle,
      detail: AppCopy.serviceDetailsNotificationBody,
      dateLabel: AppCopy.demoNotificationDate,
    ),
    AccountNotification(
      id: 'service-update-2',
      title: AppCopy.serviceDetailsNotificationTitle,
      detail: AppCopy.serviceDetailsNotificationBody,
      dateLabel: AppCopy.demoNotificationDate,
    ),
    AccountNotification(
      id: 'service-update-3',
      title: AppCopy.serviceDetailsNotificationTitle,
      detail: AppCopy.serviceDetailsNotificationBody,
      dateLabel: AppCopy.demoNotificationDate,
    ),
  ];
  static const summary = AccountSummaryStats(
    badges: 12,
    lessons: 12,
    courses: 9,
    points: 22,
    chapters: 9,
  );
  static const achievements = <AccountAchievement>[
    AccountAchievement(
      title: AppCopy.mathematicsSubject,
      iconAsset: 'assets/icons/math.png',
      subjectProgress: .2,
      points: 55,
      pointsTotal: 600,
      pointsProgress: .4,
      chapters: 3,
      chaptersTotal: 9,
      chaptersProgress: .4,
      lessons: 12,
      lessonsTotal: 30,
      lessonsProgress: .4,
    ),
    AccountAchievement(
      title: AppCopy.socialStudiesSubject,
      iconAsset: 'assets/icons/social.png',
      subjectProgress: .2,
      points: 42,
      pointsTotal: 600,
      pointsProgress: .4,
      chapters: 3,
      chaptersTotal: 9,
      chaptersProgress: .4,
      lessons: 12,
      lessonsTotal: 30,
      lessonsProgress: .4,
    ),
    AccountAchievement(
      title: AppCopy.scienceSubject,
      iconAsset: 'assets/icons/science.png',
      subjectProgress: .2,
      points: 30,
      pointsTotal: 600,
      pointsProgress: .4,
      chapters: 3,
      chaptersTotal: 9,
      chaptersProgress: .4,
      lessons: 12,
      lessonsTotal: 30,
      lessonsProgress: .4,
    ),
  ];

  String _key(String userId) =>
      'tamkeen.preview.account.${Uri.encodeComponent(userId)}.v1';

  Future<Map<String, dynamic>> _read(String userId) async {
    final key = _key(userId);
    final raw = await store.read(key);
    if (raw == null) return {};
    try {
      final value = jsonDecode(raw);
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Invalid account preview');
      }
      final profile = value['profile'];
      final read = value['read'];
      if (profile != null &&
          (profile is! Map<String, dynamic> ||
              profile['firstName'] is! String ||
              profile['lastName'] is! String ||
              profile['school'] is! String)) {
        throw const FormatException('Invalid profile');
      }
      if (read != null &&
          (read is! List || read.any((item) => item is! String))) {
        throw const FormatException('Invalid read IDs');
      }
      return value;
    } catch (_) {
      await store.remove(key);
      return {};
    }
  }

  @override
  Future<AccountData> load(String userId) async {
    await _queue[_key(userId)];
    final value = await _read(userId);
    final profile = value['profile'] as Map<String, dynamic>?;
    return AccountData(
      profile: profile == null
          ? null
          : AccountProfile(
              firstName: profile['firstName'] as String,
              lastName: profile['lastName'] as String,
              school: profile['school'] as String,
            ),
      notifications: notifications,
      albums: albums,
      summary: summary,
      achievements: achievements,
      readNotificationIds:
          (value['read'] as List?)?.cast<String>().toSet() ?? {},
      preview: true,
    ).immutable;
  }

  @override
  Future<AccountProfile> saveProfile(
    String userId,
    AccountProfile profile,
  ) async {
    final error = profile.validationError;
    if (error != null) throw AppFailure(error);
    final normalized = profile.normalized;
    return _mutate(userId, (value) {
      value['profile'] = {
        'firstName': normalized.firstName,
        'lastName': normalized.lastName,
        'school': normalized.school,
      };
      return normalized;
    });
  }

  @override
  Future<AccountProfile> updateImage(
    String userId,
    Uint8List bytes,
    String filename,
    String? mimeType,
  ) async => throw const AppFailure.unavailable();

  @override
  Future<void> markNotificationRead(String userId, String id) async {
    if (!notifications.any((item) => item.id == id)) {
      throw const AppFailure(AppCopy.notificationNotFound);
    }
    await _mutate(userId, (value) {
      final read =
          (value['read'] as List?)?.cast<String>().toSet() ?? <String>{};
      read.add(id);
      value['read'] = read.toList();
    });
  }

  Future<T> _mutate<T>(String userId, T Function(Map<String, dynamic>) change) {
    final key = _key(userId);
    final queue = _queue;
    final previous = queue[key] ?? Future<void>.value();
    final update = previous.then((_) async {
      final value = await _read(userId);
      final result = change(value);
      await store.write(key, jsonEncode(value));
      return result;
    });
    queue[key] = update.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return update;
  }

  @override
  Future<ContactResult> submitContact(ContactMessage message) async {
    final error = message.validationError;
    if (error != null) throw AppFailure(error);
    return const ContactResult(
      delivered: false,
      message: AppCopy.previewMessageNotSent,
    );
  }
}
