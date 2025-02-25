import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:xtend/data/user_32/model/keyboard_input.dart';
import 'package:xtend/keyboard/keyboard_layout.dart';

class KeyboardCursor extends Equatable {
  const KeyboardCursor(this.x, this.y);
  final int x;
  final int y;

  @override
  List<Object?> get props => [x, y];
}

class VirtualKeyEvent extends Equatable {
  const VirtualKeyEvent(this.key, this.keyEvent);
  final KeyboardKey key;
  final KeyboardKeyEvent keyEvent;

  @override
  List<Object?> get props => [key, keyEvent];
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

  void up(KeyboardKeyEvent keyEvent) {
    _handleNavigationButton(keyEvent, _up);
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

  void down(KeyboardKeyEvent keyEvent) {
    _handleNavigationButton(keyEvent, _down);
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

  void left(KeyboardKeyEvent keyEvent) {
    _handleNavigationButton(keyEvent, _left);
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

  void right(KeyboardKeyEvent keyEvent) {
    _handleNavigationButton(keyEvent, _right);
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
    KeyboardKeyEvent keyEvent,
    void Function() navigation,
  ) {
    switch (keyEvent) {
      case KeyboardKeyEvent.down:
        navigation();
        _startRepeat(navigation);
        break;
      case KeyboardKeyEvent.up:
        _stopRepeat();
        break;
    }
  }

  void clickAtCursor(KeyboardKeyEvent keyEvent) {
    KeyboardKey key = _getKeyAtCursor();
    if (key is RedirectKey) {
      redirect(key.value);
      return;
    }
    _pressKey(key, keyEvent, cursorPosition.value);
  }

  KeyboardKey<dynamic> _getKeyAtCursor() {
    return layout.value.rows[cursorPosition.value.y].keys
        .where((key) => key is! VoidKey)
        .elementAt(cursorPosition.value.x);
  }

  void capsLock(bool value) {
    capsLockState.value = value;
  }

  void toggleCapsLock(KeyboardKeyEvent keyEvent) {
    _pressKeyAndFindPosition(
      const FunctionalKey(FunctionalKeyType.capsLock),
      keyEvent,
    );
  }

  void enter(KeyboardKeyEvent keyEvent) {
    _pressKeyAndFindPosition(
      const FunctionalKey(FunctionalKeyType.enter),
      keyEvent,
    );
  }

  void backspace(KeyboardKeyEvent keyEvent) {
    _pressKeyAndFindPosition(
      const FunctionalKey(FunctionalKeyType.backspace),
      keyEvent,
    );
  }

  void _pressKeyAndFindPosition(KeyboardKey key, KeyboardKeyEvent keyEvent) {
    _pressKey(
      key,
      keyEvent,
      layout.value.findFirst((other) => other.value == key.value),
    );
  }

  void _pressKey(
    KeyboardKey key,
    KeyboardKeyEvent keyEvent, [
    KeyboardCursor? position,
  ]) {
    _onKey.add(VirtualKeyEvent(key, keyEvent));
    if (position == null) {
      return;
    }
    switch (keyEvent) {
      case KeyboardKeyEvent.down:
        pressedKeyPosition.value = position;
        break;
      case KeyboardKeyEvent.up:
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
