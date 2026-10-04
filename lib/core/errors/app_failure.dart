import 'package:tamkeen2/l10n/app_copy.g.dart';

/// An application error safe to show to the user.
class AppFailure implements Exception {
  const AppFailure(
    this.message, {
    this.statusCode,
    this.backendBody,
    this.transportType,
    this.requestMethod,
    this.requestPath,
  });
  const AppFailure.unavailable()
    : message = AppCopy.serviceUnavailable,
      statusCode = null,
      backendBody = null,
      transportType = null,
      requestMethod = null,
      requestPath = null;

  final String message;
  final int? statusCode;

  /// Original response kept for diagnostics; never display or log unredacted.
  final Object? backendBody;
  final String? transportType;
  final String? requestMethod;
  final String? requestPath;

  @override
  String toString() => message;
}
