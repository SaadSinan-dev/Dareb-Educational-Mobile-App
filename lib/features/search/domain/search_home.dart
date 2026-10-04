import 'package:tamkeen2/features/search/domain/search_repository.dart';

class SearchHome {
  const SearchHome(this.repository);
  final SearchRepository repository;
  Future<HomeSearchResult> call(String text) => repository.search(text);
}
