import 'dart:async';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_esp32_cam_project/src/view/home.dart';
import 'package:loading_animations/loading_animations.dart';
import 'package:ping_discover_network_forked/ping_discover_network_forked.dart';
import 'package:web_socket_channel/io.dart';
import 'package:wifi_info_flutter/wifi_info_flutter.dart';

class WifiCheck extends StatefulWidget {
  const WifiCheck({super.key});

  @override
  _WifiCheckState createState() => _WifiCheckState();
}

class _WifiCheckState extends State<WifiCheck> {
  final String targetSSID = "U+Net599C";
  String _connectionStatus = 'Unknown';
  final Connectivity _connectivity = Connectivity();
  final WifiInfo _wifiInfo = WifiInfo();
  int pingSuccessCount = 0;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  late bool isTargetSSID;
  late bool isDiscovering;

  @override
  void initState() {
    super.initState();
    isTargetSSID = false;
    isDiscovering = false;

    initConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _connectivitySubscription!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          LoadingFlipping.square(
            borderColor: Colors.cyan,
            size: 100,
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Text(
                  _connectionStatus.toUpperCase(),
                  style: const TextStyle(
                      fontWeight: FontWeight.w300, fontSize: 26.0),
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white),
                  onPressed:
                      isTargetSSID ? _connectWebSocket : initConnectivity,
                  child: Text(
                    isTargetSSID ? "Connect" : "Recheck WIFI",
                    style: const TextStyle(
                        fontWeight: FontWeight.w400, fontSize: 30),
                  ),
                ),
                const SizedBox(
                  height: 20,
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  void _connectWebSocket() {
    Future.delayed(const Duration(milliseconds: 100)).then((_) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (BuildContext context) => Home(
                    channel:
                        IOWebSocketChannel.connect('ws://192.168.4.1:8888'),
                  )));
    });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initConnectivity() async {
    ConnectivityResult? result;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      print(e.toString());
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result!);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    switch (result) {
      case ConnectivityResult.wifi:
        print("WIFI ****");
        String? wifiIP, wifiName;
        try {
          wifiIP = await _wifiInfo.getWifiIP();
        } on PlatformException catch (e) {
          print(e.toString());
          wifiIP = "Failed to get Wifi IP";
        }

        try {
          wifiName = await _wifiInfo.getWifiName();
        } on PlatformException catch (e) {
          print(e.toString());
          wifiName = "Failed to get wifi name";
        }

        if (wifiIP == null && wifiIP!.trim().isEmpty) {
          return;
        }

        setState(() {
          _connectionStatus = '$result\n'
              'Wifi IP: $wifiIP\n'
              'Wifi Name: $wifiName\n';
        });

        var ipString = wifiIP.split('.');
        var subnetString = "${ipString[0]}.${ipString[1]}.${ipString[2]}";

        print("subnetString **** $subnetString");
        pingToCAMServer(subnetString);
        break;
      case ConnectivityResult.mobile:
      case ConnectivityResult.none:
        setState(() => _connectionStatus = result.toString());
        break;
      default:
        setState(() => _connectionStatus = 'Failed to get connectivity.');
        break;
    }
  }

  pingToCAMServer(String subnet) async {
    if (isDiscovering) return;
    print("pingToCAMServer");
    isDiscovering = true;
    final stream = NetworkAnalyzer.discover2(subnet, 8888,
        timeout: const Duration(milliseconds: 2000));

    stream.listen((NetworkAddress addr) {
      print(addr.ip);
      if (addr.exists) {
        print('Found device: ${addr.ip}');
        setState(() {
          isTargetSSID = true;
        });
      }
    }).onDone(() {
      isDiscovering = false;
      isTargetSSID = true;
    });
  }
}
