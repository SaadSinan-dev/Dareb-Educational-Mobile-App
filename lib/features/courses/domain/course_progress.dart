class CourseProgress {
  CourseProgress({
    Set<String> saved = const {},
    Set<String> downloads = const {},
    Set<String> purchases = const {},
    Set<String> completed = const {},
  }) : saved = Set.unmodifiable(saved),
       downloads = Set.unmodifiable(downloads),
       purchases = Set.unmodifiable(purchases),
       completed = Set.unmodifiable(completed);
  final Set<String> saved, downloads, purchases, completed;
}

abstract interface class CourseProgressRepository {
  Future<CourseProgress> load(String owner);
  Future<void> save(String owner, CourseProgress progress);
}
