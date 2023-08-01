import 'package:flutter/material.dart';
import 'package:infospect/helpers/infospect_helper.dart';

class InterceptorDesktopScreen extends StatelessWidget {
  final Infospect infospect;
  const InterceptorDesktopScreen(this.infospect, {super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(toolbarHeight: 30),
          body: const Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FirstSection(),
              // _verticalDivider(),
              // SecondSection(core: core, logger: logger),
            ],
          ),
        ),
      ),
    );
  }
}

class FirstSection extends StatelessWidget {
  const FirstSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: 2,
      child: Container(
        color: Colors.black.withOpacity(0.2),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // for (final item in DevOptionsTabItem.values)
            //   Container(
            //     width: double.maxFinite,
            //     color: Colors.greenAccent,
            //     padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            //     margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            //     child: Text(
            //       item.title.toUpperCase(),
            //       style: const TextStyle(fontSize: 10),
            //     ),
            //   )
          ],
        ),
      ),
    );
  }
}
