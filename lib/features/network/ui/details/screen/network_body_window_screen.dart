import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/features/network/ui/details/widgets/json_body_viewer.dart';
import 'package:infospect/utils/extensions/infospect_network/network_request_extension.dart';
import 'package:infospect/utils/extensions/infospect_network/network_response_extension.dart';
import 'package:infospect/utils/extensions/int_extension.dart';
import 'package:infospect/utils/common_widgets/infospect_toast.dart';
import 'package:infospect/utils/infospect_util.dart';

/// Which body to show in a popped-out network body window.
enum NetworkBodyKind { request, response }

/// Desktop window that shows call metadata plus the JSON body viewer.
class NetworkBodyWindowScreen extends StatefulWidget {
  const NetworkBodyWindowScreen({
    super.key,
    required this.call,
    required this.kind,
    this.detailsInitiallyExpanded = false,
  });

  final InfospectNetworkCall call;
  final NetworkBodyKind kind;

  /// When true (e.g. opened from a network-call context menu), call details
  /// start expanded. Body popouts keep this false.
  final bool detailsInitiallyExpanded;

  @override
  State<NetworkBodyWindowScreen> createState() =>
      _NetworkBodyWindowScreenState();
}

class _NetworkBodyWindowScreenState extends State<NetworkBodyWindowScreen> {
  late bool _detailsExpanded;

  @override
  void initState() {
    super.initState();
    _detailsExpanded = widget.detailsInitiallyExpanded;
  }

  Map<String, dynamic> get _bodyJson => widget.kind == NetworkBodyKind.request
      ? widget.call.request?.bodyMap ?? {}
      : widget.call.response?.bodyMap ?? {};

  String get _bodyTitle => widget.kind == NetworkBodyKind.request
      ? 'Request Body'
      : 'Response Body';

