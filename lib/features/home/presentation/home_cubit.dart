import 'package:tamkeen2/core/state/resource_cubit.dart';
import 'package:tamkeen2/features/home/domain/home_repository.dart';
import 'package:tamkeen2/features/home/domain/get_home_overview.dart';

class HomeCubit extends ResourceCubit<HomeOverview> {
  HomeCubit(this.getOverview);
  final GetHomeOverview getOverview;
  bool _loaded = false;
  @override
  Future<HomeOverview> fetch() => getOverview();
  @override
  Future<void> load({bool force = false}) async {
    if (_loaded && !force) return;
    _loaded = true;
    await super.load();
    if (state.status == ResourceStatus.failure) _loaded = false;
  }

  @override
  void reset() {
    _loaded = false;
    super.reset();
  }
}
