import 'package:tamkeen2/features/account/domain/account_content.dart';
import 'package:tamkeen2/features/account/domain/account_content_repository.dart';
import 'package:tamkeen2/features/account/data/postman_account_data_source.dart';

class LiveAccountContentRepository implements AccountContentRepository {
  const LiveAccountContentRepository(this.source);

  final PostmanAccountDataSource source;

  @override
  Future<AccountPage> loadPage(AccountPageKind kind) => source.loadPage(kind);

  @override
  Future<List<AccountGallerySummary>> loadGallerySummaries() =>
      source.loadGallerySummaries();

  @override
  Future<AccountContactInfo> loadContactInfo() => source.loadContactInfo();

  @override
  Future<List<AccountFaq>> loadFaqs() => source.loadFaqs();
}
