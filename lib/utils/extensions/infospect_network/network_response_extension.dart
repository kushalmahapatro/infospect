import 'package:infospect/network/models/infospect_network_response.dart';

extension NetworkResponseExtension on InfospectNetworkResponse {
  String get statusString {
    if (status == -1) {
      return "ERR";
    } else if (status == 0) {
      return "???";
    } else {
      return "$status OK";
    }
  }
}
