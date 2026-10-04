import 'package:tamkeen2/core/state/resource_cubit.dart';
import 'package:tamkeen2/features/account/domain/account_content.dart';
import 'package:tamkeen2/features/account/domain/account_content_repository.dart';

class ContactInfoCubit extends ResourceCubit<AccountContactInfo> {
  ContactInfoCubit(this.repository);
  final AccountContentRepository repository;
  @override
  Future<AccountContactInfo> fetch() => repository.loadContactInfo();
}
