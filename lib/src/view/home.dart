import 'dart:async';
import 'dart:typed_data';

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
  late bool isBusy;
  late bool detected;

  late ObjectDetector _detector;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    detected = false;
    isLandscape = false;
    isBusy = false;
    _detector = ObjectDetector(
        options: ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: false,
      multipleObjects: true,
    ));
  }

  @override
  void dispose() {
    widget.channel.sink.close();
    _detector.close();
    _timer.cancel();
    super.dispose();
  }

  void detect(Uint8List bytes) {
    if (isBusy) return;
    isBusy = true;
    _detector
        .processImage(InputImage.fromBytes(
            bytes: bytes,
            metadata: InputImageMetadata(
                size: Size(videoWidth, videoHeight),
                rotation: InputImageRotation.rotation0deg,
                format: InputImageFormat.bgra8888,
                bytesPerRow: 7000)))
        .then((results) {
      setState(() {
        if (results.isNotEmpty) {
          detected = true;
          debugPrint("누구야 !!");
        } else {
          detected = false;
          debugPrint("");
        }
        isBusy = false;
      });
    });
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
              detect(snapshot.data);
              return Column(
                children: <Widget>[
                  SizedBox(
                    height: isLandscape ? 0 : 30,
                  ),
                  Stack(
                    children: [
                      Positioned(
                        bottom: 1,
                        right: 1,
                        child: Text(
                          (detected) ? "사람등장 !!" : "",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 40),
                        ),
                      ),
                      Image.memory(
                        snapshot.data,
                        gaplessPlayback: true,
                        width: newVideoSizeWidth,
                        height: newVideoSizeHeight,
                      ),
                    ],
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
