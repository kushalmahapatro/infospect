import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/features/network/ui/details/models/details_topic_data.dart';
import 'package:infospect/features/network/ui/details/screen/network_body_window_screen.dart';
import 'package:infospect/features/network/ui/details/widgets/json_body_viewer.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:infospect/utils/extensions/infospect_network/network_response_extension.dart';
import 'package:infospect/utils/infospect_util.dart';

class DesktopDetailsScreen extends StatelessWidget {
  const DesktopDetailsScreen({
    super.key,
    required this.infospect,
    this.selectedCall,
    this.topicHelper,
    this.responseTopicHelper,
    this.selectedTopic,
    this.selectedResponseTopic,
    required this.onTopicSelected,
    required this.onResponseTopicSelected,
  });

  final InfospectNetworkCall? selectedCall;
  final Infospect infospect;
  final RequestDetailsTopicHelper? topicHelper;
  final ResponseDetailsTopicHelper? responseTopicHelper;
  final TopicData? selectedTopic;
  final TopicData? selectedResponseTopic;
  final ValueChanged<TopicData> onTopicSelected;
  final ValueChanged<TopicData> onResponseTopicSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        theme.colorScheme.outlineVariant.withValues(alpha: 0.55);

    return Column(
      children: [
        if (selectedCall != null) _CallHeaderBar(call: selectedCall!),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                if (selectedCall != null && topicHelper != null)
                  _DetailsPane(
                    title: 'Request',
                    desktopTopics: topicHelper!.desktopTopics,
                    selectedTopicData: selectedTopic,
                    onTopicSelected: onTopicSelected,
                  ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: borderColor,
                ),
                if (selectedCall != null && responseTopicHelper != null)
                  _DetailsPane(
                    title: 'Response',
                    desktopTopics: responseTopicHelper!.desktopTopics,
                    selectedTopicData: selectedResponseTopic,
                    onTopicSelected: onResponseTopicSelected,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CallHeaderBar extends StatelessWidget {
  const _CallHeaderBar({required this.call});

  final InfospectNetworkCall call;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = call.response?.getStatusTextColor(context);

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      child: Row(
        children: [
          _Pill(
            label: call.method,
            background: theme.colorScheme.primary.withValues(alpha: 0.22),
            foreground: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          _Pill(
            label: call.response?.statusString ?? '…',
            background: (statusColor ?? theme.colorScheme.outline)
                .withValues(alpha: 0.28),
            foreground: statusColor ?? theme.colorScheme.onSurface,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(
              call.uri,
              maxLines: 1,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
          IconButton(
            tooltip: 'Copy URL',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: Icon(
              Icons.copy_rounded,
              size: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
            onPressed: () => Clipboard.setData(ClipboardData(text: call.uri)),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: background,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}

class _DetailsPane extends StatelessWidget {
  const _DetailsPane({
    required this.onTopicSelected,
    required this.desktopTopics,
    required this.title,
    this.selectedTopicData,
  });

  final List<TopicData> desktopTopics;
  final TopicData? selectedTopicData;
  final ValueChanged<TopicData> onTopicSelected;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (desktopTopics.isEmpty) {
      return const Expanded(child: SizedBox.shrink());
    }

    final selected = selectedTopicData ?? desktopTopics.first;
    final theme = Theme.of(context);
    final borderColor =
        theme.colorScheme.outlineVariant.withValues(alpha: 0.55);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PaneToolbar(
            title: title,
            topics: desktopTopics,
            selected: selected,
            onTopicSelected: onTopicSelected,
          ),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor)),
                color: theme.colorScheme.surface,
              ),
              child: _TopicContent(selected: selected),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaneToolbar extends StatelessWidget {
  const _PaneToolbar({
    required this.title,
    required this.topics,
    required this.selected,
    required this.onTopicSelected,
  });

  final String title;
  final List<TopicData> topics;
  final TopicData selected;
  final ValueChanged<TopicData> onTopicSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        theme.colorScheme.outlineVariant.withValues(alpha: 0.55);

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 10),
          Container(width: 1, height: 14, color: borderColor),
          const SizedBox(width: 6),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final topic in topics)
                    _TopicTab(
                      label: topic.topic,
                      selected: selected.topic == topic.topic,
                      onTap: () => onTopicSelected(topic),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicTab extends StatelessWidget {
  const _TopicTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        theme.colorScheme.outlineVariant.withValues(alpha: 0.7);

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Tooltip(
        message: label,
        waitDuration: const Duration(milliseconds: 500),
        child: Material(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(5),
            child: Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: selected
                      ? theme.colorScheme.primary.withValues(alpha: 0.35)
                      : borderColor.withValues(alpha: selected ? 1 : 0),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.62),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopicContent extends StatelessWidget {
  const _TopicContent({required this.selected});

  final TopicData selected;

  @override
  Widget build(BuildContext context) {
    return switch (selected.body) {
      TopicDetailsBodyJson(
        json: Map<String, dynamic> json,
        windowTitle: String windowTitle,
        call: InfospectNetworkCall call,
        kind: NetworkBodyKind kind,
      ) =>
        Padding(
          padding: const EdgeInsets.all(8),
          child: JsonBodyViewer(
            data: json,
            windowTitle: windowTitle,
            call: call,
            kind: kind,
          ),
        ),
      TopicDetailsBodyMap(map: Map<String, dynamic> map) =>
        _KeyValueTable(entries: map),
      TopicDetailsBodyList(list: List<ListData> list) =>
        _PropertyList(items: list),
    };
  }
}

class _KeyValueTable extends StatelessWidget {
  const _KeyValueTable({required this.entries});

  final Map<String, dynamic> entries;

  String get _allText => InfospectUtil.formatHeadersForCopy(entries);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        theme.colorScheme.outlineVariant.withValues(alpha: 0.4);
    final keys = entries.keys.toList();

    if (keys.isEmpty) {
      return Center(
        child: Text(
          'No data',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 28,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Text(
                  '${keys.length} items',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Copy all',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 24, minHeight: 24),
                  icon: Icon(
                    Icons.copy_rounded,
                    size: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _allText));
                    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                      const SnackBar(
                        content: Text('Copied'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        Divider(height: 1, thickness: 1, color: borderColor),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 2),
            itemCount: keys.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              thickness: 1,
              color: borderColor,
            ),
            itemBuilder: (context, index) {
              final key = keys[index];
              final value = entries[key]?.toString() ?? '';
              final zebra = index.isEven
                  ? theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.18)
                  : Colors.transparent;

              return ColoredBox(
                color: zebra,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 150,
                        child: SelectableText(
                          key,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SelectableText(
                          value,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            height: 1.35,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy value',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 24, minHeight: 24),
                        icon: Icon(
                          Icons.copy_rounded,
                          size: 12,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4),
                        ),
                        onPressed: () =>
                            Clipboard.setData(ClipboardData(text: value)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PropertyList extends StatelessWidget {
  const _PropertyList({required this.items});

  final List<ListData> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        theme.colorScheme.outlineVariant.withValues(alpha: 0.4);

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      itemCount: items.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        thickness: 1,
        color: borderColor,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final zebra = index.isEven
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.18)
            : Colors.transparent;

        return ColoredBox(
          color: zebra,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    item.title.replaceAll(':', '').trim(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        item.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          height: 1.35,
                        ),
                      ),
                      if ((item.other ?? '').isNotEmpty) ...[
                        const SizedBox(height: 2),
                        SelectableText(
                          item.other!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            height: 1.35,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.78),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
