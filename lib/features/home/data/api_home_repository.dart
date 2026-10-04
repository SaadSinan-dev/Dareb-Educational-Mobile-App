import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/core/network/api_client.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/features/home/domain/home_repository.dart';
import 'package:tamkeen2/features/search/domain/search_repository.dart';
import 'package:tamkeen2/features/courses/data/course_model.dart';
import 'package:tamkeen2/features/assessments/data/assessment_mapper.dart';

/// Parses only fields seen in live public responses on the configured host.
class ApiHomeRepository implements HomeRepository, SearchRepository {
  const ApiHomeRepository(this.client);
  final ApiClient client;

  @override
  Future<HomeOverview> getHome() async {
    final data = await _data('home-page/index', {'perPage': 10});
    try {
      return HomeOverview(
        sliders: _media(data['sliders']),
        news: _media(data['news']),
        subjects: List.unmodifiable(
          _objects(
            data['subjects'],
          ).map((value) => SubjectModel.fromApiJson(value).toEntity()),
        ),
        featuredCourseIds: List.unmodifiable(
          _objects(data['courses']).map((value) => _id(value['id'])),
        ),
        completionRate: _number(data['completion_rate']),
        unreadNotifications: _nonnegative(data['notification_unread']),
        subjectCount: _nonnegative(data['subject_count']),
      );
    } on FormatException {
      throw AppFailure(AppCopy.unexpectedResponse, backendBody: data);
    }
  }

  @override
  Future<HomeSearchResult> search(String text) async {
    final query = text.trim();
    if (query.isEmpty) {
      return const HomeSearchResult(
        subjects: [],
        unsupportedExamResults: 0,
        unsupportedActivityResults: 0,
      );
    }
    final data = await _data('home-page/search', {
      'perPage': 10,
      'text': query,
    });
    try {
      return HomeSearchResult(
        subjects: List.unmodifiable(
          _objects(
            data['subjects'],
          ).map((value) => SubjectModel.fromApiJson(value).toEntity()),
        ),
        unsupportedExamResults: 0,
        unsupportedActivityResults: 0,
        exams: List.unmodifiable(
          _objects(data['exams']).map(AssessmentMapper.fromJson),
        ),
        activities: List.unmodifiable(
          _objects(data['dailyActivities']).map(AssessmentMapper.fromJson),
        ),
      );
    } on FormatException {
      throw AppFailure(AppCopy.unexpectedResponse, backendBody: data);
    }
  }

  Future<Map<String, dynamic>> _data(
    String path,
    Map<String, dynamic> query,
  ) async {
    final response = await client.request<Object?>(
      path,
      queryParameters: query,
    );
    final root = response.data;
    if (root is! Map<String, dynamic> ||
        root['data'] is! Map<String, dynamic>) {
      throw AppFailure(AppCopy.unexpectedResponse, backendBody: root);
    }
    return root['data'] as Map<String, dynamic>;
  }

  static List<HomeMedia> _media(Object? source) => List.unmodifiable(
    _objects(source).map(
      (record) => HomeMedia(
        id: _id(record['id']),
        imageUrl: _string(record['image']),
        destinationUrl: _string(record['link']),
      ),
    ),
  );

  static List<Map<String, dynamic>> _objects(Object? source) {
    if (source is! List) throw const FormatException('Expected list');
    return source
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('Expected object');
          }
          return item;
        })
        .toList(growable: false);
  }

  static String _id(Object? value) {
    if (value is! int || value <= 0) throw const FormatException('Invalid ID');
    return value.toString();
  }

  static String _string(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      throw const FormatException('Expected string');
    }
    return value;
  }

  static int _nonnegative(Object? value) {
    if (value is! int || value < 0) {
      throw const FormatException('Expected count');
    }
    return value;
  }

  static num _number(Object? value) {
    if (value is! num || value < 0) {
      throw const FormatException('Expected number');
    }
    return value;
  }
}
