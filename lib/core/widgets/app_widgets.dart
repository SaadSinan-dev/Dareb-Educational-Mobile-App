export 'app_header.dart';
import 'app_header.dart';
import 'package:tamkeen2/core/theme/design_tokens.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tamkeen2/core/router/app_routes.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/core/validation/app_validators.dart';

void showAppMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: AppText(message)));
}

class AppDecisionDialog extends StatelessWidget {
  const AppDecisionDialog({
    super.key,
    required this.title,
    required this.confirmLabel,
    this.warning = false,
  });
  final String title, confirmLabel;
  final bool warning;
  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: context.colors.surface,
    insetPadding: const EdgeInsets.symmetric(horizontal: 40),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (warning)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.redAccent
                        : context.colors.error,
                    size: 26,
                  ),
                ),
              Expanded(
                child: AppText(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: context.tr(AppCopy.closeAction),
                onPressed: () => Navigator.pop(context, false),
                icon: Icon(
                  Icons.cancel_outlined,
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.grey
                      : context.colors.muted,
                  size: 30,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: AppText(confirmLabel),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.colors.secondary,
                      side: BorderSide(color: context.colors.secondary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: const AppText(AppCopy.goBackAction),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.child,
    required this.index,
    this.onIndexChanged,
  });
  final Widget child;
  final int index;
  final ValueChanged<int>? onIndexChanged;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.colors.primary,
    body: SafeArea(
      child: ColoredBox(
        color: context.colors.background,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 768),
            child: child,
          ),
        ),
      ),
    ),
    bottomNavigationBar: ColoredBox(
      color: context.colors.surface,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              for (var i = 0; i < 4; i++)
                Expanded(
                  child: Semantics(
                    selected: index == i,
                    button: true,
                    label: context.tr(
                      const [
                        AppCopy.homeTab,
                        AppCopy.mySubjectsTab,
                        AppCopy.galleryTitle,
                        AppCopy.profileTitle,
                      ][i],
                    ),
                    child: InkWell(
                      key: ValueKey('bottom-tab-$i'),
                      onTap: () => onIndexChanged != null
                          ? onIndexChanged!(i)
                          : context.go(
                              const [
                                AppRoutes.home,
                                AppRoutes.myLearning,
                                AppRoutes.gallery,
                                AppRoutes.profile,
                              ][i],
                            ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              index == i
                                  ? context.colors.primary
                                  : Theme.of(context).brightness ==
                                        Brightness.light
                                  ? AppIconTokens.inactiveNavigation
                                  : context.colors.muted,
                              BlendMode.srcIn,
                            ),
                            child: SizedBox(
                              width: AppIconTokens.navigationCanvas,
                              height: AppIconTokens.navigationCanvas,
                              child: Center(
                                child: Image.asset(
                                  'assets/icons/nav_${const ['home', 'learning', 'gallery', 'profile'][i]}.png',
                                  width: i == 0
                                      ? 17
                                      : AppIconTokens.navigationCanvas,
                                  height: i == 0
                                      ? 19
                                      : AppIconTokens.navigationCanvas,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: i == 0 ? 18 : 28,
                            height: 2,
                            color: index == i
                                ? context.colors.primary
                                : Colors.transparent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class PageLayout extends StatelessWidget {
  const PageLayout({
    super.key,
    required this.title,
    this.children = const [],
    this.body,
    this.actions,
    this.header,
    this.back = true,
    this.padding = const EdgeInsets.fromLTRB(16, 22, 16, 24),
  });
  final String title;
  final List<Widget> children;
  final List<Widget>? actions;
  final Widget? header;
  final Widget? body;
  final bool back;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.colors.primary,
    body: SafeArea(
      bottom: false,
      child: ColoredBox(
        color: context.colors.background,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 768),
            child: header != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [
                      header!,
                      Padding(
                        padding: padding.add(
                          EdgeInsets.only(
                            bottom: MediaQuery.paddingOf(context).bottom,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: children,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      AppHeader(
                        title: title,
                        leading: back
                            ? IconButton(
                                tooltip: context.tr(AppCopy.backAction),
                                onPressed: () {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.go(AppRoutes.home);
                                  }
                                },
                                icon: Icon(
                                  Icons.arrow_back,
                                  color: context.colors.onBrand,
                                ),
                              )
                            : null,
                        actions:
                            actions ??
                            [
                              HeaderNotificationAction(
                                onPressed: () =>
                                    context.push(AppRoutes.notifications),
                              ),
                            ],
                      ),
                      Expanded(
                        child:
                            body ??
                            ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: padding.add(
                                EdgeInsets.only(
                                  bottom: MediaQuery.paddingOf(context).bottom,
                                ),
                              ),
                              children: children,
                            ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    ),
  );
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({super.key, required this.child, this.padding = 16});
  final Widget child;
  final double padding;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: context.colors.surface,
      border: Border.all(color: context.colors.border),
      borderRadius: BorderRadius.circular(18),
    ),
    child: child,
  );
}

class AppSearch extends StatefulWidget {
  const AppSearch({
    super.key,
    required this.onChanged,
    this.value = '',
    this.onTap,
    this.onSubmitted,
  });
  final ValueChanged<String> onChanged;
  final String value;
  final VoidCallback? onTap;
  final ValueChanged<String>? onSubmitted;
  @override
  State<AppSearch> createState() => _AppSearchState();
}

class _AppSearchState extends State<AppSearch> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );
  @override
  void didUpdateWidget(AppSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Echoes from Cubit must not reset the Arabic IME selection/composition.
    if (widget.value != _controller.text && widget.value != oldWidget.value) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextFormField(
    key: ValueKey(widget.onTap == null ? 'editable-search' : 'search-link'),
    controller: _controller,
    onChanged: widget.onChanged,
    onFieldSubmitted: widget.onSubmitted ?? widget.onChanged,
    onTap: widget.onTap,
    readOnly: widget.onTap != null,
    textDirection: Directionality.of(context),
    textAlign: TextAlign.start,
    keyboardType: TextInputType.text,
    validator: (value) {
      final error = AppValidators.search(value);
      return error == null ? null : context.tr(error);
    },
    autovalidateMode: AutovalidateMode.onUserInteraction,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      hintText: context.tr(AppCopy.searchHereHint),
      prefixIcon: Icon(Icons.search, color: context.colors.secondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.onSeeAll});
  final String title;
  final VoidCallback? onSeeAll;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Row(
      children: [
        Expanded(
          child: AppText(
            title,
            style: TextStyle(color: context.colors.primary, fontSize: 16),
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const AppText(AppCopy.showAllAction),
          ),
      ],
    ),
  );
}

class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
  });
  final double? width;
  final double height, radius;
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: context.colors.skeleton,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}
