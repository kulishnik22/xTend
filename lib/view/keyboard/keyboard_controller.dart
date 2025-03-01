import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:xtend/data/user_32/model/keyboard_event.dart';
import 'package:xtend/view/keyboard/keyboard_layout.dart';

class KeyboardCursor extends Equatable {
  const KeyboardCursor(this.x, this.y);
  final int x;
  final int y;

  @override
  List<Object?> get props => [x, y];
}

class VirtualKeyEvent extends Equatable {
  const VirtualKeyEvent(this.key, this.eventType);
  final VirtualKeyboardKey key;
  final KeyboardEventType eventType;

  @override
  List<Object?> get props => [key, eventType];
}

class KeyboardController {
  KeyboardController()
    : layout = ValueNotifier(_initialLayout),
      cursorPosition = ValueNotifier(_initialLayout.initialCursor),
      capsLockState = ValueNotifier(false),
      pressedKeyPosition = ValueNotifier(null),
      _onKey = StreamController<VirtualKeyEvent>() {
    maxLengthBounds = _computeMaxLengthBounds(layout.value);
  }
  static final KeyboardLayout _initialLayout =
      KeyboardLayout.alphabeticNumeric();

  final ValueNotifier<KeyboardLayout> layout;
  final ValueNotifier<KeyboardCursor> cursorPosition;
  final ValueNotifier<bool> capsLockState;
  final ValueNotifier<KeyboardCursor?> pressedKeyPosition;
  final StreamController<VirtualKeyEvent> _onKey;

  late List<int> maxLengthBounds;

  Timer? _delayTimer;
  Timer? _repeatTimer;

  void _startRepeat(void Function() callback) {
    _stopRepeat();
    _delayTimer = Timer(const Duration(milliseconds: 500), () {
      _repeatTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        callback();
      });
    });
  }

  void _stopRepeat() {
    _delayTimer?.cancel();
    _repeatTimer?.cancel();
    _delayTimer = null;
    _repeatTimer = null;
  }

  List<int> _computeMaxLengthBounds(KeyboardLayout keyboardLayout) {
    return keyboardLayout.rows
        .map((row) => row.keys.where((key) => key is! VoidKey).length)
        .toList();
  }

  Stream<VirtualKeyEvent> get onKey => _onKey.stream;

  void up(KeyboardEventType eventType) {
    _handleNavigationButton(eventType, _up);
  }

  void _up() {
    int x = cursorPosition.value.x;
    int y = cursorPosition.value.y;
    if (y == 0) {
      y = maxLengthBounds.length - 1;
    } else {
      y--;
    }
    if (maxLengthBounds[y] <= x) {
      x = maxLengthBounds[y] - 1;
    }
    cursorPosition.value = KeyboardCursor(x, y);
  }

  void down(KeyboardEventType eventType) {
    _handleNavigationButton(eventType, _down);
  }

  void _down() {
    int x = cursorPosition.value.x;
    int y = cursorPosition.value.y;
    if (y == maxLengthBounds.length - 1) {
      y = 0;
    } else {
      y++;
    }
    if (maxLengthBounds[y] <= x) {
      x = maxLengthBounds[y] - 1;
    }
    cursorPosition.value = KeyboardCursor(x, y);
  }

  void left(KeyboardEventType eventType) {
    _handleNavigationButton(eventType, _left);
  }

  void _left() {
    int x = cursorPosition.value.x;
    int y = cursorPosition.value.y;
    if (x == 0) {
      x = maxLengthBounds[y] - 1;
    } else {
      x--;
    }
    cursorPosition.value = KeyboardCursor(x, y);
  }

  void right(KeyboardEventType eventType) {
    _handleNavigationButton(eventType, _right);
  }

  void _right() {
    int x = cursorPosition.value.x;
    int y = cursorPosition.value.y;
    if (x == maxLengthBounds[y] - 1) {
      x = 0;
    } else {
      x++;
    }
    cursorPosition.value = KeyboardCursor(x, y);
  }

  void _handleNavigationButton(
    KeyboardEventType eventType,
    void Function() navigation,
  ) {
    switch (eventType) {
      case KeyboardEventType.down:
        navigation();
        _startRepeat(navigation);
        break;
      case KeyboardEventType.up:
        _stopRepeat();
        break;
    }
  }

  void clickAtCursor(KeyboardEventType eventType) {
    VirtualKeyboardKey key = _getKeyAtCursor();
    if (key is RedirectKey) {
      redirect(key.value);
      return;
    }
    _pressKey(key, eventType, cursorPosition.value);
  }

  VirtualKeyboardKey<dynamic> _getKeyAtCursor() {
    return layout.value.rows[cursorPosition.value.y].keys
        .where((key) => key is! VoidKey)
        .elementAt(cursorPosition.value.x);
  }

  void setCapsLock(bool value) {
    capsLockState.value = value;
  }

  void toggleCapsLock(KeyboardEventType eventType) {
    _pressKeyAndFindPosition(
      const FunctionalKey(FunctionalKeyType.capsLock),
      eventType,
    );
  }

  void enter(KeyboardEventType eventType) {
    _pressKeyAndFindPosition(
      const FunctionalKey(FunctionalKeyType.enter),
      eventType,
    );
  }

  void backspace(KeyboardEventType eventType) {
    _pressKeyAndFindPosition(
      const FunctionalKey(FunctionalKeyType.backspace),
      eventType,
    );
  }

  void _pressKeyAndFindPosition(
    VirtualKeyboardKey key,
    KeyboardEventType eventType,
  ) {
    _pressKey(
      key,
      eventType,
      layout.value.findFirst((other) => other.value == key.value),
    );
  }

  void _pressKey(
    VirtualKeyboardKey key,
    KeyboardEventType eventType, [
    KeyboardCursor? position,
  ]) {
    _onKey.add(VirtualKeyEvent(key, eventType));
    if (position == null) {
      return;
    }
    switch (eventType) {
      case KeyboardEventType.down:
        pressedKeyPosition.value = position;
        break;
      case KeyboardEventType.up:
        pressedKeyPosition.value = null;
        break;
    }
  }

  void redirect(KeyboardLayoutType type) {
    KeyboardLayout newLayout = KeyboardLayout.fromType(type);
    layout.value = newLayout;
    cursorPosition.value = newLayout.initialCursor;
    maxLengthBounds = _computeMaxLengthBounds(layout.value);
  }

  Future<void> dispose() async {
    await _onKey.close();
    layout.dispose();
    cursorPosition.dispose();
    capsLockState.dispose();
    pressedKeyPosition.dispose();
    _stopRepeat();
  }
}
