import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/features/network/ui/details/models/details_topic_data.dart';
import 'package:infospect/features/network/ui/details/screen/network_body_window_screen.dart';
import 'package:infospect/features/network/ui/details/widgets/details_row_widget.dart';
import 'package:infospect/features/network/ui/details/widgets/json_body_viewer.dart';
import 'package:infospect/features/network/ui/list/components/expansion_widget.dart';
import 'package:infospect/features/network/ui/list/components/trailing_widget.dart';
import 'package:infospect/helpers/infospect_helper.dart';

class InterceptorDetailsRequest extends StatelessWidget {
  final InfospectNetworkCall call;
  final Infospect infospect;

  const InterceptorDetailsRequest(
    this.call, {
    super.key,
    required this.infospect,
  });

  bool _expandedByDefault(String topic) {
    return topic == 'Headers' ||
        topic == 'Query' ||
        topic == 'Body' ||
        topic == 'Form Data Fields' ||
        topic == 'Form Data Files';
  }

  @override
  Widget build(BuildContext context) {
    final topicHelper = RequestDetailsTopicHelper(call);
    final bodyHeight = (MediaQuery.sizeOf(context).height * 0.34).clamp(
      180.0,
      300.0,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
      children: topicHelper.topics.map((e) {
        final expanded = _expandedByDefault(e.topic);
        return switch (e.body) {
          TopicDetailsBodyJson(
            json: Map<String, dynamic> json,
            windowTitle: String windowTitle,
            call: InfospectNetworkCall networkCall,
            kind: NetworkBodyKind kind,
          ) =>
            ExpansionWidget(
              title: e.topic,
              initiallyExpanded: expanded,
              children: [
                SizedBox(
                  height: bodyHeight,
                  child: JsonBodyViewer(
                    data: json,
                    windowTitle: windowTitle,
                    call: networkCall,
                    kind: kind,
                  ),
                ),
              ],
            ),
          TopicDetailsBodyMap(
            map: Map<String, dynamic> map,
            trailing: TrailingData? trailing,
          ) =>
            _mapSection(e, map, trailing, expanded),
          TopicDetailsBodyList(list: List<ListData> list) =>
            _listSection(e, list, expanded),
        };
      }).toList(),
    );
  }

  ExpansionWidget _listSection(
    TopicData e,
    List<ListData> list,
    bool expanded,
  ) {
    return ExpansionWidget(
      title: e.topic,
      initiallyExpanded: expanded,
      children: list
          .mapIndexed(
            (index, item) => DetailsRowWidget(
              item.title,
              item.subtitle,
              other: item.other,
              showDivider: index != list.length - 1,
            ),
          )
          .toList(),
    );
  }

  ExpansionWidget _mapSection(
    TopicData e,
    Map<String, dynamic> map,
    TrailingData? trailing,
    bool expanded,
  ) {
    return ExpansionWidget.map(
      title: e.topic,
      map: map,
      initiallyExpanded: expanded,
      trailing: trailing != null
          ? TrailingWidget(
              text: trailing.trailing,
              infospect: infospect,
              data: trailing.data,
              beautificationRequired: trailing.beautificationRequired,
            )
          : null,
    );
  }
}
