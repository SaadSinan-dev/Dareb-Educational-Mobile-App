import 'support/live_test_config.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tamkeen2/core/di/service_locator.dart';
import 'package:tamkeen2/core/network/api_client.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';

// Explicit mutating QA test for the Postman-confirmed image upload operation.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('update image is confirmed by profile/get', (tester) async {
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
    final client = services<ApiClient>();
    final before = await client.request<Object?>('profile/get');
    final previous = _image(before.data);
    final bytes = await rootBundle.load('assets/images/avatar.png');
    final upload = await client.request<Object?>(
      'users/update-image',
      method: 'POST',
      data: FormData.fromMap({
        'image': MultipartFile.fromBytes(
          bytes.buffer.asUint8List(),
          filename: 'qa-avatar.png',
          contentType: DioMediaType.parse('image/png'),
        ),
      }),
    );
    expect(upload.statusCode, 200);
    final after = await client.request<Object?>('profile/get');
    final current = _image(after.data);
    expect(current, isNotEmpty);
    expect(Uri.tryParse(current)?.scheme, 'https');
    // Safe evidence only: no account data, response body, or credential values.
    // ignore: avoid_print
    print(
      'IMAGE upload=${upload.statusCode} profile=${after.statusCode} changed=${previous != current}',
    );
  });
}

String _image(Object? body) {
  if (body is! Map || body['data'] is! Map) return '';
  final value = (body['data'] as Map)['image'];
  return value is String ? value : '';
}
