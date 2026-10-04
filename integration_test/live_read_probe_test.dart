import 'support/live_test_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tamkeen2/core/di/service_locator.dart';
import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/core/network/api_client.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';

// Explicit device-only contract probe. Reports keys and status, never values.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('read authenticated feature shapes', (tester) async {
    const phone = String.fromEnvironment('LIVE_ACCOUNT_PHONE');
    if (phone.isEmpty) fail('Set LIVE_ACCOUNT_PHONE to a dedicated QA number.');
    configureDependencies();
    final auth = services<AuthCubit>();
    final code = liveTestCode();
    await auth.requestCode(phone);
    expect(auth.state.status, AuthStatus.codeSent, reason: auth.state.error);
    await auth.verifyCode(code);
    expect(
      auth.state.status,
      AuthStatus.authenticated,
      reason: auth.state.error,
    );
    final governorates = await auth.governorates();
    final sampledGovernorates = <String>{
      ...governorates.take(3).map((item) => item.key),
      if (governorates.any((item) => item.key == 'damascus')) 'damascus',
    };
    for (final governorate in sampledGovernorates) {
      for (final type in [1, 2]) {
        final schools = await auth.schools(
          type: type,
          governorate: governorate,
        );
        // ignore: avoid_print
        print(
          'SCHOOLS governorate=$governorate type=$type count=${schools.length}',
        );
      }
    }
    final client = services<ApiClient>();
    final reads = <(String, Map<String, dynamic>?)>[
      ('profile/get', null),
      ('profile/points', {'page': 1, 'perPage': 10}),
      ('profile/medals', {'page': 1, 'perPage': 10}),
      ('profile/cups', {'page': 1, 'perPage': 10}),
      ('notifications/get', {'page': 1}),
      ('faqs/all', null),
      ('galleries/all', null),
      ('exams/my', null),
      ('daily-activities/my', null),
      ('subscriptions/my', null),
      ('payment-methods/all', null),
      ('packages/all', null),
    ];
    for (final (path, query) in reads) {
      try {
        final response = await client.request<Object?>(
          path,
          queryParameters: query,
        );
        final body = response.data;
        final data = body is Map ? body['data'] : null;
        // ignore: avoid_print
        print('READ $path status=${response.statusCode} shape=${_shape(data)}');
        if (path == 'profile/get' && data is Map) {
          final image = data['image'];
          final uri = image is String ? Uri.tryParse(image) : null;
          // ignore: avoid_print
          print(
            'PROFILE IMAGE present=${image != null} absoluteHttps=${uri?.scheme == 'https' && uri?.hasAuthority == true}',
          );
        }
      } on AppFailure catch (error) {
        // ignore: avoid_print
        print('READ $path status=${error.statusCode} failure=${error.message}');
      }
    }
  });
}

String _shape(Object? value) {
  if (value is List) {
    final first = value.isEmpty ? null : value.first;
    return 'list(length=${value.length}, item=${_shape(first)})';
  }
  if (value is Map) {
    final keys = value.keys.map((key) => '$key').toList()..sort();
    return 'map(keys=$keys)';
  }
  return value == null ? 'null' : value.runtimeType.toString();
}
