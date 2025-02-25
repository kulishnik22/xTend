import 'package:flutter/material.dart';
import 'package:xtend/keyboard/keyboard_controller.dart';
import 'package:xtend/keyboard/keyboard_layout.dart';

class KeyboardConfiguration {
  const KeyboardConfiguration({
    required this.keyColor,
    required this.specialKeyColor,
    required this.foregroundColor,
    required this.foregroundSize,
    required this.onKeySelected,
    required this.onKeyDown,
    this.keyRadius = const BorderRadius.all(Radius.circular(10)),
  });
  final Color keyColor;
  final Color specialKeyColor;
  final Color foregroundColor;
  final double foregroundSize;
  final Color onKeySelected;
  final Color onKeyDown;
  final BorderRadius keyRadius;
}

class Keyboard extends StatefulWidget {
  const Keyboard({
    super.key,
    required this.configuration,
    required this.controller,
  });

  final KeyboardConfiguration configuration;
  final KeyboardController controller;

  @override
  State<Keyboard> createState() => _KeyboardState();
}

class _KeyboardState extends State<Keyboard> {
  late Size keySize;
  late double padding;

  late KeyboardLayout layout;
  late KeyboardCursor cursorPosition;
  late bool capsLockState;
  KeyboardCursor? pressedKeyPosition;

  @override
  void initState() {
    super.initState();
    layout = widget.controller.layout.value;
    cursorPosition = widget.controller.cursorPosition.value;
    capsLockState = widget.controller.capsLockState.value;
    widget.controller.layout.addListener(_onLayoutChanged);
    widget.controller.cursorPosition.addListener(_onCursorPositionChanged);
    widget.controller.capsLockState.addListener(_onCapsLockChanged);
    widget.controller.pressedKeyPosition.addListener(_onPressedKeyChanged);
  }

  void _onLayoutChanged() {
    setState(() {
      layout = widget.controller.layout.value;
    });
  }

  void _onCursorPositionChanged() {
    setState(() {
      cursorPosition = widget.controller.cursorPosition.value;
    });
  }

  void _onCapsLockChanged() {
    setState(() {
      capsLockState = widget.controller.capsLockState.value;
    });
  }

  void _onPressedKeyChanged() {
    setState(() {
      pressedKeyPosition = widget.controller.pressedKeyPosition.value;
    });
  }

  @override
  void dispose() {
    widget.controller.layout.removeListener(_onLayoutChanged);
    widget.controller.cursorPosition.removeListener(_onCursorPositionChanged);
    widget.controller.capsLockState.removeListener(_onCapsLockChanged);
    widget.controller.pressedKeyPosition.removeListener(_onPressedKeyChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        padding = constraints.maxHeight / 100;
        keySize = computeKeySize(constraints);
        return Padding(
          padding: EdgeInsets.all(padding),
          child: SizedBox(
            width: constraints.maxWidth - (padding * 2),
            height: constraints.maxHeight - (padding * 2),
            child: buildKeyboard(keySize),
          ),
        );
      },
    );
  }

  Size computeKeySize(BoxConstraints constraints) {
    int columns = layout.columnsCount;
    int rows = layout.rowsCount;
    double horizontalPaddingOffset = (padding * 2) / columns;
    double verticalPaddingOffset = (padding * 2) / rows;
    return Size(
      constraints.maxWidth / columns - horizontalPaddingOffset,
      constraints.maxHeight / rows - verticalPaddingOffset,
    );
  }

  Widget buildKeyboard(Size keySize) {
    List<KeyRow> rows = layout.rows;
    return Column(
      children: [for (int x = 0; x < rows.length; x++) buildRow(rows[x], x)],
    );
  }

  Widget buildRow(KeyRow row, int rowIndex) {
    int keyIndex = 0;
    List<Widget> children = [];
    for (KeyboardKey key in row.keys) {
      if (key is VoidKey) {
        children.add(buildKey(key));
        continue;
      }
      children.add(buildKey(key, KeyboardCursor(keyIndex, rowIndex)));
      keyIndex++;
    }
    return Row(children: children);
  }

  Widget buildKey(KeyboardKey key, [KeyboardCursor? keyPosition]) {
    return SizedBox(
      width: keySize.width * key.width,
      height: keySize.height,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: buildKeyCap(key, keyPosition),
      ),
    );
  }

  Widget buildKeyCap(KeyboardKey key, KeyboardCursor? keyPosition) {
    switch (key) {
      case VoidKey():
        return buildVoidKeyCap();
      case TextKey():
        return buildTextKeyCap(key, keyPosition!);
      case RedirectKey():
        return buildRedirectKeyCap(keyPosition!);
      case FunctionalKey():
        return buildFunctionalKeyCap(key, keyPosition!);
    }
  }

  Widget buildVoidKeyCap() {
    return const SizedBox();
  }

  Widget buildTextKeyCap(TextKey key, KeyboardCursor keyPosition) {
    return buildKeyCapButton(
      keyPosition: keyPosition,
      child: Text(
        capsLockState ? key.capsLockVariant : key.value,
        style: TextStyle(
          fontSize: widget.configuration.foregroundSize,
          color: widget.configuration.foregroundColor,
        ),
      ),
    );
  }

  Widget buildRedirectKeyCap(KeyboardCursor keyPosition) {
    return buildKeyCapButton(
      special: true,
      keyPosition: keyPosition,
      child: buildKeyIcon(Icons.more_horiz),
    );
  }

  Widget buildFunctionalKeyCap(FunctionalKey key, KeyboardCursor keyPosition) {
    return buildKeyCapButton(
      special: true,
      keyPosition: keyPosition,
      child: buildKeyIcon(getFunctionalKeyIcon(key.value)),
    );
  }

  IconData getFunctionalKeyIcon(FunctionalKeyType keyType) => switch (keyType) {
    FunctionalKeyType.backspace => Icons.backspace_outlined,
    FunctionalKeyType.enter => Icons.keyboard_return_outlined,
    FunctionalKeyType.capsLock => Icons.keyboard_capslock_outlined,
  };

  Icon buildKeyIcon(IconData icon) => Icon(
    icon,
    color: widget.configuration.foregroundColor,
    size: widget.configuration.foregroundSize,
  );

  Widget buildKeyCapButton({
    bool special = false,
    required KeyboardCursor keyPosition,
    required Widget child,
  }) {
    bool selected = keyPosition == cursorPosition;
    bool pressed =
        pressedKeyPosition != null && keyPosition == pressedKeyPosition;
    return Material(
      color:
          pressed
              ? widget.configuration.onKeyDown
              : selected
              ? widget.configuration.onKeySelected
              : special
              ? widget.configuration.specialKeyColor
              : widget.configuration.keyColor,
      borderRadius: widget.configuration.keyRadius,
      child: Center(child: child),
    );
  }
}
