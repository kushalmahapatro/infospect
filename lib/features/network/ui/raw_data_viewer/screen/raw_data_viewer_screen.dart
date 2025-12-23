import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_json_view/flutter_json_view.dart';
import 'package:infospect/features/network/ui/raw_data_viewer/notifier/raw_data_viewer_notifier.dart';
import 'package:infospect/features/network/ui/raw_data_viewer/models/raw_data_view.dart';
import 'package:infospect/infospect.dart';
import 'package:infospect/utils/infospect_util.dart';

class RawDataViewerScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool beautificationRequired;
  final RawDataViewerNotifier notifier;

  const RawDataViewerScreen({
    super.key,
    required this.data,
    this.beautificationRequired = false,
    required this.notifier,
  });

  @override
  State<RawDataViewerScreen> createState() => _RawDataViewerScreenState();
}

class _RawDataViewerScreenState extends State<RawDataViewerScreen> {
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
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: ConditionalWidget(
          condition: widget.notifier.view == RawDataView.beautified,
          ifTrue: CupertinoSearchTextField(
            padding: const EdgeInsetsDirectional.fromSTEB(5.5, 8, 5.5, 8),
            style: Theme.of(context).textTheme.labelLarge,
            itemSize: 20,
            prefixInsets: const EdgeInsetsDirectional.fromSTEB(6, 0, 0, 3),
            onChanged: (search) {
              widget.notifier.changeSearchValue(search);
            },
          ),
          ifFalse: const SizedBox.shrink(),
        ),
      ),
      bottomNavigationBar: widget.beautificationRequired
          ? BottomNavBarWidget(widget.notifier)
          : null,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ConditionalWidget(
          condition: widget.notifier.view == RawDataView.beautified,
          ifTrue: ConditionalWidget(
            condition: widget.beautificationRequired,
            ifTrue: HighlightText(
              style: Theme.of(context).textTheme.bodyMedium,
              text: InfospectUtil.encoder.convert(widget.data),
              highlight: widget.notifier.searchValue,
            ),
            ifFalse: ListView(
              children: widget.data.entries
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.key,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            e.value.toString(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          ifFalse: JsonView.map(
            widget.data,
            theme: JsonViewTheme(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
              keyStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              stringStyle: Theme.of(context).textTheme.bodyMedium!,
              boolStyle: Theme.of(context).textTheme.bodyMedium!,
              separator: const Text(':'),
            ),
          ),
        ),
      ),
    );
  }
}

class BottomNavBarWidget extends StatelessWidget {
  final RawDataViewerNotifier notifier;

  const BottomNavBarWidget(this.notifier, {super.key});

  @override
  Widget build(BuildContext context) {
    return AppBottomBar(
      selectedIndex: notifier.view == RawDataView.beautified ? 0 : 1,
      tabs: [
        (
          icon: RawDataView.beautified.icon,
          title: RawDataView.beautified.value
        ),
        (icon: RawDataView.treeView.icon, title: RawDataView.treeView.value),
      ],
      tabChangedCallback: (index) {
        notifier.changeView(
          index == 0 ? RawDataView.beautified : RawDataView.treeView,
        );
      },
    );
  }
}
