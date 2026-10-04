import 'dart:convert';
import 'package:tamkeen2/core/storage/key_value_store.dart';
import 'package:tamkeen2/features/courses/domain/course_progress.dart';

/// Owner-scoped persistence mapping; malformed or obsolete records are ignored.
class StoredCourseProgressRepository implements CourseProgressRepository {
  const StoredCourseProgressRepository(this._store);
  final KeyValueStore _store;
  @override
  Future<CourseProgress> load(String owner) async {
    final raw = await _store.read('learning.v1.$owner');
    if (raw == null) return CourseProgress();
    try {
      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic>) return CourseProgress();
      Set<String> ids(String key) => data[key] is List
          ? (data[key] as List).whereType<String>().toSet()
          : {};
      return CourseProgress(
        saved: ids('saved'),
        downloads: ids('downloads'),
        purchases: ids('purchases'),
        completed: ids('completed'),
      );
    } on FormatException {
      return CourseProgress();
    }
  }

  @override
  Future<void> save(String owner, CourseProgress progress) => _store.write(
    'learning.v1.$owner',
    jsonEncode({
      'saved': progress.saved.toList(),
      'downloads': progress.downloads.toList(),
      'purchases': progress.purchases.toList(),
      'completed': progress.completed.toList(),
    }),
  );
}
