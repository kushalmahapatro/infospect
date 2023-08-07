import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:infospect/features/network/models/infospect_network_response.dart';

extension NetworkResponseExtension on InfospectNetworkResponse {
  String get statusString {
    int status = this.status ?? -1;
    if (status == -1) {
      return "ERR";
    } else if (status < 200) {
      return status.toString();
    } else if (status >= 200 && status < 300) {
      return "$status OK";
    } else if (status >= 300 && status < 400) {
      return status.toString();
    } else if (status >= 400 && status < 600) {
      return status.toString();
    } else {
      return "ERR";
    }
  }

  Color? getStatusTextColor(BuildContext context) {
    int status = this.status ?? -1;
    if (status == -1) {
      return Colors.red[400];
    } else if (status < 200) {
      return Theme.of(context).textTheme.bodyLarge!.color;
    } else if (status >= 200 && status < 300) {
      return Colors.green[400];
    } else if (status >= 300 && status < 400) {
      return Colors.orange[400];
    } else if (status >= 400 && status < 600) {
      return Colors.red[400];
    } else {
      return Theme.of(context).textTheme.bodyLarge!.color;
    }
  }

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
