import 'package:flutter/cupertino.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoSearchTextField(
      onChanged: (search) {},
    );
  }
}
