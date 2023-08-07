import 'dart:convert';

import 'package:infospect/features/network/models/infospect_network_request.dart';

extension NetworkRequestExtension on InfospectNetworkRequest {
  Map<String, dynamic> get bodyMap {
    if (body is String && body.toString().isNotEmpty) {
      try {
        return jsonDecode(body) as Map<String, dynamic>;
      } catch (_) {
        return {};
      }
    } else if (body is Map) {
      return (body as Map).cast<String, dynamic>();
    }
    return {};
  }
}
