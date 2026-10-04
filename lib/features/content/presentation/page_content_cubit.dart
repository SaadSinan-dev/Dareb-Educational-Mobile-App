import 'package:tamkeen2/core/state/resource_cubit.dart';
import 'package:tamkeen2/features/account/domain/account_content.dart';
import 'package:tamkeen2/features/account/domain/account_content_repository.dart';
import 'package:tamkeen2/features/content/data/cms_text_mapper.dart';

class PageContentCubit extends ResourceCubit<String> {
  PageContentCubit(this.repository, this.kind);
  final AccountContentRepository repository;
  final AccountPageKind kind;
  @override
  Future<String> fetch() async =>
      accountHtmlToText((await repository.loadPage(kind)).value);
}