  bool get _hasBodyJson => _bodyJson.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        theme.colorScheme.outlineVariant.withValues(alpha: 0.55);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CallSummaryBar(call: widget.call, kind: widget.kind),
          Divider(height: 1, thickness: 1, color: borderColor),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CollapsibleDetails(
                    expanded: _detailsExpanded,
                    onToggle: () =>
                        setState(() => _detailsExpanded = !_detailsExpanded),
                    child: _MetaPanel(call: widget.call, kind: widget.kind),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _hasBodyJson
                        ? JsonBodyViewer(
                            data: _bodyJson,
                            windowTitle: _bodyTitle,
                            showOpenInWindow: false,
                          )
                        : _EmptyBodyPlaceholder(title: _bodyTitle),
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

class _EmptyBodyPlaceholder extends StatelessWidget {
  const _EmptyBodyPlaceholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        theme.colorScheme.outlineVariant.withValues(alpha: 0.55);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Center(
        child: Text(
          'No $title',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

class _CollapsibleDetails extends StatelessWidget {
  const _CollapsibleDetails({
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        theme.colorScheme.outlineVariant.withValues(alpha: 0.55);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(5),
              bottom: Radius.circular(expanded ? 0 : 5),
            ),
            child: SizedBox(
              height: 30,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      size: 16,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Call details',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      expanded ? 'Collapse' : 'Expand',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: child,
              ),
            ),
            secondChild: const SizedBox(width: double.infinity),
            crossFadeState: expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 160),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

class _CallSummaryBar extends StatelessWidget {
  const _CallSummaryBar({required this.call, required this.kind});

  final InfospectNetworkCall call;
  final NetworkBodyKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = call.response?.getStatusTextColor(context);

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      child: Row(
        children: [
          _Chip(
            label: call.method,
            background: theme.colorScheme.primary.withValues(alpha: 0.25),
          ),
          const SizedBox(width: 6),
          _Chip(
            label: call.response?.statusString ?? '…',
            background: statusColor?.withValues(alpha: 0.35),
          ),
          const SizedBox(width: 6),
          _Chip(
            label: kind == NetworkBodyKind.request ? 'Request' : 'Response',
            background:
                theme.colorScheme.secondaryContainer.withValues(alpha: 0.55),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(
              call.uri,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPanel extends StatelessWidget {
  const _MetaPanel({required this.call, required this.kind});

  final InfospectNetworkCall call;
  final NetworkBodyKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final request = call.request;
    final response = call.response;
    final requestHeaders = request?.headers ?? {};
    final requestBody = request?.bodyMap ?? {};
    final responseHeaders = response?.headers == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(response!.headers!);

    final rows = <(String, String)>[
      ('Server', call.server),
      ('Endpoint', call.endpoint),
      ('Client', call.client),
      ('Duration', call.duration.toReadableTime),
      if (request != null) ...[
        ('Request time', request.time.toString()),
        ('Request size', request.size.toReadableBytes),
        if ((request.contentType ?? '').isNotEmpty)
          ('Content-Type', request.contentType!),
      ],
      if (response != null) ...[
        ('Response time', response.time.toString()),
        ('Response size', response.size.toReadableBytes),
        ('Status', response.statusString),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: rows
              .map(
                (row) => SizedBox(
                  width: 280,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 96,
                        child: Text(
                          row.$1,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.55),
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SelectableText(
                          row.$2,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
        if (requestHeaders.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionTitle(
            'Request headers',
            onCopy: () => _copyText(
              context,
              _formatHeaders(requestHeaders),
              'Request headers copied',
            ),
          ),
          const SizedBox(height: 6),
          _HeadersPreview(headers: requestHeaders),
        ],
        if (requestBody.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionTitle(
            'Request body',
            onCopy: () => _copyText(
              context,
              InfospectUtil.encoder.convert(requestBody),
              'Request body copied',
            ),
          ),
          const SizedBox(height: 6),
          _JsonPreview(data: requestBody),
        ],
        if (responseHeaders.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionTitle(
            'Response headers',
            onCopy: () => _copyText(
              context,
              _formatHeaders(responseHeaders),
              'Response headers copied',
            ),
          ),
          const SizedBox(height: 6),
          _HeadersPreview(headers: responseHeaders),
        ],
        if (kind == NetworkBodyKind.request) ...[
          Builder(
            builder: (context) {
              final responseBody = call.response?.bodyMap ?? {};
              if (responseBody.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _SectionTitle(
                    'Response body',
                    onCopy: () => _copyText(
                      context,
                      InfospectUtil.encoder.convert(responseBody),
                      'Response body copied',
                    ),
                  ),
                  const SizedBox(height: 6),
                  _JsonPreview(data: responseBody),
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  String _formatHeaders(Map<String, dynamic> headers) {
    return InfospectUtil.formatHeadersForCopy(headers);
  }

  void _copyText(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    InfospectToast.show(
      context,
      message,
      duration: const Duration(seconds: 1),
      icon: Icons.copy_rounded,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label, {this.onCopy});

  final String label;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        if (onCopy != null)
          IconButton(
            tooltip: 'Copy all',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            icon: Icon(
              Icons.copy_rounded,
              size: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            onPressed: onCopy,
          ),
      ],
    );
  }
}

class _JsonPreview extends StatelessWidget {
  const _JsonPreview({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SelectableText(
      InfospectUtil.encoder.convert(data),
      style: theme.textTheme.bodySmall?.copyWith(
        fontSize: 11,
        fontFamily: 'monospace',
        height: 1.35,
      ),
    );
  }
}

class _HeadersPreview extends StatelessWidget {
  const _HeadersPreview({required this.headers});

  final Map<String, dynamic> headers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = headers.entries.take(12).toList();
    final remaining = headers.length - entries.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: SelectableText(
              '${e.key}: ${e.value}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                fontFamily: 'monospace',
                height: 1.35,
              ),
            ),
          ),
        ),
        if (remaining > 0)
          Text(
            '+$remaining more',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.background});

  final String label;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: background ??
            Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
