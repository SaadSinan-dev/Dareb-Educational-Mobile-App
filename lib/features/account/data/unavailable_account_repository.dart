import 'dart:typed_data';

import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/features/account/domain/account_models.dart';
import 'package:tamkeen2/features/account/domain/account_repository.dart';

/// Live account endpoints have not been specified or verified.
class UnavailableAccountRepository implements AccountRepository {
  @override
  Future<AccountData> load(String userId) async =>
      throw const AppFailure.unavailable();
  @override
  Future<AccountProfile> saveProfile(
    String userId,
    AccountProfile profile,
  ) async => throw const AppFailure.unavailable();
  @override
  Future<AccountProfile> updateImage(
    String userId,
    Uint8List bytes,
    String filename,
    String? mimeType,
  ) async => throw const AppFailure.unavailable();
  @override
  Future<void> markNotificationRead(String userId, String id) async =>
      throw const AppFailure.unavailable();
  @override
  Future<ContactResult> submitContact(ContactMessage message) async =>
      throw const AppFailure.unavailable();
}
