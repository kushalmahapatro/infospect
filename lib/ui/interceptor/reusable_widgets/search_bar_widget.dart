import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 36,
      child: SearchBar(
        shadowColor: MaterialStatePropertyAll(Colors.transparent),
        textStyle: MaterialStatePropertyAll(TextStyle(height: 1)),
        side:
            MaterialStatePropertyAll(BorderSide(color: Colors.black, width: 2)),
        leading: Icon(
          Icons.search,
          color: Colors.black,
        ),
        hintText: "Search",
        shape: MaterialStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ),
      ),
    );
  }
}
