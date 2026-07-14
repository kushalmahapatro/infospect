import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/features/network/ui/details/notifier/interceptor_details_notifier.dart';
import 'package:infospect/features/network/ui/details/components/interceptor_details_error.dart';
import 'package:infospect/features/network/ui/details/components/interceptor_details_request.dart';
import 'package:infospect/features/network/ui/details/components/interceptor_details_response.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:infospect/utils/extensions/infospect_network/network_call_extension.dart';
import 'package:infospect/utils/extensions/infospect_network/network_response_extension.dart';
import 'package:infospect/utils/extensions/int_extension.dart';
import 'package:infospect/utils/common_widgets/infospect_mobile_chrome.dart';
import 'package:infospect/utils/infospect_share.dart';

class InterceptorDetailsScreen extends StatefulWidget {
  final Infospect infospect;
  final InfospectNetworkCall? call;
  final InterceptorDetailsNotifier notifier;

  const InterceptorDetailsScreen(
    this.infospect, {
    this.call,
    required this.notifier,
    super.key,
  });

  @override
  State<InterceptorDetailsScreen> createState() =>
      _InterceptorDetailsScreenState();
}

class _InterceptorDetailsScreenState extends State<InterceptorDetailsScreen> {
  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_onNotifierChanged);
  }

  void _onNotifierChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_onNotifierChanged);
    widget.notifier.dispose();
    super.dispose();
  }

  Future<void> _shareCall() async {
    final call = widget.call;
    if (call == null) return;
    final data = await call.sharableData;
    if (!mounted) return;
    InfospectShare.shareText(
      data,
      subject: 'Request Details',
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.call == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: const InfospectMobileToolbar(
          title: Text('Network call'),
        ),
        body: Center(
          child: Text(
            'No call selected',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.45),
                ),
          ),
        ),
      );
    }

    final call = widget.call!;
    final theme = Theme.of(context);
    final borderColor =
        theme.colorScheme.outlineVariant.withValues(alpha: 0.55);
    final tabs = _detailTabs(call);
    final selectedTab = widget.notifier.selectedTab.clamp(0, tabs.length - 1);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: InfospectMobileToolbar(
        title: Text(
          call.endpoint.isNotEmpty ? call.endpoint : 'Network call',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontFamily: 'monospace',
            fontSize: InfospectMobileChrome.titleFontSize,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Share',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints:
                BoxConstraints.tight(InfospectMobileChrome.backTapTarget),
            icon: const Icon(Icons.share_rounded, size: 18),
            onPressed: _shareCall,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CallHeaderBar(call: call),
          _DetailsTabBar(
            tabs: tabs,
            selectedIndex: selectedTab,
            onChanged: widget.notifier.changeTab,
          ),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: IndexedStack(
                index: selectedTab,
                children: [
                  InterceptorDetailsRequest(
                    call,
                    infospect: widget.infospect,
                  ),
                  InterceptorDetailsResponse(
                    call,
                    infospect: widget.infospect,
                  ),
                  if (call.error != null)
                    InterceptorDetailsError(
                      call,
                      infospect: widget.infospect,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_DetailTab> _detailTabs(InfospectNetworkCall call) {
    return [
      const _DetailTab(label: 'Request', icon: Icons.arrow_upward_rounded),
      const _DetailTab(label: 'Response', icon: Icons.arrow_downward_rounded),
      if (call.error != null)
        const _DetailTab(label: 'Error', icon: Icons.warning_amber_rounded),
    ];
  }
}

class _DetailTab {
  const _DetailTab({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _CallHeaderBar extends StatelessWidget {
  const _CallHeaderBar({required this.call});

  final InfospectNetworkCall call;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final statusColor = call.loading
        ? theme.colorScheme.primary
        : (call.response?.getStatusTextColor(context) ??
            theme.colorScheme.outline);
    final duration = call.loading ? '…' : call.duration.toReadableTime;
    final up = (call.request?.size ?? 0).toReadableBytes;
    final down = (call.response?.size ?? 0).toReadableBytes;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Pill(
                label: call.method.toUpperCase(),
                background: theme.colorScheme.primary.withValues(alpha: 0.22),
                foreground: theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),
              _Pill(
                label: call.loading
                    ? '…'
                    : (call.response?.statusString ?? 'ERR'),
                background: statusColor.withValues(alpha: 0.22),
                foreground: statusColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$duration · $up↑ $down↓',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    height: 1.1,
                    color: muted,
                  ),
                ),
              ),
              InkWell(
                onTap: () => Clipboard.setData(ClipboardData(text: call.uri)),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.copy_rounded, size: 14, color: muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SelectableText(
            call.uri,
            maxLines: 1,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              fontFamily: 'monospace',
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsTabBar extends StatelessWidget {
  const _DetailsTabBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<_DetailTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        theme.colorScheme.outlineVariant.withValues(alpha: 0.55);

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(
              child: _TabChip(
                tab: tabs[i],
                selected: selectedIndex == i,
                onTap: () => onChanged(i),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _DetailTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: selected
          ? theme.colorScheme.primary.withValues(alpha: 0.14)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          height: 24,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                tab.icon,
                size: 12,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
              const SizedBox(width: 3),
              Text(
                tab.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  height: 1.1,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.62),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: background,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          height: 1.15,
          color: foreground,
        ),
      ),
    );
  }
}
