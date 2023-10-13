import 'package:flutter/material.dart';

abstract class AppDivider {
  static Widget horizontal({double? height, Color? color}) {
    return Container(
      height: height ?? 1,
      width: double.infinity,
      color: color ?? Colors.black,
    );
  }

  static Widget vertical({double? width, Color? color}) {
    return Container(
      width: width ?? 1,
      height: double.infinity,
      color: color ?? Colors.black,
    );
  }
}
