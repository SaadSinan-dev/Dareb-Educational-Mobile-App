import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:tamkeen2/core/config/app_config.dart';
import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/core/network/network_issue.dart';
import 'network_issue_stub.dart'
    if (dart.library.io) 'network_issue_io.dart'
    as platform;

/// Transport only. No API endpoint or response contract is assumed.
class ApiClient {
  ApiClient({
    String? baseUrl,
    this.onUnauthorized,
    this.authorizationHeaderProvider,
  }) : dio = Dio(
         BaseOptions(
           baseUrl:
               '${(baseUrl ?? AppConfig.apiBaseUrl).replaceFirst(RegExp(r'/+$'), '')}/',
           connectTimeout: const Duration(seconds: 15),
           receiveTimeout: const Duration(seconds: 15),
           sendTimeout: const Duration(seconds: 15),
           followRedirects: false,
           headers: {'Accept': 'application/json'},
           responseType: ResponseType.json,
         ),
       ) {
    final configuredBase = Uri.parse(dio.options.baseUrl);
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final destination = options.uri;
            if (destination.origin != configuredBase.origin ||
                !destination.path.startsWith(configuredBase.path) ||
                !_validPath(options.path)) {
              throw const AppFailure(AppCopy.unexpectedClientError);
            }
            options.followRedirects = false;
            final authorization = (await authorizationHeaderProvider?.call())
                ?.trim();
            options.headers.removeWhere(
              (key, _) => key.toLowerCase() == 'authorization',
            );
            if (authorization != null && authorization.isNotEmpty) {
              if (authorization.contains(RegExp(r'[\r\n]'))) {
                throw const AppFailure(AppCopy.unexpectedClientError);
              }
              options.headers['Authorization'] = authorization;
            }
            handler.next(options);
          } catch (cause) {
            handler.reject(
              DioException(
                requestOptions: options,
                error: cause is AppFailure
                    ? cause
                    : const AppFailure(AppCopy.unexpectedClientError),
              ),
            );
          }
        },
        onError: (error, handler) async {
          assert(() {
            _debugRequestFailure(error);
            return true;
          }());
          if (error.response?.statusCode == 401) {
            try {
              final provider = authorizationHeaderProvider;
              final rejected = error.requestOptions.headers['Authorization'];
              if (provider == null ||
                  (rejected != null &&
                      rejected == (await provider())?.trim())) {
                await onUnauthorized?.call(
                  rejected is String ? rejected : null,
                );
              }
            } catch (_) {
              // Session cleanup must not replace the safe HTTP failure.
            }
          }
          handler.next(error.copyWith(error: _failure(error)));
        },
      ),
    );
  }

  final Dio dio;
  final FutureOr<void> Function(String? authorization)? onUnauthorized;

  /// Read fresh credentials for each request. The verified auth integration
  /// supplies the complete header, including its scheme. No scheme is assumed.
  /// Returning null removes authorization, including after logout.
  final FutureOr<String?> Function()? authorizationHeaderProvider;

  /// Callers supply verified paths/methods; no auth scheme or response is assumed.
  Future<Response<T>> request<T>(
    String path, {
    String method = 'GET',
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    if (!_validPath(path)) {
      throw const AppFailure(AppCopy.unexpectedClientError);
    }
    try {
      return await dio.request<T>(
        path.replaceFirst(RegExp(r'^/+'), ''),
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: Options(method: method),
      );
    } on DioException catch (error) {
      throw error.error is AppFailure ? error.error! : _failure(error);
    }
  }

  static bool _validPath(String path) {
    final uri = Uri.tryParse(path);
    final segments = path.split('?').first.split('/');
    return uri != null &&
        !uri.hasScheme &&
        !uri.hasAuthority &&
        !uri.hasFragment &&
        !path.startsWith('//') &&
        !segments.any(_unsafeSegment);
  }

  static AppFailure _failure(DioException error) {
    if (error.error is AppFailure) return error.error! as AppFailure;
    final status = error.response?.statusCode;
    final message = switch (status) {
      400 => AppCopy.badRequest,
      401 => AppCopy.sessionExpired,
      403 => AppCopy.accessDenied,
      404 => AppCopy.contentUnavailable,
      409 => AppCopy.dataChanged,
      422 => AppCopy.requestValidationFailed,
      429 => AppCopy.tooManyRequests,
      500 => AppCopy.serverError,
      502 => AppCopy.badGateway,
      503 => AppCopy.backendTemporarilyUnavailable,
      _ => switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout => AppCopy.connectionTimedOut,
        DioExceptionType.connectionError => switch (platform.detectNetworkIssue(
          error.error,
        )) {
          NetworkIssue.offline => AppCopy.noInternetConnection,
          NetworkIssue.dns => AppCopy.dnsLookupFailed,
          null => AppCopy.connectionFailed,
        },
        DioExceptionType.badCertificate => AppCopy.secureConnectionFailed,
        DioExceptionType.cancel => AppCopy.requestCancelled,
        _ when error.error is FormatException => AppCopy.unexpectedResponse,
        _ => AppCopy.unexpectedClientError,
      },
    };
    return AppFailure(
      message,
      statusCode: status,
      backendBody: error.response?.data,
      transportType: error.type.name,
      requestMethod: error.requestOptions.method,
      requestPath: error.requestOptions.uri.path,
    );
  }

  static bool _unsafeSegment(String segment) {
    try {
      final decoded = Uri.decodeComponent(segment);
      return decoded == '.' ||
          decoded == '..' ||
          decoded.contains('/') ||
          decoded.contains('\\') ||
          decoded.contains('%');
    } on FormatException {
      return true;
    }
  }

  static void _debugRequestFailure(DioException error) {
    final request = error.requestOptions;
    final data = request.data;
    final fieldNames = switch (data) {
      FormData value => value.fields.map((field) => field.key),
      Map value => value.keys.map((key) => '$key'),
      _ => const <String>[],
    };
    final safeFields = fieldNames.where(_safeDiagnosticName).toList();
    final response = error.response?.data;
    final responseKeys = response is Map
        ? response.keys.map((key) => '$key').where(_safeDiagnosticName).toList()
        : const <String>[];
    // Values, query parameters, authorization, OTPs, and raw bodies are omitted.
    debugPrint(
      'API ${request.method} ${request.uri.path} '
      'status=${error.response?.statusCode ?? 'none'} '
      'type=${error.type.name} fields=$safeFields responseKeys=$responseKeys',
    );
  }

  static bool _safeDiagnosticName(String value) =>
      value.length <= 48 && RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value);
}
