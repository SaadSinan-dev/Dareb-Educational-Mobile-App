import 'dart:io';

import 'package:dio/dio.dart';

import 'package:tamkeen2/core/network/network_issue.dart';

/// Classify only transport errors that the platform identifies unambiguously.
NetworkIssue? detectNetworkIssue(Object? error) {
  final cause = error is DioException ? error.error : error;
  if (cause is! SocketException) return null;
  if (cause.message.startsWith('Failed host lookup')) return NetworkIssue.dns;
  if ({100, 101, 113, 10051, 10065}.contains(cause.osError?.errorCode)) {
    return NetworkIssue.offline;
  }
  return null;
}
