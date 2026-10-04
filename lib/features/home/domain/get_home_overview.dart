import 'package:tamkeen2/features/home/domain/home_repository.dart';

class GetHomeOverview {
  const GetHomeOverview(this.repository);
  final HomeRepository repository;
  Future<HomeOverview> call() => repository.getHome();
}
