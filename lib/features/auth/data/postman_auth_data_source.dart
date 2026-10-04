import 'package:dio/dio.dart';

import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/core/network/api_client.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/features/auth/domain/registration_draft.dart';
import 'package:tamkeen2/features/auth/domain/registration_options.dart';

/// Request shapes and the activation token field match the supplied collection.
class PostmanAuthDataSource {
  const PostmanAuthDataSource({
    required this.publicClient,
    required this.authenticatedClient,
  });

  final ApiClient publicClient;
  final ApiClient authenticatedClient;

  Future<void> login(String phone) async {
    await publicClient.request<Object?>(
      'auth/login',
      method: 'POST',
      data: FormData.fromMap({'phone': phone}),
    );
  }

  Future<void> resend(String phone) async {
    await publicClient.request<Object?>(
      'auth/resend',
      method: 'POST',
      data: FormData.fromMap({'phone': phone}),
    );
  }

  Future<String> activate({
    required String phone,
    required String code,
    String? fcmToken,
    required String deviceId,
  }) async {
    final response = await publicClient.request<Object?>(
      'auth/active',
      method: 'POST',
      data: FormData.fromMap({
        'phone': phone,
        'verification_code': code,
        if (fcmToken != null && fcmToken.isNotEmpty) 'fcm_token': fcmToken,
        'device_id': deviceId,
      }),
    );
    final body = response.data;
    final data = body is Map ? body['data'] : null;
    final token = data is Map ? data['token'] : null;
    if (token is! String || token.isEmpty || token.contains(RegExp(r'\s'))) {
      throw AppFailure(
        AppCopy.unexpectedResponse,
        backendBody: body,
        requestMethod: 'POST',
        requestPath: 'auth/active',
      );
    }
    return token;
  }

  Future<List<GovernorateOption>> governorates() async {
    final response = await authenticatedClient.request<Object?>(
      'governorates/all',
    );
    final data = _data(response.data);
    if (data is! Map) {
      throw AppFailure(AppCopy.unexpectedResponse, backendBody: response.data);
    }
    return [
      for (final entry in data.entries)
        if (entry.key is String && entry.value is String)
          GovernorateOption(
            key: entry.key as String,
            name: entry.value as String,
          ),
    ];
  }

  Future<List<RegistrationOption>> branches() => _options('branches/all');

  Future<List<RegistrationOption>> schools({
    required int type,
    required String governorate,
  }) => _options(
    'schools/all',
    query: {'type': type, 'governorate': governorate},
  );

  Future<List<RegistrationOption>> _options(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final response = await authenticatedClient.request<Object?>(
      path,
      queryParameters: query,
    );
    final data = _data(response.data);
    if (data is! List) {
      throw AppFailure(AppCopy.unexpectedResponse, backendBody: response.data);
    }
    return [
      for (final item in data)
        if (item is Map && item['id'] is int && item['name'] is String)
          RegistrationOption(
            id: item['id'] as int,
            name: item['name'] as String,
          ),
    ];
  }

  Future<void> completeProfile(RegistrationDraft draft) async {
    final response = await authenticatedClient.request<Object?>(
      'users/edit',
      method: 'POST',
      data: FormData.fromMap({
        'f_name': draft.firstName.trim(),
        'l_name': draft.lastName.trim(),
        'email': draft.email.trim(),
        'school_id': draft.schoolId,
        'know_about_app': switch (draft.referralSource!) {
          ReferralSource.facebook => 1,
          ReferralSource.instagram => 2,
          ReferralSource.friend => 3,
          ReferralSource.school => 4,
          ReferralSource.other => 5,
        },
        'gender': draft.gender == Gender.female ? 0 : 1,
        'age': draft.age,
        'branch_id': draft.branchId,
      }),
    );
    _data(response.data);
  }

  Future<bool> profileCompleted() async {
    try {
      final response = await authenticatedClient.request<Object?>(
        'profile/get',
      );
      final data = _data(response.data);
      if (data is! Map) {
        throw AppFailure(
          AppCopy.unexpectedResponse,
          backendBody: response.data,
        );
      }
      return true;
    } on AppFailure catch (error) {
      final body = error.backendBody;
      if (error.statusCode == 400 &&
          body is Map &&
          body['message'] is String &&
          (body['message'] as String).contains('ليس لديه فرع')) {
        return false;
      }
      rethrow;
    }
  }

  Object? _data(Object? body) {
    if (body is! Map || !body.containsKey('data')) {
      throw AppFailure(AppCopy.unexpectedResponse, backendBody: body);
    }
    return body['data'];
  }

  Future<void> logout() async {
    await authenticatedClient.request<Object?>('auth/logout');
  }

  Future<void> deleteAccount() async {
    await authenticatedClient.request<Object?>('auth/delete', method: 'POST');
  }
}
