import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:tamkeen2/core/validation/app_validators.dart';

import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/core/network/api_client.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/features/account/domain/account_content.dart';
import 'package:tamkeen2/features/account/domain/account_models.dart';

/// Exact account/content request shapes from the supplied collection.
/// Only page, gallery, and public support-info responses were observed successfully.
class PostmanAccountDataSource {
  const PostmanAccountDataSource({
    required this.publicClient,
    required this.authenticatedClient,
  });

  final ApiClient publicClient;
  final ApiClient authenticatedClient;

  Future<AccountPage> loadPage(AccountPageKind kind) async {
    final path = switch (kind) {
      AccountPageKind.privacyPolicy => 'pages/privacy-policy',
      AccountPageKind.termsConditions => 'pages/terms-conditions',
      AccountPageKind.aboutApplication => 'pages/about-application',
    };
    final response = await publicClient.request<Object?>(path);
    final data = _data(response.data);
    if (data == null || (data is List && data.isEmpty)) {
      return const AccountPage.empty();
    }
    if (data is! Map ||
        data['id'] is! int ||
        !data.containsKey('value') ||
        (data['value'] != null && data['value'] is! String)) {
      throw AppFailure(AppCopy.unexpectedResponse, backendBody: response.data);
    }
    return AccountPage(
      id: data['id'] as int,
      value: data['value'] as String? ?? '',
    );
  }

  Future<List<AccountGallerySummary>> loadGallerySummaries() async {
    final response = await authenticatedClient.request<Object?>(
      'galleries/all',
    );
    final data = _data(response.data);
    if (data is! List) {
      throw AppFailure(AppCopy.unexpectedResponse, backendBody: response.data);
    }
    final summaries = <AccountGallerySummary>[];
    for (final item in data) {
      if (item is! Map ||
          item['id'] is! int ||
          item['name'] is! String ||
          item['images'] is! List) {
        throw AppFailure(AppCopy.unexpectedResponse, backendBody: item);
      }
      summaries.add(
        AccountGallerySummary(
          id: item['id'] as int,
          name: item['name'] as String,
          images: List.unmodifiable(
            (item['images'] as List).map(_galleryImageUrl),
          ),
        ),
      );
    }
    return List.unmodifiable(summaries);
  }

  // The live album is currently empty; accept explicit URL strings or image/url
  // records without inventing another endpoint, path or local image fallback.
  String _galleryImageUrl(Object? item) {
    final value = item is String
        ? item
        : item is Map
        ? item['image'] ?? item['url'] ?? item['original_url']
        : null;
    final uri = value is String ? Uri.tryParse(value.trim()) : null;
    if (uri == null ||
        !{'https', 'http'}.contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw AppFailure(AppCopy.unexpectedResponse, backendBody: item);
    }
    return uri.toString();
  }

  Future<AccountContactInfo> loadContactInfo() async {
    final response = await publicClient.request<Object?>('infos/all');
    final data = _data(response.data);
    if (data is! Map || data['email'] is! String || data['phone'] is! String) {
      throw AppFailure(AppCopy.unexpectedResponse, backendBody: response.data);
    }
    return AccountContactInfo(
      email: data['email'] as String,
      phone: data['phone'] as String,
    );
  }

  Future<List<AccountFaq>> loadFaqs() async {
    final response = await authenticatedClient.request<Object?>('faqs/all');
    final data = _data(response.data);
    if (data is! List) {
      throw AppFailure(AppCopy.unexpectedResponse, backendBody: response.data);
    }
    final faqs = <AccountFaq>[];
    for (final item in data) {
      if (item is! Map ||
          item['id'] is! int ||
          item['question'] is! String ||
          item['answer'] is! String) {
        throw AppFailure(AppCopy.unexpectedResponse, backendBody: item);
      }
      faqs.add(
        AccountFaq(
          id: item['id'] as int,
          question: item['question'] as String,
          answer: item['answer'] as String,
        ),
      );
    }
    return List.unmodifiable(faqs);
  }

