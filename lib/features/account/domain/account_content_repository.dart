import 'package:tamkeen2/features/account/domain/account_content.dart';

abstract interface class AccountContentRepository {
  Future<AccountPage> loadPage(AccountPageKind kind);
  Future<List<AccountGallerySummary>> loadGallerySummaries();
  Future<AccountContactInfo> loadContactInfo();
  Future<List<AccountFaq>> loadFaqs();
}
