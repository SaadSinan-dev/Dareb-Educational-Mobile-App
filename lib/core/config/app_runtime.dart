import 'package:flutter/widgets.dart';

/// Immutable run configuration supplied by the application composition root.
class AppRuntime extends InheritedWidget {
  const AppRuntime({super.key, required this.preview, required super.child});
  final bool preview;
  static bool? previewOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppRuntime>()?.preview;
  @override
  bool updateShouldNotify(AppRuntime oldWidget) => preview != oldWidget.preview;
}
