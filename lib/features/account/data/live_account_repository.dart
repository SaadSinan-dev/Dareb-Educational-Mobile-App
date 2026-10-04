import 'dart:typed_data';

import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/features/account/domain/account_models.dart';
import 'package:tamkeen2/features/account/domain/account_repository.dart';
import 'package:tamkeen2/features/account/data/postman_account_data_source.dart';

/// Uses observed authenticated profile data; unsupported mutations stay explicit.
class LiveAccountRepository implements AccountRepository {
  const LiveAccountRepository(this.source);

  final PostmanAccountDataSource source;

  @override
  Future<AccountData> load(String userId) => source.loadAccountData();

  @override
  Future<AccountProfile> saveProfile(
    String userId,
    AccountProfile profile,
  ) async {
    if (profile.schoolId == null) throw const AppFailure.unavailable();
    await source.updateUser(profile);
    final saved = (await source.loadAccountData()).profile;
    if (saved == null ||
        saved.firstName != profile.firstName.trim() ||
        saved.lastName != profile.lastName.trim() ||
        saved.schoolId != profile.schoolId) {
      throw const AppFailure(AppCopy.unexpectedResponse);
    }
    return saved;
  }

  @override
  Future<AccountProfile> updateImage(
    String userId,
    Uint8List bytes,
    String filename,
    String? mimeType,
  ) async {
    await source.updateImage(bytes, filename, mimeType);
    final saved = (await source.loadAccountData()).profile;
    if (saved?.imageUrl == null) {
      throw const AppFailure(AppCopy.unexpectedResponse);
    }
    return saved!;
  }

  @override
  Future<void> markNotificationRead(String userId, String id) async =>
      throw const AppFailure.unavailable();

  @override
  Future<ContactResult> submitContact(ContactMessage message) async {
    await source.addContact(message);
    return const ContactResult(
      delivered: true,
      message: AppCopy.contactSubmissionReceived,
    );
  }
}
