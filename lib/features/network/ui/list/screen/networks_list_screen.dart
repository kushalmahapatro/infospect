import 'package:flutter/material.dart';
import 'package:infospect/features/network/ui/details/notifier/interceptor_details_notifier.dart';
import 'package:infospect/features/network/ui/details/screen/interceptor_details_screen.dart';
import 'package:infospect/features/network/ui/list/components/network_call_app_bar.dart';
import 'package:infospect/features/network/ui/list/components/network_call_item.dart';
import 'package:infospect/features/network/ui/list/notifier/networks_list_notifier.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:infospect/utils/common_widgets/live_edge_scroll_view.dart';
import 'package:infospect/utils/infospect_share.dart';
import 'package:share_plus/share_plus.dart';

class NetworksListScreen extends StatefulWidget {
  final Infospect infospect;
  final NetworksListNotifier notifier;

  const NetworksListScreen(this.infospect, {required this.notifier, super.key});

  @override
  State<NetworksListScreen> createState() => _NetworksListScreenState();
}

class _NetworksListScreenState extends State<NetworksListScreen> {
  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_onNotifierChanged);
    widget.notifier.onShareAllNetworkCalls = (sharableFile) {
      if (Infospect.instance.onShareAllNetworkCalls != null) {
        Infospect.instance.onShareAllNetworkCalls!(sharableFile.path);
      } else {
        final XFile file = XFile(sharableFile.path);
        InfospectShare.shareFiles([file], context: mounted ? context : null);
      }
    };
  }

  void _onNotifierChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_onNotifierChanged);
    super.dispose();
  }

  String get _querySignature =>
      '${widget.notifier.searchedText}|${widget.notifier.filters.map((e) => e.name).join('|')}|${widget.notifier.timeSort.name}';

  @override
  Widget build(BuildContext context) {
    final calls = widget.notifier.filteredCalls;
    final ascending = widget.notifier.isTimeSortAscending;

    return Scaffold(
      appBar: NetworkCallAppBar(
        hasBottom: widget.notifier.filters.isNotEmpty,
        infospect: widget.infospect,
        notifier: widget.notifier,
      ),
      body: calls.isEmpty
          ? const SizedBox.shrink()
          : LiveEdgeScrollableList(
              itemCount: calls.length,
              newestItemKey: calls.isEmpty
                  ? null
                  : (ascending ? calls.last.id : calls.first.id),
              newItemsLabel: 'New calls',
              edge: ascending ? LiveListEdge.bottom : LiveListEdge.top,
              querySignature: _querySignature,
              itemBuilder: (context, index) {
                return NetworkCallItem(
                  networkCall: calls[index],
                  onItemClicked: (selectedCall) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InterceptorDetailsScreen(
                          widget.infospect,
                          call: selectedCall,
                          notifier: InterceptorDetailsNotifier(),
                        ),
                      ),
                    );
                  },
                  onAddBreakpoint: (call) {
                    widget.infospect.addEndpointBreakpoint(
                      endpoint: call.endpoint,
                      method: call.method,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Breakpoint added for ${call.method} ${call.endpoint}',
                        ),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  searchedText: widget.notifier.searchedText,
                );
              },
            ),
    );
  }
}
