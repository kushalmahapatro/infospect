import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:menu_bar/menu_bar.dart';

/// state for the invoker widget (defaults to alwaysOpened)
enum InvokerState {
  /// alwaysOpened: This will force the the invoker widget to be opened always
  alwaysOpened,

  /// collapsable: This will make the widget to collapse and expand on demand
  /// By default it will be in collapsed state
  /// Tap or outwards will expand the widget
  /// When expanded, tapping on it will navigate to Infospect screen.
  /// And swiping it inwards will change it to collapsed state
  collapsable,

  /// autoCollapse: This will auto change the widget state from expanded to collapse after 5 seconds
  /// By default it will be in collapsed state
  /// Tap or outwards will expand the widget and if not tapped within 5 secs, it will change to
  /// collapsed state.
  /// When expanded, tapping on it will navigate to Infospect screen and will change it to
  /// collapsed state
  /// And swiping it inwards will change it to collapsed state
  autoCollapse
}

class InfospectInvoker extends StatefulWidget {
  const InfospectInvoker({
    super.key,
    required this.child,
    required this.infospect,
    this.state = InvokerState.alwaysOpened,
  });

  final Widget child;
  final Infospect infospect;
  final InvokerState state;

  @override
  State<InfospectInvoker> createState() => _DevOptionsBuilderState();
}

class _DevOptionsBuilderState extends State<InfospectInvoker> {
  double end = 0;
  late BorderRadiusGeometry borderRadius;
  late double width;
  Timer? timer;

  void initialValues({bool isInit = false}) {
    if (widget.state == InvokerState.alwaysOpened) {
      end = 2;
      borderRadius = BorderRadius.circular(25);
      width = 50;
    } else if (widget.state == InvokerState.autoCollapse ||
        widget.state == InvokerState.collapsable) {
      if (end == 0 && !isInit) return;
      end = 0;
      borderRadius = const BorderRadiusDirectional.only(
        topStart: Radius.circular(5),
        bottomStart: Radius.circular(5),
      );
      width = 5;
    }
    setState(() {});
  }

  void changedValues() {
    if (end == 2) return;
    end = 2;
    borderRadius = BorderRadius.circular(25);
    width = 50;
    setState(() {});
  }

  void startTimer() {
    if (widget.state == InvokerState.autoCollapse) {
      timer = Timer.periodic(
          const Duration(seconds: 5), (timer) => setState(initialValues));
    }
  }

  @override
  void initState() {
    initialValues(isInit: true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return widget.child;

    if (Platform.isMacOS) {
      return _MacOsMenuBarWidget(
        widget: widget,
      );
    } else if (Platform.isWindows || Platform.isLinux) {
      return _OtherDesktopMenuBarWidget(
        widget: widget,
      );
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        alignment: Alignment.bottomCenter,
        fit: StackFit.loose,
        children: [
          widget.child,
          ValueListenableBuilder<bool>(
            valueListenable: widget.infospect.isInspectorOpened,
            builder: (context, value, child) {
              if (value) {
                return const SizedBox();
              } else {
                return child ?? const SizedBox();
              }
            },
            child: AnimatedPositionedDirectional(
              duration: const Duration(milliseconds: 300),
              bottom: 30,
              end: end,
              child: SafeArea(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: (details) {
                    switch (widget.state) {
                      case InvokerState.collapsable ||
                            InvokerState.autoCollapse:
                        timer?.cancel();
                        if (details.delta.dx < 0) {
                          changedValues();
                          startTimer();
                        } else if (details.delta.dx > 0) {
                          initialValues();
                        }
                        break;

                      case InvokerState.alwaysOpened:
                        break;
                    }
                  },
                  onTap: () {
                    switch (widget.state) {
                      case InvokerState.autoCollapse:
                        timer?.cancel();
                        if (end == 0) {
                          changedValues();
                          startTimer();
                        } else {
                          initialValues();
                          widget.infospect.navigateToInterceptor();
                        }
                        break;

                      case InvokerState.collapsable:
                        if (end == 0) {
                          changedValues();
                        } else {
                          widget.infospect.navigateToInterceptor();
                        }
                        break;

                      case InvokerState.alwaysOpened:
                        widget.infospect.navigateToInterceptor();
                        break;
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 20),
                    child: Theme(
                      data: Theme.of(context),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                                  .elevatedButtonTheme
                                  .style
                                  ?.backgroundColor
                                  ?.resolve({MaterialState.focused}) ??
                              Colors.red,
                          borderRadius: borderRadius,
                        ),
                        height: 50,
                        width: width,
                        child: width == 50
                            ? const Icon(
                                FontAwesomeIcons.code,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtherDesktopMenuBarWidget extends StatelessWidget {
  const _OtherDesktopMenuBarWidget({
    required this.widget,
  });

  final InfospectInvoker widget;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) {
            return MenuBarWidget(
              barButtons: [
                BarButton(
                  text: const Text('Options'),
                  submenu: SubMenu(
                    menuItems: [
                      MenuButton(
                        text: const Text('Infospect'),
                        shortcutText: 'Ctrl+I',
                        shortcut: SingleActivator(
                          LogicalKeyboardKey.keyI,
                          meta: Platform.isMacOS,
                          control: !Platform.isMacOS,
                        ),
                        onTap: () async =>
                            await widget.infospect.openInspectorInNewWindow(),
                      )
                    ],
                  ),
                )
              ],
              child: widget.child,
            );
          },
        );
      },
    );
  }
}

class _MacOsMenuBarWidget extends StatelessWidget {
  const _MacOsMenuBarWidget({
    required this.widget,
  });

  final InfospectInvoker widget;

  @override
  Widget build(BuildContext context) {
    return PlatformMenuBar(
      menus: <PlatformMenuItem>[
        PlatformMenu(
          label: 'Options',
          menus: <PlatformMenuItem>[
            PlatformMenuItem(
              onSelected: () async {
                await widget.infospect.openInspectorInNewWindow();
              },
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyI,
                meta: true,
              ),
              label: 'Infospect',
            ),
          ],
        ),
      ],
      child: widget.child,
    );
  }
}
