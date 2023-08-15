export 'request_details_topic_helper.dart';
export 'response_details_topic_helper.dart';

typedef TopicData = ({String topic, TopicDetailsBody body});

typedef TrailingData = ({
  String trailing,
  Map<String, dynamic> data,
  bool beautificationRequired
});

typedef ListData = ({String title, String subtitle, String? other});

sealed class TopicDetailsBody {}

class TopicDetailsBodyMap extends TopicDetailsBody {
  final Map<String, dynamic> map;
  final TrailingData? trailing;

  TopicDetailsBodyMap({required this.map, this.trailing});
}

class TopicDetailsBodyList extends TopicDetailsBody {
  final List<ListData> list;

  TopicDetailsBodyList(this.list);
}
