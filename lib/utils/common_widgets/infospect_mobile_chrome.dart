import 'package:flutter/material.dart';

/// Shared mobile chrome sizes for Infospect list / pushed screens.
abstract final class InfospectMobileChrome {
  static const double toolbarHeight = 40;
  static const double backIconSize = 20;
  static const Size backTapTarget = Size(40, 40);
  static const EdgeInsets toolbarPadding = EdgeInsets.only(left: 4, right: 4);
  static const double titleFontSize = 13;
}

/// Compact back / close control matching the main Infospect mobile shell.
class InfospectCompactBackButton extends StatelessWidget {
  const InfospectCompactBackButton({
    super.key,
    this.onPressed,
    this.tooltip = 'Back',
  });

  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tight(InfospectMobileChrome.backTapTarget),
      icon: const Icon(
        Icons.arrow_back_rounded,
        size: InfospectMobileChrome.backIconSize,
      ),
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
    );
  }
}

/// Flat 40px mobile toolbar used by pushed Infospect screens (Breakpoints,
/// network details, etc.) so they match the main list chrome density.
class InfospectMobileToolbar extends StatelessWidget
    implements PreferredSizeWidget {
  const InfospectMobileToolbar({
    super.key,
    required this.title,
    this.leading,
    this.actions = const [],
    this.automaticallyImplyLeading = true,
  });

  final Widget title;
  final Widget? leading;
  final List<Widget> actions;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize =>
      const Size.fromHeight(InfospectMobileChrome.toolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final Widget? resolvedLeading = leading ??
        (automaticallyImplyLeading && canPop
            ? const InfospectCompactBackButton()
            : null);

    return Material(
      color: theme.colorScheme.surface,
      child: SizedBox(
        height: InfospectMobileChrome.toolbarHeight,
        child: Padding(
          padding: InfospectMobileChrome.toolbarPadding,
          child: NavigationToolbar(
            centerMiddle: false,
            leading: resolvedLeading,
            middle: DefaultTextStyle(
              style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: InfospectMobileChrome.titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ) ??
                  const TextStyle(
                    fontSize: InfospectMobileChrome.titleFontSize,
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              child: title,
            ),
            trailing: actions.isEmpty
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions,
                  ),
            middleSpacing: 8,
          ),
        ),
      ),
    );
  }
}
