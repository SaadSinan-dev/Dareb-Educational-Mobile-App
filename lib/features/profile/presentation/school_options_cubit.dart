import 'package:tamkeen2/core/state/resource_cubit.dart';
import 'package:tamkeen2/features/auth/domain/auth_repository.dart';
import 'package:tamkeen2/features/auth/domain/registration_options.dart';

/// Retains the saved school's ID while refreshing both institution categories.
class SchoolOptionsCubit extends ResourceCubit<List<RegistrationOption>> {
  SchoolOptionsCubit(this._repository);
  final AuthRepository _repository;
  String? _governorate;
  List<RegistrationOption> _saved = const [];

  Future<void> refresh(String? governorate, List<RegistrationOption> saved) {
    _governorate = governorate;
    _saved = List.unmodifiable(saved);
    return load();
  }

  @override
  Future<List<RegistrationOption>> fetch() async {
    final governorate = _governorate;
    final saved = _saved;
    if (governorate == null) return saved;
    final lists = await Future.wait([
      _repository.schools(type: 1, governorate: governorate),
      _repository.schools(type: 2, governorate: governorate),
    ]);
    return List.unmodifiable(
      <int, RegistrationOption>{
        for (final item in saved) item.id: item,
        for (final list in lists)
          for (final item in list) item.id: item,
      }.values,
    );
  }
}
