import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:xtend/controller/xtend_controller.dart';
import 'package:xtend/service/keyboard_interface.dart';
import 'package:xtend/util/system_tray_util.dart';
import 'package:xtend/util/window_util.dart';
import 'package:xtend/view/constants/xtend_icons.dart';
import 'package:xtend/view/keyboard/keyboard.dart';
import 'package:xtend/view/keyboard/keyboard_controller.dart';
import 'package:xtend/service/xtend.dart';

class XtendView extends StatefulWidget {
  const XtendView({super.key, required this.controller});

  final XtendController controller;

  @override
  State<XtendView> createState() => _XtendViewState();
}

class _XtendViewState extends State<XtendView> {
  late KeyboardController _keyboardController;
  late Stream<XtendMode> _modeStream;
  @override
  void initState() {
    super.initState();
    _keyboardController = KeyboardController();
    _modeStream = widget.controller.modeStream.asBroadcastStream();
    unawaited(Future.wait([_addSystemTray(), _initializeController()]));
  }

  Future<void> _initializeController() async {
    await widget.controller.initialize(
      VirtualKeyboardInterface(keyboardController: _keyboardController),
    );
    _modeStream.forEach((mode) async {
      if (mode == XtendMode.keyboard) {
        await WindowUtil.showKeyboard();
        return;
      }
      if (mode == XtendMode.gamepad) {
        await WindowUtil.hideWindow();
      }
      await WindowUtil.showWindow();
    });
  }

  Future<void> _addSystemTray() async {
    SystemTrayUtil.initialize(
      onExitMenuSelected: () async {
        await _keyboardController.dispose();
        await widget.controller.dispose();
        await SystemTrayUtil.removeTrayIcon();
        await WindowUtil.closeWindow();
        exit(0);
      },
    );
    await SystemTrayUtil.addTrayIcon();
  }

  @override
  Widget build(BuildContext context) {
    return Material(color: Colors.transparent, child: buildBackground());
  }

  Container buildBackground() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.black,
      ),
      child: Center(
        child: StreamBuilder<XtendMode>(
          stream: _modeStream,
          builder: (context, snapshot) {
            return snapshot.data == null
                ? Container()
                : buildMode(snapshot.data!);
          },
        ),
      ),
    );
  }

  Widget buildMode(XtendMode mode) {
    if (mode == XtendMode.keyboard) {
      return Keyboard(
        controller: _keyboardController,
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
    XtendMode.gamepad => XtendIcons.gamepad,
    XtendMode.none => XtendIcons.none,
    XtendMode.keyboard =>
      throw UnimplementedError(), // No icon, keyboard is displayed
  };
}
