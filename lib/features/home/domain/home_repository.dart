import 'package:tamkeen2/features/courses/domain/subject.dart';

/// Public home content verified from `home-page/index`.
class HomeMedia {
  const HomeMedia({
    required this.id,
    required this.imageUrl,
    required this.destinationUrl,
  });

  final String id;
  final String imageUrl;
  final String destinationUrl;
}

class HomeOverview {
  const HomeOverview({
    required this.sliders,
    required this.news,
    required this.subjects,
    required this.featuredCourseIds,
    required this.completionRate,
    required this.unreadNotifications,
    required this.subjectCount,
  });

  final List<HomeMedia> sliders;
  final List<HomeMedia> news;
  final List<Subject> subjects;
  final List<String> featuredCourseIds;

  /// The raw backend percentage; its denominator is not documented.
  final num completionRate;
  final int unreadNotifications;
  final int subjectCount;
}

abstract interface class HomeRepository {
  Future<HomeOverview> getHome();
}
