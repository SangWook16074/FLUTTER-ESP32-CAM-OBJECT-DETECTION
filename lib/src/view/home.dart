import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_esp32_cam_project/src/view/wifi_check.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class Home extends StatefulWidget {
  final WebSocketChannel channel;

  const Home({super.key, required this.channel});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final double videoWidth = 640;
  final double videoHeight = 480;

  double newVideoSizeWidth = 640;
  double newVideoSizeHeight = 480;

  late bool isLandscape;

  final _globalKey = GlobalKey();

  late ObjectDetector _detector;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    isLandscape = false;
    _detector = ObjectDetector(
        options: ObjectDetectorOptions(
            mode: DetectionMode.stream,
            classifyObjects: true,
            multipleObjects: true));
  }

  @override
  void dispose() {
    widget.channel.sink.close();
    _detector.close();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black,
        child: StreamBuilder(
          stream: widget.channel.stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              Future.delayed(const Duration(milliseconds: 100)).then((_) {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (BuildContext context) => const WifiCheck()));
              });
            }

            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              );
            } else {
              try {
                _detector
                    .processImage(InputImage.fromBytes(
                        bytes: snapshot.data,
                        metadata: InputImageMetadata(
                            size: const Size(50, 50),
                            format: InputImageFormat.nv21,
                            bytesPerRow: 1,
                            rotation: InputImageRotation
                                .rotation0deg // or other rotation value
                            )))
                    .then((result) {
                  debugPrint(result.length.toString());
                });
              } catch (e) {
                print(e.toString());
              }
              // Handle the detection result

              return Column(
                children: <Widget>[
                  SizedBox(
                    height: isLandscape ? 0 : 30,
                  ),
                  RepaintBoundary(
                    key: _globalKey,
                    child: Image.memory(
                      snapshot.data,
                      gaplessPlayback: true,
                      width: newVideoSizeWidth,
                      height: newVideoSizeHeight,
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
