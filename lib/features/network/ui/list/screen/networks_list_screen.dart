import 'package:flutter/material.dart';
import 'package:infospect/features/network/ui/list/components/network_call_app_bar.dart';
import 'package:infospect/features/network/ui/list/components/network_call_item.dart';
import 'package:infospect/features/network/ui/list/notifier/networks_list_notifier.dart';
import 'package:infospect/features/network/ui/details/screen/interceptor_details_screen.dart';
import 'package:infospect/features/network/ui/details/notifier/interceptor_details_notifier.dart';
import 'package:infospect/helpers/infospect_helper.dart';

class NetworksListScreen extends StatefulWidget {
  final Infospect infospect;
  final NetworksListNotifier notifier;

  const NetworksListScreen(
    this.infospect, {
    required this.notifier,
    super.key,
  });

  @override
  State<NetworksListScreen> createState() => _NetworksListScreenState();
}

class _NetworksListScreenState extends State<NetworksListScreen> {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NetworkCallAppBar(
        hasBottom: widget.notifier.filters.isNotEmpty,
        infospect: widget.infospect,
        notifier: widget.notifier,
      ),
      body: ListView.builder(
        itemCount: widget.notifier.filteredCalls.length,
        itemBuilder: (context, index) {
          return NetworkCallItem(
            networkCall: widget.notifier.filteredCalls[index],
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
            searchedText: widget.notifier.searchedText,
          );
        },
      ),
    );
  }
}
