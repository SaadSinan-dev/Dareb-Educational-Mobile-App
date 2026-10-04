import 'app_failure.dart';
import '../../l10n/app_copy.g.dart';

String failureMessage(Object error) =>
    error is AppFailure ? error.message : AppCopy.unexpectedClientError;