  /// The live profile shape was verified against a completed QA account.
  Future<AccountData> loadAccountData() async {
    final response = await authenticatedClient.request<Object?>('profile/get');
    final data = _data(response.data);
    if (data is! Map ||
        data['f_name'] is! String ||
        data['l_name'] is! String ||
        data['school'] is! Map ||
        (data['school'] as Map)['id'] is! int ||
        (data['school'] as Map)['name'] is! String ||
        (data['school'] as Map)['governorate'] is! String ||
        data['points'] is! int) {
      throw AppFailure(AppCopy.unexpectedResponse, backendBody: response.data);
    }
    return AccountData(
      profile: AccountProfile(
        firstName: data['f_name'] as String,
        lastName: data['l_name'] as String,
        school: (data['school'] as Map)['name'] as String,
        schoolId: (data['school'] as Map)['id'] as int,
        schoolGovernorate: (data['school'] as Map)['governorate'] as String,
        imageUrl: switch (data['image']) {
          final String value when Uri.tryParse(value)?.scheme == 'https' =>
            value,
          _ => null,
        },
      ),
      summary: AccountSummaryStats(points: data['points'] as int),
    );
  }

  Future<void> updateUser(AccountProfile profile) async {
    final response = await authenticatedClient.request<Object?>(
      'users/update',
      method: 'POST',
      data: FormData.fromMap({
        'f_name': profile.firstName.trim(),
        'l_name': profile.lastName.trim(),
        'school_id': profile.schoolId,
      }),
    );
    if (_data(response.data) is! Map) {
      throw AppFailure(AppCopy.unexpectedResponse, backendBody: response.data);
    }
  }

  Future<void> updateImage(
    Uint8List bytes,
    String filename,
    String? mimeType,
  ) async {
    if (bytes.isEmpty) throw const AppFailure(AppCopy.requestValidationFailed);
    final safeName = filename.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final type = mimeType != null && mimeType.startsWith('image/')
        ? mimeType
        : switch (safeName.toLowerCase().split('.').last) {
            'png' => 'image/png',
            'webp' => 'image/webp',
            'gif' => 'image/gif',
            _ => 'image/jpeg',
          };
    await authenticatedClient.request<Object?>(
      'users/update-image',
      method: 'POST',
      data: FormData.fromMap({
        'image': MultipartFile.fromBytes(
          bytes,
          filename: safeName.isEmpty ? 'profile.jpg' : safeName,
          contentType: DioMediaType.parse(type),
        ),
      }),
    );
  }

  /// Other authenticated schemas remain unverified and raw inside data.
  Future<Object?> requestProfile() => _get('profile/get');

  Future<Object?> requestPoints({int page = 1, int perPage = 10}) =>
      _getHistory('profile/points', page, perPage);

  Future<Object?> requestMedals({int page = 1, int perPage = 10}) =>
      _getHistory('profile/medals', page, perPage);

  Future<Object?> requestCups({int page = 1, int perPage = 10}) =>
      _getHistory('profile/cups', page, perPage);

  Future<Object?> requestNotifications({int page = 1}) async {
    if (page < 1) throw const AppFailure.unavailable();
    final response = await authenticatedClient.request<Object?>(
      'notifications/get',
      queryParameters: {'page': page},
    );
    return response.data;
  }

  Future<Object?> requestFaqs() => _get('faqs/all');

  /// The collection places this operation under bearer authentication.
  /// A 2xx response is required before the caller reports acceptance.
  Future<void> addContact(ContactMessage message) async {
    final validation = message.validationError;
    if (validation != null) throw AppFailure(validation);
    final response = await authenticatedClient.request<Object?>(
      'contact-us/add',
      method: 'POST',
      data: FormData.fromMap({
        'f_name': message.name.trim(),
        'l_name': message.lastName.trim(),
        'phone': AppValidators.normalizedPhone(message.phone),
        'text': message.description.trim(),
      }),
    );
    final status = response.statusCode;
    if (status == null || status < 200 || status >= 300) {
      throw AppFailure(AppCopy.unexpectedResponse, backendBody: response.data);
    }
  }

  Future<Object?> _get(String path) async {
    final response = await authenticatedClient.request<Object?>(path);
    return response.data;
  }

  Future<Object?> _getHistory(String path, int page, int perPage) async {
    if (page < 1 || perPage < 1) throw const AppFailure.unavailable();
    final response = await authenticatedClient.request<Object?>(
      path,
      queryParameters: {'page': page, 'perPage': perPage},
    );
    return response.data;
  }

  Object? _data(Object? body) {
    if (body is! Map || !body.containsKey('data')) {
      throw AppFailure(AppCopy.unexpectedResponse, backendBody: body);
    }
    return body['data'];
  }
}
