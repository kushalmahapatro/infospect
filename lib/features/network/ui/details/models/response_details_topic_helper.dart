import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/features/network/ui/details/models/details_topic_data.dart';
import 'package:infospect/utils/extensions/infospect_network/network_response_extension.dart';
import 'package:infospect/utils/extensions/int_extension.dart';

class ResponseDetailsTopicHelper {
  ResponseDetailsTopicHelper(this.call) {
    initTopics();
  }

  final InfospectNetworkCall call;

  late TopicData _summaryTopics;
  TopicData? _headerTopics;
  TopicData? _bodyTopics;
  TopicData? _errorTopics;

  void initTopics() {
    _setupSummaryTopics();

    if (call.response?.headers?.isNotEmpty ?? false) {
      _setupHeaderTopics();
    }

    if (call.response?.body != null &&
        (call.response?.bodyMap ?? {}).isNotEmpty) {
      _setupBodyTopics();
    }

    if (call.error != null) {
      _setupErrorTopics();
    }
  }

  List<TopicData> get topics {
    final List<TopicData> list = [];
    if (call.response != null) list.add(_summaryTopics);
    if (_headerTopics != null) list.add(_headerTopics!);
    if (_bodyTopics != null) list.add(_bodyTopics!);

    return list;
  }

  List<TopicData> get desktopTopics {
    final List<TopicData> list = [];
    if (_headerTopics != null) list.add(_headerTopics!);
    if (_bodyTopics != null) list.add(_bodyTopics!);
    if (_errorTopics != null) list.add(_errorTopics!);
    if (call.response != null) list.add(_summaryTopics);

    return list;
  }

  /// general topic data setup
  void _setupSummaryTopics() {
    _summaryTopics = (
      topic: 'Summary',
      body: TopicDetailsBodyList(
        [
          (
            title: 'Received at:',
            subtitle: call.response!.time.toString(),
            other: null,
          ),
          (
            title: 'Bytes received:',
            subtitle: call.response!.size.toReadableBytes,
            other: null,
          ),
          (
            title: 'Status: ',
            subtitle: call.response!.statusString,
            other: null,
          ),
        ],
      )
    );
  }

  /// header topic data setup
  void _setupHeaderTopics() {
    _headerTopics = (
      topic: 'Headers',
      body: TopicDetailsBodyMap(
        map: call.response?.headers ?? {},
        trailing: (
          trailing: 'View raw',
          data: call.response?.headers ?? {},
          beautificationRequired: false,
        ),
      ),
    );
  }

  /// body topic data setup
  void _setupBodyTopics() {
    _bodyTopics = (
      topic: 'Body',
      body: TopicDetailsBodyMap(
        map: {'': call.response?.body?.toString() ?? ''},
        trailing: (
          trailing: 'View Body',
          data: call.response?.bodyMap ?? {},
          beautificationRequired: true,
        ),
      ),
    );
  }

  /// error topic data setup
  void _setupErrorTopics() {
    if ((call.error?.error.toString() ?? '').isEmpty) return;

    _errorTopics = (
      topic: 'Error',
      body: TopicDetailsBodyList(
        [
          (
            title: 'Message:',
            subtitle: call.error?.error.toString() ?? '',
            other: null,
          ),
          if (call.error?.stackTrace != null)
            (
              title: 'Stacktrace:',
              subtitle: call.error?.stackTrace.toString() ?? '',
              other: null,
            )
        ],
      ),
    );
  }
}
