import 'package:cuberto_bottom_bar/cuberto_bottom_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:infospect/utils/common_widgets/highlight_text_widget.dart';
import 'package:infospect/utils/infospect_util.dart';

class RawDataViewer extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool beautificationRequired;
  const RawDataViewer(
      {super.key, required this.data, this.beautificationRequired = false});

  @override
  Widget build(BuildContext context) {
    ValueNotifier<String> searched = ValueNotifier('');
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: CupertinoSearchTextField(
          onChanged: (search) {
            searched.value = search;
          },
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      bottomNavigationBar:
          beautificationRequired ? const BottomNavBarWidget() : null,
      body: ValueListenableBuilder<String>(
        valueListenable: searched,
        builder: (context, search, child) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: beautificationRequired
                ? HighlightText(
                    text: InfospectUtil.encoder.convert(data),
                    highlight: search,
                  )
                : ListView(
                    children: data.entries
                        .map(
                          (e) => Wrap(
                            crossAxisAlignment: WrapCrossAlignment.start,
                            children: [
                              HighlightText(
                                text: '${e.key}:',
                                highlight: search,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              const Padding(padding: EdgeInsets.only(left: 5)),
                              HighlightText(
                                text: e.value.toString(),
                                highlight: search,
                              ),
                              const Padding(
                                padding: EdgeInsets.only(bottom: 18),
                              )
                            ],
                          ),
                        )
                        .toList(),
                  ),
          );
        },
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
    return CubertoBottomBar(
      key: const Key("BottomBar"),
      barShadow: const [BoxShadow(blurRadius: 0)],
      selectedTab: 0,
      inactiveIconColor: Colors.black,
      tabs: [
        TabData(iconData: Icons.code, title: "Beautified"),
        TabData(iconData: Icons.list, title: "Tree View"),
      ],
      onTabChangedListener: (position, headline6, backgroundColor) async {},
    );
  }
}
