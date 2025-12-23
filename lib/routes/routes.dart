import 'package:flutter/material.dart';
import 'package:infospect/features/network/ui/details/notifier/interceptor_details_notifier.dart';
import 'package:infospect/features/network/ui/details/screen/interceptor_details_screen.dart';
import 'package:infospect/features/network/ui/raw_data_viewer/notifier/raw_data_viewer_notifier.dart';
import 'package:infospect/features/network/ui/raw_data_viewer/screen/raw_data_viewer_screen.dart';
import 'package:infospect/features/network/ui/list/notifier/networks_list_notifier.dart';
import 'package:infospect/features/logger/ui/logs_list/notifier/logs_list_notifier.dart';
import 'package:infospect/helpers/infospect_helper.dart';

class MobileRoutes {
  ThemeData? themeData;

  MobileRoutes();

  Widget launch(
    Infospect infospect, {
    required NetworksListNotifier networksListNotifier,
    required LogsListNotifier logsListNotifier,
    bool isMultiWindow = false,
  }) {
    return infospect.infospectLaunchScreen(
      networksListNotifier: networksListNotifier,
      logsListNotifier: logsListNotifier,
      isMultiWindow: isMultiWindow,
    );
  }

  Widget networkCallDetails(Infospect infospect) {
    final notifier = InterceptorDetailsNotifier();
    return InterceptorDetailsScreen(
      infospect,
      notifier: notifier,
    );
  }

  Widget rawDataViewer({
    required Map<String, dynamic> data,
    bool beautificationRequired = false,
  }) {
    final notifier = RawDataViewerNotifier();
    return RawDataViewerScreen(
      data: data,
      beautificationRequired: beautificationRequired,
      notifier: notifier,
    );
  }
}
