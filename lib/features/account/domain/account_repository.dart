import 'package:tamkeen2/features/contact/domain/contact_repository.dart';
import 'dart:typed_data';

import 'package:tamkeen2/features/account/domain/account_models.dart';

abstract interface class AccountRepository implements ContactRepository {
  Future<AccountData> load(String userId);
  Future<AccountProfile> saveProfile(String userId, AccountProfile profile);
  Future<AccountProfile> updateImage(
    String userId,
    Uint8List bytes,
    String filename,
    String? mimeType,
  );
  Future<void> markNotificationRead(String userId, String id);
}
