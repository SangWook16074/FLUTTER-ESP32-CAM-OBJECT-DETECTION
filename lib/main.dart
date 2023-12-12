import 'package:flutter/material.dart';
import 'package:flutter_esp32_cam_project/src/view/wifi_check.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: WifiCheck(),
    );
  }
}
