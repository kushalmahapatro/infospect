import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infospect/features/invoker/infospect_desktop_invoker.dart';
import 'package:infospect/features/launch/desktop/infospect_desktop_menu_bar.dart';
import 'package:infospect/features/launch/desktop/infospect_desktop_shortcuts.dart';
import 'package:infospect/features/launch/notifier/launch_notifier.dart';
import 'package:infospect/features/launch/screen/launch_desktop_screen.dart';
import 'package:infospect/features/logger/ui/logs_list/notifier/logs_list_notifier.dart';
import 'package:infospect/features/network/ui/list/notifier/networks_list_notifier.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:menu_bar/menu_bar.dart';
import 'package:multiview_desktop/multiview_desktop.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InfospectDesktopShortcuts', () {
    test('openInspectorActivators cover mac and non-mac', () {
      expect(
        InfospectDesktopShortcuts.openInspectorActivators,
        containsAll([
          InfospectDesktopShortcuts.openInspectorMac,
          InfospectDesktopShortcuts.openInspectorOther,
        ]),
      );
    });

    test('primary uses meta or control based on platform', () {
      final activator = InfospectDesktopShortcuts.networkTab;
      if (InfospectDesktopShortcuts.isApple) {
        expect(activator.meta, isTrue);
        expect(activator.control, isFalse);
      } else {
        expect(activator.meta, isFalse);
        expect(activator.control, isTrue);
      }
      expect(activator.trigger, LogicalKeyboardKey.digit1);
    });
  });

  group('InfospectDesktopInvoker merge helpers', () {
    test('mergePlatformMenus keeps host menus and appends Infospect', () {
      final host = <PlatformMenuItem>[
        const PlatformMenu(label: 'File', menus: []),
        const PlatformMenu(label: 'Edit', menus: []),
      ];
      final merged = InfospectDesktopInvoker.mergePlatformMenus(host);
      expect(merged.length, 3);
      expect((merged[0] as PlatformMenu).label, 'File');
      expect((merged[1] as PlatformMenu).label, 'Edit');
      expect((merged[2] as PlatformMenu).label, 'Infospect');
    });

    test('mergeBarButtons keeps host buttons and appends Infospect', () {
      final host = <BarButton>[
        BarButton(
          text: const Text('File'),
          submenu: SubMenu(menuItems: [
            MenuButton(text: const Text('New'), onTap: () {}),
          ]),
        ),
      ];
      final merged = InfospectDesktopInvoker.mergeBarButtons(host);
      expect(merged.length, 2);
      expect((merged[0].text as Text).data, 'File');
      expect((merged[1].text as Text).data, 'Infospect');
    });

    test('mergeTaskbarMenus keeps host items and appends Infospect', () {
      final host = <TaskbarMenuItem>[
        TaskbarMenuItem(title: 'New Window', onPressed: () {}),
      ];
      final merged = InfospectDesktopInvoker.mergeTaskbarMenus(host);
      expect(merged.length, 2);
      expect(merged[0].title, 'New Window');
      expect(merged[1].title, 'Open Infospect');
    });
  });

  group('InfospectDesktopMenuShell', () {
    late Infospect infospect;
    late NetworksListNotifier networks;
    late LogsListNotifier logs;

    setUp(() {
      Infospect.ensureInitialized(logAppLaunch: false);
      infospect = Infospect.instance;
      networks = NetworksListNotifier();
      logs = LogsListNotifier(infospectLogger: infospect.infospectLogger);
      LaunchNotifier.instance.selectTab(0);
    });

    tearDown(() {
      networks.dispose();
      logs.dispose();
    });

    Widget pumpTarget({bool forceInApp = true}) {
      return MaterialApp(
        home: Scaffold(
          body: InfospectDesktopMenuShell(
            infospect: infospect,
            networksListNotifier: networks,
            logsListNotifier: logs,
            forceInAppMenuBar: forceInApp,
            child: const SizedBox.expand(child: Text('content')),
          ),
        ),
      );
    }

    test('native menu bar is macOS-only', () {
      expect(
        infospectSupportsNativeMenuBar(),
        defaultTargetPlatform == TargetPlatform.macOS,
      );
    });

    testWidgets('in-app menu renders View / Network / Logs / Window',
        (tester) async {
      await tester.pumpWidget(pumpTarget());
      expect(find.byType(InfospectDesktopInAppMenuBar), findsOneWidget);
      expect(find.text('View'), findsOneWidget);
      expect(find.text('Network'), findsWidgets);
      expect(find.text('Logs'), findsWidgets);
      expect(find.text('Window'), findsOneWidget);
      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('in-app menu items show shortcut labels', (tester) async {
      await tester.pumpWidget(pumpTarget());
      await tester.tap(find.text('View'));
      await tester.pumpAndSettle();

      expect(
        find.text(InfospectDesktopShortcuts.networkTabLabel),
        findsOneWidget,
      );
      expect(find.text(InfospectDesktopShortcuts.logsTabLabel), findsOneWidget);
      expect(
        find.text(InfospectDesktopShortcuts.breakpointsLabel),
        findsOneWidget,
      );
    });

    testWidgets('native path uses PlatformMenuBar without in-app bar',
        (tester) async {
      await tester.pumpWidget(pumpTarget(forceInApp: false));
      if (infospectSupportsNativeMenuBar()) {
        expect(find.byType(PlatformMenuBar), findsOneWidget);
        expect(find.byType(InfospectDesktopInAppMenuBar), findsNothing);
        expect(find.text('content'), findsOneWidget);
      } else {
        expect(find.byType(InfospectDesktopInAppMenuBar), findsOneWidget);
      }
    });

    testWidgets('⌘/Ctrl+2 selects logs tab via HardwareKeyboard',
        (tester) async {
      await tester.pumpWidget(pumpTarget());
      expect(LaunchNotifier.instance.selectedTab, 0);

      await tester.sendKeyDownEvent(
        InfospectDesktopShortcuts.isApple
            ? LogicalKeyboardKey.meta
            : LogicalKeyboardKey.control,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.sendKeyUpEvent(
        InfospectDesktopShortcuts.isApple
            ? LogicalKeyboardKey.meta
            : LogicalKeyboardKey.control,
      );
      await tester.pump();

      expect(LaunchNotifier.instance.selectedTab, 1);
    });

    testWidgets('⌘/Ctrl+1 selects network tab via HardwareKeyboard',
        (tester) async {
      LaunchNotifier.instance.selectTab(1);
      await tester.pumpWidget(pumpTarget());

      await tester.sendKeyDownEvent(
        InfospectDesktopShortcuts.isApple
            ? LogicalKeyboardKey.meta
            : LogicalKeyboardKey.control,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.sendKeyUpEvent(
        InfospectDesktopShortcuts.isApple
            ? LogicalKeyboardKey.meta
            : LogicalKeyboardKey.control,
      );
      await tester.pump();

      expect(LaunchNotifier.instance.selectedTab, 0);
    });

    testWidgets('LaunchDesktopScreen includes menu shell', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LaunchDesktopScreen(
            infospect,
            networksListNotifier: networks,
            logsListNotifier: logs,
          ),
        ),
      );
      expect(find.byType(InfospectDesktopMenuShell), findsOneWidget);
    });
  });

  group('native menu definitions', () {
    late Infospect infospect;
    late NetworksListNotifier networks;
    late LogsListNotifier logs;

    setUp(() {
      Infospect.ensureInitialized(logAppLaunch: false);
      infospect = Infospect.instance;
      networks = NetworksListNotifier();
      logs = LogsListNotifier(infospectLogger: infospect.infospectLogger);
    });

    tearDown(() {
      networks.dispose();
      logs.dispose();
    });

    testWidgets('buildNativeMenus exposes labeled shortcuts', (tester) async {
      late InfospectDesktopMenuActions actions;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              actions = InfospectDesktopMenuActions(
                context: context,
                infospect: infospect,
                networks: networks,
                logs: logs,
              );
              return const SizedBox();
            },
          ),
        ),
      );

      final menus = actions.buildNativeMenus();
      expect(menus.length, 4);

      PlatformMenuItem? findItem(String label) {
        PlatformMenuItem? walk(PlatformMenuItem item) {
          if (item.label == label) return item;
          if (item is PlatformMenu) {
            for (final child in item.menus) {
              final found = walk(child);
              if (found != null) return found;
            }
          }
          if (item is PlatformMenuItemGroup) {
            for (final child in item.members) {
              final found = walk(child);
              if (found != null) return found;
            }
          }
          return null;
        }

        for (final top in menus) {
          final found = walk(top);
          if (found != null) return found;
        }
        return null;
      }

      final network = findItem('Network');
      expect(network, isNotNull);
      expect(network!.shortcut, isA<SingleActivator>());
      expect((network.shortcut! as SingleActivator).trigger,
          LogicalKeyboardKey.digit1);

      final breakpoints = findItem('Breakpoints…');
      expect(breakpoints, isNotNull);
      expect((breakpoints!.shortcut! as SingleActivator).trigger,
          LogicalKeyboardKey.keyB);

      final clear = findItem('Clear Network Calls');
      expect(clear, isNotNull);
      expect((clear!.shortcut! as SingleActivator).trigger,
          LogicalKeyboardKey.keyK);
      expect((clear.shortcut! as SingleActivator).shift, isTrue);
    });
  });
}
