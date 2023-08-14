import 'package:flutter/material.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/features/network/ui/details/components/interceptor_details_response.dart';
import 'package:infospect/features/network/ui/details/models/request_body_details_topic_helper.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:infospect/utils/common_widgets/conditional_widget.dart';
import 'package:infospect/utils/common_widgets/divider.dart';
import 'package:infospect/utils/extensions/infospect_network/network_response_extension.dart';

class DesktopDetailsScreen extends StatelessWidget {
  const DesktopDetailsScreen({
    super.key,
    required this.infospect,
    this.selectedCall,
    this.topicHelper,
    this.selectedTopic,
    required this.onTopicSelected,
  });

  final InfospectNetworkCall? selectedCall;
  final Infospect infospect;
  final RequestBodyDetailsTopicHelper? topicHelper;
  final TopicData? selectedTopic;
  final ValueChanged<TopicData> onTopicSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 4),

        /// Selected network call data
        if (selectedCall != null) ...[
          Row(
            children: [
              const SizedBox(width: 8),

              /// Method
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 2.0),
                  child: Text(
                    selectedCall?.method ?? '',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              /// Status
              Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: selectedCall?.response?.getStatusTextColor(context)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 2.0),
                  child: Text(
                    selectedCall?.response?.statusString ?? '',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              /// URL
              Flexible(
                child: SelectableText(
                  selectedCall?.uri ?? '',
                  style: const TextStyle(fontSize: 12),
                ),
              )
            ],
          ),
        ],
        const SizedBox(height: 4),
        AppDivider.horizontal(),
        Flexible(
          child: Row(
            children: [
              if (selectedCall != null && topicHelper != null)
                _RequestWidget(
                  selectedCall: selectedCall!,
                  infospect: infospect,
                  topicHelper: topicHelper!,
                  selectedTopicData: selectedTopic,
                  onTopicSelected: (topic) => onTopicSelected(topic),
                ),
              AppDivider.vertical(),
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 4),
                    const Text(
                      'Response',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AppDivider.horizontal(),
                    if (selectedCall != null)
                      Expanded(
                        child: InterceptorDetailsResponse(
                          selectedCall!,
                          infospect: infospect,
                        ),
                      )
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RequestWidget extends StatelessWidget {
  const _RequestWidget(
      {required this.infospect,
      required this.onTopicSelected,
      required this.selectedCall,
      required this.topicHelper,
      this.selectedTopicData});

  final InfospectNetworkCall selectedCall;
  final Infospect infospect;
  final RequestBodyDetailsTopicHelper topicHelper;
  final TopicData? selectedTopicData;
  final ValueChanged<TopicData> onTopicSelected;

  @override
  Widget build(BuildContext context) {
    TopicData selected = selectedTopicData ?? topicHelper.desktopTopics.first;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text(
                    'Request',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ...[const SizedBox(width: 10), ..._topics(context, selected)]
                ],
              ),
            ),
          ),
          AppDivider.horizontal(),
          Expanded(child: _topicBody(selected)),
        ],
      ),
    );
  }

  ListView _topicBody(TopicData selected) {
    return switch (selected.body) {
      NetworkRequestDetailsBodyMap(
        map: Map<String, dynamic> map,
      ) =>
        ListView(
          children: map.entries
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.start,
                    children: [
                      SelectableText(
                        '${e.key}:',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Padding(padding: EdgeInsets.only(left: 2)),
                      SelectableText(
                        e.value.toString(),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),

      /// expansion widget with list
      NetworkRequestDetailsBodyList(list: List<ListData> list) => ListView(
          children: list
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ConditionalWidget(
                    condition: e.other == null,
                    ifTrue: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.start,
                      children: [
                        SelectableText(
                          e.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SelectableText(e.subtitle),
                      ],
                    ),
                    ifFalse: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          e.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsetsDirectional.only(start: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SelectableText(e.subtitle),
                              SelectableText(e.other ?? ''),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
    };
  }

  List<Widget> _topics(BuildContext context, TopicData selected) {
    List<Widget> list = [];
    for (final e in topicHelper.desktopTopics) {
      list.add(
        InkWell(
          onTap: () => onTopicSelected.call(e),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              e.topic,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary.withOpacity(
                      selected.topic == e.topic ? 1 : 0.4,
                    ),
              ),
            ),
          ),
        ),
      );
    }
    return list;
  }
}
