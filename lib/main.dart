import 'dart:io';

import 'package:flutter/material.dart';
import 'package:xtend/constants/xtend_icons.dart';
import 'package:xtend/data/user_32/user_32_api.dart';
import 'package:xtend/data/xinput/gamepad_service.dart';
import 'package:xtend/keyboard/keyboard.dart';
import 'package:xtend/keyboard/keyboard_controller.dart';
import 'package:xtend/service/xtend.dart';
import 'package:xtend/util/system_tray_util.dart';
import 'package:xtend/util/window_util.dart';

void main() async {
  if (!Platform.isWindows) {
    exit(0);
  }
  WidgetsFlutterBinding.ensureInitialized();
  KeyboardController keyboardController = KeyboardController();
  Xtend xtend = Xtend(
    user32Api: User32Api(),
    gamepadService: GamepadService(),
    keyboardController: keyboardController,
  );
  runApp(
    XtendApp(stream: xtend.modeStream, keyboardController: keyboardController),
  );
  await addSystemTray(xtend);
  await startXtend(xtend);
}

Future<void> startXtend(Xtend xtend) async {
  await xtend.start();
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

Future<void> addSystemTray(Xtend xtend) async {
  SystemTrayUtil.initialize(
    onExitMenuSelected: () async {
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

class XtendView extends StatefulWidget {
  const XtendView({
    super.key,
    required this.stream,
    required this.keyboardController,
  });

  final Stream<XtendMode> stream;
  final KeyboardController keyboardController;

  @override
  State<XtendView> createState() => _XtendViewState();
}

class _XtendViewState extends State<XtendView> {
  @override
  void dispose() {
    widget.keyboardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.black,
        ),
        child: Center(
          child: StreamBuilder<XtendMode>(
            stream: widget.stream,
            builder: (context, snapshot) {
              return snapshot.data == null
                  ? Container()
                  : buildMode(snapshot.data!);
            },
          ),
        ),
      ),
    );
  }

  Widget buildMode(XtendMode mode) {
    if (mode == XtendMode.keyboard) {
      return Keyboard(
        controller: widget.keyboardController,
        configuration: KeyboardConfiguration(
          keyColor: Colors.grey.shade900,
          specialKeyColor: const Color(0xFF622ABC),
          foregroundColor: Colors.white,
          onKeySelected: Colors.grey.shade800,
          onKeyDown: Colors.grey.shade700,
          foregroundSize: 30,
        ),
      );
    }
    return mode.icon();
  }
}

extension XtendModeExtension on XtendMode {
  IconGetter get icon => switch (this) {
        XtendMode.mouse => XtendIcons.mouse,
        XtendMode.keyboard =>
          throw UnimplementedError(), // No icon, keyboard is displayed
        XtendMode.gamepad => XtendIcons.gamepad,
        XtendMode.none => XtendIcons.none,
      };
}
