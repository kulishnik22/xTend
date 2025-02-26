import 'package:flutter/material.dart';
import 'package:xtend/constants/xtend_icons.dart';
import 'package:xtend/keyboard/keyboard.dart';
import 'package:xtend/keyboard/keyboard_controller.dart';
import 'package:xtend/service/xtend.dart';

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
    XtendMode.gamepad => XtendIcons.gamepad,
    XtendMode.none => XtendIcons.none,
    XtendMode.keyboard =>
      throw UnimplementedError(), // No icon, keyboard is displayed
  };
}
