import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';

abstract final class ApiValues {
  static Map<String, dynamic> object(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const AppFailure(AppCopy.unexpectedResponse);
    }
    return value;
  }

  static List<Map<String, dynamic>> objects(Object? value) {
    if (value is! List) throw const AppFailure(AppCopy.unexpectedResponse);
    return List.unmodifiable(value.map(object));
  }

  static String id(Object? value) {
    if (value is! int || value <= 0) {
      throw const AppFailure(AppCopy.unexpectedResponse);
    }
    return '$value';
  }

  static int requestId(String value) {
    final parsed = int.tryParse(value);
    if (parsed == null || parsed <= 0 || '$parsed' != value) {
      throw const AppFailure(AppCopy.badRequest);
    }
    return parsed;
  }

  static String text(Object? value) {
    if (value is! String) throw const AppFailure(AppCopy.unexpectedResponse);
    return value;
  }

  static String? optionalText(Object? value) =>
      value == null ? null : text(value);
  static int? count(Object? value) {
    if (value == null) return null;
    if (value is! int || value < 0) {
      throw const AppFailure(AppCopy.unexpectedResponse);
    }
    return value;
  }

  static bool? flag(Object? value) {
    if (value == null) return null;
    if (value is! bool) throw const AppFailure(AppCopy.unexpectedResponse);
    return value;
  }
}
