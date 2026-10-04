import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tamkeen2/application/app_bootstrap_cubit.dart';
import 'package:tamkeen2/core/di/service_locator.dart';
import 'package:tamkeen2/core/network/api_client.dart';
import 'package:tamkeen2/core/router/app_routes.dart';
import 'package:tamkeen2/features/account/domain/account_repository.dart';
import 'package:tamkeen2/features/auth/data/auth_session_store.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';
import 'package:tamkeen2/main.dart' as application;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies(demoMode: false);
  final auth = services<AuthCubit>();
  final sessions = services<AuthSessionStore>();
  final client = services<ApiClient>();
  final onlineTransport = client.dio.httpClientAdapter;
  String? activatedToken;
  int profileResponses = 0;
  bool? bearerVerified;

  services<ApiClient>(instanceName: 'public').dio.interceptors.add(
    InterceptorsWrapper(
      onResponse: (response, handler) {
        if (response.requestOptions.path == 'auth/active') {
          final body = response.data;
          final data = body is Map ? body['data'] : null;
          activatedToken = data is Map && data['token'] is String
              ? data['token'] as String
              : null;
        }
        handler.next(response);
      },
    ),
  );
  client.dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (options.path == 'profile/get') {
          final session = await sessions.readSession();
          bearerVerified =
              session != null &&
              options.headers['Authorization'] == 'Bearer ${session.token}';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (response.requestOptions.path == 'profile/get' &&
            response.statusCode == 200) {
          profileResponses++;
        }
        handler.next(response);
      },
    ),
  );
  if (const bool.fromEnvironment('SESSION_AUDIT_OFFLINE')) {
    client.dio.httpClientAdapter = _OfflineTransport();
  }

  BuildContext? appContext() {
    BuildContext? result;
    void visit(Element element) {
      if (element.widget is BlocBuilder<AppBootstrapCubit, BootstrapState>) {
        result = element;
      }
      element.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(visit);
    return result;
  }

  String? route() {
    String? result;
    void visit(Element element) {
      if (element.widget is Scaffold) {
        try {
          result = GoRouter.of(element).routeInformationProvider.value.uri.path;
        } catch (_) {}
      }
      element.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(visit);
    return result;
  }

  registerExtension('ext.tamkeen.sessionAudit', (method, parameters) async {
    try {
      final action = parameters['action'] ?? 'snapshot';
      final before = await sessions.readSession();
      bool? preserved;
      bool? profileLoaded;
      switch (action) {
        case 'snapshot':
          break;
        case 'profile':
          final user = auth.state.user;
          if (user == null) throw StateError('Session is not authenticated');
          final account = await services<AccountRepository>().load(user.id);
          profileLoaded = account.profile != null;
          final context = appContext();
          if (context != null) {
            void navigate(Element element) {
              try {
                GoRouter.of(element).go(AppRoutes.profile);
              } catch (_) {
                element.visitChildren(navigate);
              }
            }

            (context as Element).visitChildren(navigate);
          }
        case 'network-failure':
          if (before == null || auth.state.user == null) {
            throw StateError('A real authenticated session is required');
          }
          client.dio.httpClientAdapter = _OfflineTransport();
          try {
            await auth.refreshSession();
          } finally {
            client.dio.httpClientAdapter = onlineTransport;
          }
          preserved = (await sessions.readSession())?.token == before.token;
        case 'retry-network':
          client.dio.httpClientAdapter = onlineTransport;
          final context = appContext();
          if (context == null || !context.mounted) {
            throw StateError('Bootstrap is unavailable');
          }
          await context.read<AppBootstrapCubit>().initialize();
          preserved =
              before != null &&
              (await sessions.readSession())?.token == before.token;
        case 'logout':
          await auth.logout();
        case 'revoked':
          if (before == null) {
            throw StateError('A real authenticated session is required');
          }
          await auth.logout();
          if (auth.state.error != null) {
            throw StateError(
              'Backend logout must succeed before testing revocation',
            );
          }
          await sessions.saveSession(before);
          await auth.restore();
        default:
          throw StateError('Unknown audit action');
      }
      final session = await sessions.readSession();
      final context = appContext();
      final bootstrap = context?.read<AppBootstrapCubit>();
      return ServiceExtensionResponse.result(
        jsonEncode({
          'action': action,
          'persisted': session != null,
          'auth': auth.state.status.name,
          'authenticated': auth.state.user != null,
          'bootstrap': bootstrap?.state.status.name,
          'route': route(),
          'profile_responses': profileResponses,
          'bearer_verified': bearerVerified,
          'activation_persisted': activatedToken == null
              ? null
              : session?.token == activatedToken,
          'token_preserved': preserved,
          'profile_loaded': profileLoaded,
          'has_session_error': auth.state.error != null,
        }),
      );
    } catch (_) {
      return ServiceExtensionResponse.error(
        ServiceExtensionResponse.extensionError,
        'Session audit action failed; no credentials are included.',
      );
    }
  });
  application.main();
}

class _OfflineTransport implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => throw DioException(
    requestOptions: options,
    type: DioExceptionType.connectionError,
  );

  @override
  void close({bool force = false}) {}
}
