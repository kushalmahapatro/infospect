import 'package:flutter/material.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/features/network/ui/details/models/request_body_details_topic_helper.dart';
import 'package:infospect/features/network/ui/details/widgets/details_row_widget.dart';
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

  @override
  Widget build(BuildContext context) {
    final RequestBodyDetailsTopicHelper topicHelper =
        RequestBodyDetailsTopicHelper(call);

    return ListView(
      shrinkWrap: true,
      children: topicHelper.topics.map((e) {
        return switch (e.body) {
          /// expansion widget with map
          NetworkRequestDetailsBodyMap(
            map: Map<String, dynamic> map,
            trailing: TrailingData? trailing
          ) =>
            _getExpansionMap(e, map, trailing),

          /// expansion widget with list
          NetworkRequestDetailsBodyList(list: List<ListData> list) =>
            _getExpansionList(e, list)
        };
      }).toList(),
    );
  }

  ExpansionWidget _getExpansionList(TopicData e, List<ListData> list) {
    return ExpansionWidget(
      title: e.topic,
      children: list
          .map(
            (e) => DetailsRowWidget(
              e.title,
              e.subtitle,
              other: e.other,
            ),
          )
          .toList(),
    );
  }

  ExpansionWidget _getExpansionMap(
      TopicData e, Map<String, dynamic> map, TrailingData? trailing) {
    return ExpansionWidget.map(
      title: e.topic,
      map: map,
      trailing: trailing != null
          ? TrailingWidget(
              text: trailing.trailing,
              infospect: infospect,
              data: trailing.data,
            )
          : null,
    );
  }
}
