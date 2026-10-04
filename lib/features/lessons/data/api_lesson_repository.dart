import 'package:dio/dio.dart';
import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/core/network/api_client.dart';
import 'package:tamkeen2/core/validation/app_validators.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/features/courses/domain/course.dart';
import 'package:tamkeen2/features/lessons/domain/lesson.dart';
import 'package:tamkeen2/features/lessons/domain/lesson_repository.dart';
import 'package:tamkeen2/core/network/api_values.dart';
import 'package:tamkeen2/features/assessments/data/assessment_mapper.dart';

class ApiLessonRepository implements LessonRepository {
  const ApiLessonRepository(this.client);
  final ApiClient client;
  Future<Object?> _get(String path, [Map<String, dynamic>? query]) async {
    final response = await client.request<Object?>(
      path,
      queryParameters: query,
    );
    final root = ApiValues.object(response.data);
    if (!root.containsKey('data')) {
      throw AppFailure(AppCopy.unexpectedResponse, backendBody: root);
    }
    return root['data'];
  }

  Future<void> _post(String path, FormData form) async {
    await client.request<Object?>(path, method: 'POST', data: form);
  }

  @override
  Future<RemoteLesson> lesson(String lessonId) async {
    final data = ApiValues.object(
      await _get('lessions/details', {'id': ApiValues.requestId(lessonId)}),
    );
    final semester = ApiValues.object(data['semester']);
    final type = ApiValues.object(data['type']);
    final kind = switch (type['id']) {
      1 => LessonKind.document,
      2 => LessonKind.video,
      3 => LessonKind.exam,
      _ => throw const AppFailure(AppCopy.unexpectedResponse),
    };
    return RemoteLesson(
      id: ApiValues.id(data['id']),
      title: ApiValues.text(data['name']),
      kind: kind,
      semesterId: ApiValues.id(semester['id']),
      isAttended: ApiValues.flag(data['is_attended']) ?? false,
      hasAccess:
          ApiValues.flag(data['is_free']) == true ||
          ApiValues.flag(data['is_subscription']) == true ||
          ApiValues.flag(semester['is_free']) == true ||
          ApiValues.flag(semester['is_subscription']) == true,
      videoUrl: ApiValues.optionalText(data['url']),
      drive360: ApiValues.optionalText(data['drive_link_360']),
      drive720: ApiValues.optionalText(data['drive_link_720']),
      fileUrl: ApiValues.optionalText(data['file']),
      exam: data['exam'] == null
          ? null
          : AssessmentMapper.fromJson(ApiValues.object(data['exam'])),
    );
  }

  static Uri? mediaUri(String? value) {
    final uri = Uri.tryParse(value ?? '');
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    return uri;
  }

  @override
  Future<Uri> resolveVideo(
    RemoteLesson lesson, {
    bool highQuality = false,
  }) async {
    if (!lesson.hasAccess) throw const AppFailure(AppCopy.accessDenied);
    final source = mediaUri(lesson.videoUrl);
    if (source == null) throw const AppFailure(AppCopy.mediaMissing);
    final youtube =
        source.host == 'youtu.be' ||
        source.host == 'youtube.com' ||
        source.host.endsWith('.youtube.com');
    if (!youtube) return source;
    final response = await client.request<Object?>(
      highQuality ? 'yt-dlp-720-audio' : 'yt-dlp',
      queryParameters: {'video_url': source.toString()},
    );
    // The successful resolver schema is unverified while the server returns 500.
    // This narrow parser accepts an explicit HTTPS URL; unsupported responses
    // fail explicitly; backend resolver errors are never replaced by a random URL.
    final root = ApiValues.object(response.data);
    final url = mediaUri(root['url'] is String ? root['url'] as String : null);
    if (url == null) {
      throw AppFailure(AppCopy.noMediaFormats, backendBody: root);
    }
    return url;
  }

  @override
  Future<void> attendLesson(String lessonId) => _post(
    'lessions/attend-lession',
    FormData.fromMap({'lession_id': ApiValues.requestId(lessonId)}),
  );
  @override
  Future<void> lastAttended(String semesterId) => _post(
    'lessions/last-attend-lession',
    FormData.fromMap({'semester_id': ApiValues.requestId(semesterId)}),
  );
  @override
  Future<List<RemoteComment>> comments(String lessonId) async =>
      List.unmodifiable(
        ApiValues.objects(
          await _get('comments/get-by-lession', {
            'lession_id': ApiValues.requestId(lessonId),
            'page': 1,
          }),
        ).map(
          (data) => RemoteComment(
            id: ApiValues.id(data['id']),
            text: ApiValues.text(data['comment']),
          ),
        ),
      );
  @override
  Future<void> addComment(String lessonId, String value) async {
    final error = AppValidators.comment(value);
    if (error != null) throw AppFailure(error);
    await _post(
      'comments/add-comment',
      FormData.fromMap({
        'lession_id': ApiValues.requestId(lessonId),
        'comment': value.trim(),
      }),
    );
  }
}
