import 'dart:async';
import 'dart:isolate';

import 'package:xtend/data/xinput/model/gamepad.dart';
import 'package:xtend/data/xinput/xinput_api.dart';

class GamepadService {
  GamepadService({this.controllerId = 0});
  final int controllerId;

  Isolate? _isolate;
  ReceivePort? _stateReceivePort;
  Stream<dynamic>? _stateStream;
  SendPort? _stopSendPort;

  Stream<Gamepad?> get stateStream => _stateStream!.map(
    (state) => state == null ? null : Gamepad.fromJson(state),
  );

  Future<void> start() async {
    _stateReceivePort = ReceivePort();
    _stateStream = _stateReceivePort!.asBroadcastStream();
    _isolate = await Isolate.spawn(_entryPoint, {
      'sendPort': _stateReceivePort!.sendPort,
      'controllerId': controllerId,
    });
    _stopSendPort = await _stateStream!.first;
  }

  Future<void> _awaitCloseReady() async {
    await _stateStream?.firstWhere((value) => value == null);
  }

  static Future<void> _entryPoint(Map<String, dynamic> message) async {
    SendPort sendPort = message['sendPort'];
    int controllerId = message['controllerId'];
    ReceivePort stopReceivePort = ReceivePort();
    bool running = true;
    sendPort.send(stopReceivePort.sendPort);
    stopReceivePort.forEach((_) {
      running = false;
    });
    XinputApi xinputApi = XinputApi();
    try {
      while (running) {
        Gamepad? gamepad = xinputApi.readState(controllerId);
        sendPort.send(gamepad?.toJson());
        await Future.delayed(const Duration(milliseconds: 16));
      }
    } finally {
      xinputApi.dispose();
      stopReceivePort.close();
      sendPort.send(null);
    }
  }

  Future<void> stop() async {
    _stopSendPort?.send(null);
    await _awaitCloseReady();
    _isolate?.kill();
    _stateReceivePort?.close();
    _stopSendPort = null;
    _isolate = null;
    _stateReceivePort = null;
  }
}
