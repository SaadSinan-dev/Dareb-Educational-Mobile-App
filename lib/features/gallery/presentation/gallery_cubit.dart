import 'package:tamkeen2/core/state/resource_cubit.dart';
import 'package:tamkeen2/features/account/domain/account_content.dart';
import 'package:tamkeen2/features/account/domain/account_content_repository.dart';

class GalleryCubit extends ResourceCubit<List<AccountGallerySummary>> {
  GalleryCubit(this.repository);
  final AccountContentRepository repository;
  @override
  Future<List<AccountGallerySummary>> fetch() async =>
      List.unmodifiable(await repository.loadGallerySummaries());
}
