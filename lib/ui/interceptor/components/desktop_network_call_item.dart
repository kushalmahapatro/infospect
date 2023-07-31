part of 'network_call_item.dart';

class _DesktopNetworkCallItem extends NetworkCallItem {
  const _DesktopNetworkCallItem(
      {required InfospectNetworkCall networkCall,
      required Function onItemClicked})
      : super._(networkCall: networkCall, onItemClicked: onItemClicked);

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
