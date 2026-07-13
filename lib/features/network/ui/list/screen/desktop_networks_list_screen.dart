import 'package:flutter/material.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/features/network/ui/list/components/network_call_app_bar.dart';
import 'package:infospect/features/network/ui/list/desktop_components/draggable_table.dart';
import 'package:infospect/features/network/ui/list/notifier/networks_list_notifier.dart';
import 'package:infospect/features/network/ui/details/screen/desktop_details_screen.dart';
import 'package:infospect/features/network/ui/details/models/details_topic_data.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:infospect/utils/infospect_share.dart';
import 'package:share_plus/share_plus.dart';

class DesktopNetworksListScreen extends StatefulWidget {
  final Infospect infospect;
  final NetworksListNotifier notifier;

  const DesktopNetworksListScreen(
    this.infospect, {
    required this.notifier,
    super.key,
  });

  @override
  State<DesktopNetworksListScreen> createState() =>
      _DesktopNetworksListScreenState();
}

class _DesktopNetworksListScreenState extends State<DesktopNetworksListScreen> {
  InfospectNetworkCall? _selectedCall;
  TopicData? _selectedTopic;
  TopicData? _selectedResponseTopic;
  RequestDetailsTopicHelper? _topicHelper;
  ResponseDetailsTopicHelper? _responseTopicHelper;

  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_onNotifierChanged);
    widget.notifier.onShareAllNetworkCalls = (sharableFile) {
      if (Infospect.instance.onShareAllNetworkCalls != null) {
        Infospect.instance.onShareAllNetworkCalls!(sharableFile.path);
      } else {
        final XFile file = XFile(sharableFile.path);
        InfospectShare.shareFiles([file], context: mounted ? context : null);
      }
    };
  }

  void _onNotifierChanged() {
    setState(() {});
  }

  void _onCallSelected(InfospectNetworkCall call) {
    setState(() {
      _selectedCall = call;
      _topicHelper = RequestDetailsTopicHelper(call);
      _responseTopicHelper = ResponseDetailsTopicHelper(call);
      _selectedTopic = _topicHelper!.desktopTopics.first;
      _selectedResponseTopic = _responseTopicHelper!.desktopTopics.first;
    });
  }

  @override
  void didUpdateWidget(covariant DesktopNetworksListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notifier != widget.notifier) {
      oldWidget.notifier.removeListener(_onNotifierChanged);
      widget.notifier.addListener(_onNotifierChanged);
    }
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_onNotifierChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outlineVariant.withValues(
      alpha: 0.55,
    );

    return Scaffold(
      appBar: NetworkCallAppBar.desktop(
        hasBottom: widget.notifier.filters.isNotEmpty,
        infospect: widget.infospect,
        notifier: widget.notifier,
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return DraggableTable(
                  infospect: widget.infospect,
                  selectedCall: _selectedCall,
                  onCallSelected: _onCallSelected,
                  constraints: constraints,
                  notifier: widget.notifier,
                );
              },
            ),
          ),
          if (_selectedCall != null) ...[
            Divider(height: 1, thickness: 1, color: borderColor),
            Expanded(
              child: DesktopDetailsScreen(
                infospect: widget.infospect,
                selectedCall: _selectedCall,
                topicHelper: _topicHelper,
                responseTopicHelper: _responseTopicHelper,
                selectedTopic: _selectedTopic,
                selectedResponseTopic: _selectedResponseTopic,
                onTopicSelected: (topic) {
                  setState(() {
                    _selectedTopic = topic;
                  });
                },
                onResponseTopicSelected: (topic) {
                  setState(() {
                    _selectedResponseTopic = topic;
                  });
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
