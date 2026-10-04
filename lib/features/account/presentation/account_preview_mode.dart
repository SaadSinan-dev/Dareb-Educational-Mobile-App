import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tamkeen2/core/config/app_config.dart';
import 'package:tamkeen2/core/config/app_runtime.dart';
import 'account_cubit.dart';

bool accountPreviewMode(BuildContext context, bool? override) {
  if (override != null) return override;
  final configured = AppRuntime.previewOf(context);
  if (configured != null) return configured;
  // Standalone feature previews can supply their already-loaded account state.
  try {
    return context.read<AccountCubit>().state.data.preview;
  } on ProviderNotFoundException {
    return AppConfig.demoMode;
  }
}
