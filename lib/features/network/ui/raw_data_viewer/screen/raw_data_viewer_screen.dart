import 'package:cuberto_bottom_bar/cuberto_bottom_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_json_view/flutter_json_view.dart';
import 'package:infospect/features/network/ui/raw_data_viewer/bloc/raw_data_viewer_bloc.dart';
import 'package:infospect/features/network/ui/raw_data_viewer/models/raw_data_view.dart';
import 'package:infospect/utils/common_widgets/conditional_widget.dart';
import 'package:infospect/utils/common_widgets/highlight_text_widget.dart';
import 'package:infospect/utils/infospect_util.dart';

class RawDataViewerScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool beautificationRequired;

  const RawDataViewerScreen(
      {super.key, required this.data, this.beautificationRequired = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RawDataViewerBloc(),
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: RawDataViewerSelector<RawDataView>(
            selector: (state) => state.view,
            builder: (context, view) {
              return ConditionalWidget(
                condition: view == RawDataView.beautified,
                ifTrue: CupertinoSearchTextField(
                  onChanged: (search) {
                    context
                        .read<RawDataViewerBloc>()
                        .add(SearchValueChanged(search));
                  },
                ),
                ifFalse: const SizedBox.shrink(),
              );
            },
          ),
        ),
        bottomNavigationBar:
            beautificationRequired ? const BottomNavBarWidget() : null,
        body: RawDataViewerBuilder(
          buildWhen: (previous, current) =>
              previous.view != current.view ||
              previous.searchValue != current.searchValue,
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: ConditionalWidget(
                condition: state.view == RawDataView.beautified,
                ifTrue: ConditionalWidget(
                  condition: beautificationRequired,
                  ifTrue: HighlightText(
                    style: Theme.of(context).textTheme.bodyMedium,
                    text: InfospectUtil.encoder.convert(data),
                    highlight: state.searchValue,
                  ),
                  ifFalse: ListView(
                    children: data.entries
                        .map(
                          (e) => Wrap(
                            crossAxisAlignment: WrapCrossAlignment.start,
                            children: [
                              HighlightText(
                                text: '${e.key}:',
                                highlight: state.searchValue,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              const Padding(padding: EdgeInsets.only(left: 5)),
                              HighlightText(
                                text: e.value.toString(),
                                highlight: state.searchValue,
                              ),
                              const Padding(
                                padding: EdgeInsets.only(bottom: 18),
                              )
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
                ifFalse: JsonView.map(
                  data,
                  theme: JsonViewTheme(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    separator: const Text(':'),
                    closeIcon: Icon(
                      Icons.arrow_drop_up,
                      size: 18,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    openIcon: Icon(
                      Icons.arrow_drop_down,
                      size: 18,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class BottomNavBarWidget extends StatelessWidget {
  const BottomNavBarWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return RawDataViewerSelector<RawDataView>(
      selector: (state) => state.view,
      builder: (context, view) {
        return CubertoBottomBar(
          key: const Key("BottomBar"),
          barShadow: const [BoxShadow(blurRadius: 0)],
          selectedTab: view.index,
          inactiveIconColor: Theme.of(context).colorScheme.onSurface,
          barBackgroundColor: Theme.of(context).colorScheme.primary,
          textColor: Theme.of(context).colorScheme.primary,
          tabs: RawDataView.values
              .map(
                (e) => TabData(
                  iconData: e.icon,
                  title: e.value,
                ),
              )
              .toList(),
          onTabChangedListener: (position, headline, backgroundColor) {
            context
                .read<RawDataViewerBloc>()
                .add(RawDataViewChanged(RawDataView.values[position]));
          },
        );
      },
    );
  }
}
