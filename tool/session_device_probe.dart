import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty) {
    stderr.writeln(
      'Usage: dart run tool/session_device_probe.dart <VM service URI> [action]',
    );
    exitCode = 1;
    return;
  }
  final service = Uri.parse(arguments.first);
  final path = service.path.endsWith('/') ? service.path : '${service.path}/';
  final socket = await WebSocket.connect(
    service
        .replace(
          scheme: service.scheme == 'https' ? 'wss' : 'ws',
          path: '${path}ws',
        )
        .toString(),
  );
  int nextId = 0;
  final pending = <int, Completer<Map<String, dynamic>>>{};
  final subscription = socket.listen((event) {
    final response = jsonDecode(event as String) as Map<String, dynamic>;
    final identifier = response['id'];
    if (identifier is int) pending.remove(identifier)?.complete(response);
  });
  Future<Map<String, dynamic>> call(
    String method, [
    Map<String, dynamic>? parameters,
  ]) async {
    final identifier = ++nextId;
    final result = Completer<Map<String, dynamic>>();
    pending[identifier] = result;
    socket.add(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': identifier,
        'method': method,
        'params': ?parameters,
      }),
    );
    final response = await result.future.timeout(const Duration(seconds: 45));
    if (response.containsKey('error')) {
      throw StateError('VM audit request failed');
    }
    return response['result'] as Map<String, dynamic>;
  }

  try {
    final machine = await call('getVM');
    final isolates = machine['isolates'] as List;
    final isolate = isolates.cast<Map>().firstWhere(
      (value) => value['name'] == 'main',
    );
    final response = await call('ext.tamkeen.sessionAudit', {
      'isolateId': isolate['id'],
      'action': arguments.length > 1 ? arguments[1] : 'snapshot',
    });
    stdout.writeln(jsonEncode(response));
  } finally {
    await subscription.cancel();
    await socket.close();
  }
}
