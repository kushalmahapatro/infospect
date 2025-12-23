import 'package:flutter/material.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/features/network/ui/details/notifier/interceptor_details_notifier.dart';
import 'package:infospect/features/network/ui/details/components/interceptor_details_error.dart';
import 'package:infospect/features/network/ui/details/components/interceptor_details_request.dart';
import 'package:infospect/features/network/ui/details/components/interceptor_details_response.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:infospect/utils/common_widgets/app_bottom_bar.dart';
import 'package:infospect/utils/extensions/infospect_network/network_call_extension.dart';
import 'package:share_plus/share_plus.dart';

class InterceptorDetailsScreen extends StatefulWidget {
  final Infospect infospect;
  final InfospectNetworkCall? call;
  final InterceptorDetailsNotifier notifier;

  const InterceptorDetailsScreen(
    this.infospect, {
    this.call,
    required this.notifier,
    super.key,
  });

  @override
  State<InterceptorDetailsScreen> createState() =>
      _InterceptorDetailsScreenState();
}

class _InterceptorDetailsScreenState extends State<InterceptorDetailsScreen> {
  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_onNotifierChanged);
  }

  void _onNotifierChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_onNotifierChanged);
    widget.notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.call == null) {
      return const Scaffold(
        body: Center(child: Text('No call selected')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          widget.call!.server,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: IndexedStack(
        index: widget.notifier.selectedTab,
        children: [
          InterceptorDetailsRequest(widget.call!, infospect: widget.infospect),
          InterceptorDetailsResponse(widget.call!, infospect: widget.infospect),
          InterceptorDetailsError(widget.call!, infospect: widget.infospect),
        ],
      ),
      bottomNavigationBar: BottomNavBarWidget(widget.call!, widget.notifier),
    );
  }
}

class BottomNavBarWidget extends StatelessWidget {
  final InfospectNetworkCall call;
  final InterceptorDetailsNotifier notifier;

  const BottomNavBarWidget(
    this.call,
    this.notifier, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (icon: Icons.arrow_upward, title: "Request"),
      (icon: Icons.arrow_downward, title: "Response"),
      (icon: Icons.warning, title: "Error"),
      (icon: Icons.share, title: "Share")
    ];
    if (call.error == null) {
      tabs.removeAt(2);
    }
    return AppBottomBar(
      selectedIndex: notifier.selectedTab,
      tabs: tabs,
      tabChangedCallback: (position) async {
        if (position == tabs.length - 1) {
          SharePlus.instance.share(
            ShareParams(
              text: await call.sharableData,
              subject: 'Request Details',
            ),
          );
        } else {
          notifier.changeTab(position);
        }
      },
    );
  }
}
