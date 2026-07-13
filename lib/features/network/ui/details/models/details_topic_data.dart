import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/features/network/ui/details/screen/network_body_window_screen.dart';

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

/// JSON request/response body with beautify, foldable tree, and open-in-window.
class TopicDetailsBodyJson extends TopicDetailsBody {
  final Map<String, dynamic> json;
  final String windowTitle;
  final InfospectNetworkCall call;
  final NetworkBodyKind kind;

  TopicDetailsBodyJson({
    required this.json,
    required this.call,
    required this.kind,
    this.windowTitle = 'Body',
  });
}
