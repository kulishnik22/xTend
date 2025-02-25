import 'dart:io';

import 'package:flutter/material.dart';
import 'package:xtend/keyboard/keyboard_controller.dart';
import 'package:xtend/service/xtend.dart';
import 'package:xtend/util/system_tray_util.dart';
import 'package:xtend/util/window_util.dart';
import 'package:xtend/xtend_view.dart';

void main() async {
  if (!Platform.isWindows) {
    exit(0);
  }
  WidgetsFlutterBinding.ensureInitialized();
  KeyboardController keyboardController = KeyboardController();
  Xtend xtend = Xtend(keyboardController: keyboardController);
  runApp(
    XtendApp(stream: xtend.modeStream, keyboardController: keyboardController),
  );
  await addSystemTray(xtend, keyboardController);
  await startXtend(xtend);
}

Future<void> startXtend(Xtend xtend) async {
  await xtend.initialize();
  xtend.modeStream.forEach((mode) async {
    if (mode == XtendMode.keyboard) {
      await CustomWindowUtil.showKeyboard();
      return;
    }
    if (mode == XtendMode.gamepad) {
      await CustomWindowUtil.hideWindow();
    }
    await CustomWindowUtil.showWindow();
  });
}

Future<void> addSystemTray(
  Xtend xtend,
  KeyboardController keyboardController,
) async {
  SystemTrayUtil.initialize(
    onExitMenuSelected: () async {
      await keyboardController.dispose();
      await xtend.dispose();
      await SystemTrayUtil.removeTrayIcon();
      await CustomWindowUtil.closeWindow();
      exit(0);
    },
  );
  await SystemTrayUtil.addTrayIcon();
}

class XtendApp extends StatelessWidget {
  const XtendApp({
    super.key,
    required this.stream,
    required this.keyboardController,
  });

  final Stream<XtendMode> stream;
  final KeyboardController keyboardController;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: XtendView(stream: stream, keyboardController: keyboardController),
    );
  }
}
