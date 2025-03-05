import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:xtend/controller/xtend_controller.dart';
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
  late XtendExceptionType? _initializationError;
  @override
  void initState() {
    super.initState();
    _keyboardController = KeyboardController();
    _modeStream = widget.controller.modeStream.asBroadcastStream();
    unawaited(Future.wait([_addSystemTray(), _initializeModeStreamRead()]));
  }

  Future<void> _initializeModeStreamRead() async {
    await _initializeController();
    _modeStream.forEach((mode) async {
      if (_initializationError != null) {
        WindowUtil.showWindow(const Duration(seconds: 5));
        return;
      }
      if (mode == XtendMode.keyboard) {
        await WindowUtil.showKeyboard();
        return;
      }
      if (_isModeAfterKeyboard(mode)) {
        await WindowUtil.hideWindow();
      }
      await WindowUtil.showWindow();
    });
  }

  bool _isModeAfterKeyboard(XtendMode mode) {
    return mode ==
        XtendMode.values[(XtendMode.keyboard.index + 1) %
            XtendMode.values.length];
  }

  Future<void> _initializeController() async {
    _initializationError = await widget.controller.initialize(
      _keyboardController,
    );
  }

  Future<void> _addSystemTray() async {
    SystemTrayUtil.initialize(onExitMenuSelected: _quitApplication);
    await SystemTrayUtil.addTrayIcon();
  }

  Future<void> _quitApplication() async {
    await _keyboardController.dispose();
    await widget.controller.dispose();
    await SystemTrayUtil.removeTrayIcon();
    await WindowUtil.closeWindow();
    exit(0);
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
                : buildBody(snapshot.data!);
          },
        ),
      ),
    );
  }

  Widget buildBody(XtendMode mode) {
    if (_initializationError != null) {
      Widget errorWidget = buildError();
      _initializationError = null;
      return errorWidget;
    }
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

  Widget buildError() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            '❌\n${_getErrorMessage()}',
            style: const TextStyle(fontSize: 16, color: Colors.white),
            textAlign: TextAlign.center,
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),
      ],
    );
  }

  String _getErrorMessage() {
    return switch (_initializationError!) {
      XtendExceptionType.readConfig =>
        'Unable to read config\n(Default config is used)',
      XtendExceptionType.deserialize =>
        'Config format is invalid\n(Default config is used)',
    };
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
