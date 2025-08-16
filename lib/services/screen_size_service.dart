import 'package:flutter/material.dart';

class ScreenSizeService {
  static final ScreenSizeService _instance = ScreenSizeService._internal();

  factory ScreenSizeService() => _instance;

  ScreenSizeService._internal();

  late double width;
  late double height;

  void init(BuildContext context) {
    final size = MediaQuery.of(context).size;
    width = size.width;
    height = size.height;
  }

  bool get isMobile => width < 800;
}
