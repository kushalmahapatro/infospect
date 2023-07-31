import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:infospect/helpers/infospect_helper.dart';

class InfospectInvoker extends StatefulWidget {
  const InfospectInvoker(
      {super.key, required this.child, required this.infospect});

  final Widget child;
  final Infospect infospect;

  @override
  State<InfospectInvoker> createState() => _DevOptionsBuilderState();
}

class _DevOptionsBuilderState extends State<InfospectInvoker> {
  double end = 0;
  late BorderRadiusGeometry borderRadius;
  late double width;
  Timer? timer;

  void initialValues({bool isInit = false}) {
    if (end == 0 && !isInit) return;
    end = 0;
    borderRadius = const BorderRadiusDirectional.only(
      topStart: Radius.circular(5),
      bottomStart: Radius.circular(5),
    );
    width = 5;
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
    timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        initialValues();
      });
    });
  }

  @override
  void initState() {
    initialValues(isInit: true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return widget.child;

    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      return PlatformMenuBar(
        menus: <PlatformMenuItem>[
          PlatformMenu(
            label: 'Options',
            menus: <PlatformMenuItem>[
              PlatformMenuItem(
                onSelected: () async {
                  await widget.infospect.openInspectorInNewWindow();
                },
                shortcut: const CharacterActivator('m'),
                label: 'Show Dev Options',
              ),
            ],
          ),
        ],
        child: widget.child,
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
                    timer?.cancel();
                    if (details.delta.dx < 0) {
                      changedValues();
                      startTimer();
                    } else if (details.delta.dx > 0) {
                      initialValues();
                    }
                  },
                  onTap: () {
                    timer?.cancel();
                    if (end == 0) {
                      changedValues();
                      startTimer();
                    } else {
                      initialValues();
                      widget.infospect.navigateToInterceptor();
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
