import 'dart:async';
import 'dart:math' as math;
import 'package:xtend/data/user_32/model/keyboard_input.dart';
import 'package:xtend/data/user_32/model/mouse_input.dart';
import 'package:xtend/data/user_32/model/mouse_position.dart';
import 'package:xtend/data/user_32/user_32_api.dart';
import 'package:xtend/data/xinput/gamepad_service.dart';
import 'package:xtend/data/xinput/model/gamepad.dart';
import 'package:xtend/keyboard/keyboard_controller.dart';
import 'package:xtend/keyboard/keyboard_layout.dart';

class Xtend {
  Xtend({
    required this.gamepadService,
    required this.user32Api,
    required this.keyboardController,
  }) : _modeStreamController = StreamController.broadcast(),
       _xtendMode = XtendMode.none;
  final GamepadService gamepadService;
  final User32Api user32Api;
  final KeyboardController keyboardController;

  final StreamController<XtendMode> _modeStreamController;
  Gamepad? _prevGamepad;
  int? _prevLeftThumbX;
  int? _prevLeftThumbY;
  int? _prevRightThumbX;
  int? _prevRightThumbY;
  XtendMode _xtendMode;
  StreamSubscription? _capsLockSubscription;

  Stream<XtendMode> get modeStream => _modeStreamController.stream;

  Future<void> start() async {
    await gamepadService.listen();
    keyboardController.onKey.forEach(_executeKey);
    gamepadService.stateStream.forEach(_updateState);
  }

  Future<void> dispose() async {
    await gamepadService.stop();
    user32Api.dispose();
    await keyboardController.dispose();
    await _modeStreamController.close();
    _capsLockSubscription?.cancel();
  }

  void _listenToCapsLock() {
    if (_capsLockSubscription != null) {
      return;
    }
    _capsLockSubscription = user32Api.getCapsLockStream().listen(
      _updateCapsLock,
    );
  }

  void _quitListeningToCapsLock() {
    _capsLockSubscription?.cancel();
    _capsLockSubscription = null;
  }

  void _executeKey(VirtualKeyEvent keyEvent) {
    KeyboardKey key = keyEvent.key;
    if (key is TextKey) {
      user32Api.simulateCharacter(
        char: key.value.codeUnitAt(0),
        isCapsLockActive: keyboardController.capsLockState.value,
        keyEvent: keyEvent.keyEvent,
      );
    }
    if (key is FunctionalKey) {
      if (key.value == FunctionalKeyType.capsLock) {
        user32Api.simulateKeyboardEvent(
          keyboardEvent: KeyboardEvent.capital,
          keyEvent: keyEvent.keyEvent,
          repeatOnKeyDown: false,
        );
      } else if (key.value == FunctionalKeyType.backspace) {
        user32Api.simulateKeyboardEvent(
          keyboardEvent: KeyboardEvent.back,
          keyEvent: keyEvent.keyEvent,
        );
      } else if (key.value == FunctionalKeyType.enter) {
        user32Api.simulateKeyboardEvent(
          keyboardEvent: KeyboardEvent.enter,
          keyEvent: keyEvent.keyEvent,
        );
      }
    }
  }

  void _updateCapsLock(bool value) {
    keyboardController.capsLock(value);
  }

  Future<void> _updateState(Gamepad? gamepad) async {
    await _handleXtendMode(gamepad);
    if (_prevGamepad == gamepad) {
      return;
    }
    _updateXtendMode(gamepad);
    _prevGamepad = gamepad;
    _prevLeftThumbX = _zeroToTenRangeNullable(_prevGamepad?.leftThumbX);
    _prevLeftThumbY = _zeroToTenRangeNullable(_prevGamepad?.leftThumbY);
    _prevRightThumbX = _zeroToTenRangeNullable(_prevGamepad?.rightThumbX);
    _prevRightThumbY = _zeroToTenRangeNullable(_prevGamepad?.rightThumbY);
  }

  int? _zeroToTenRangeNullable(int? value) =>
      _nullableTransfrom(value, _zeroToTenRange);
  int _zeroToTenRange(int value) => value ~/ 3000;

  Future<void> _handleXtendMode(Gamepad? gamepad) async {
    if (gamepad == null) {
      return;
    }
    if (_xtendMode == XtendMode.keyboard) {
      _listenToCapsLock();
    } else {
      _quitListeningToCapsLock();
    }
    switch (_xtendMode) {
      case XtendMode.mouse:
        _handleMouseMode(gamepad);
        break;
      case XtendMode.keyboard:
        _handleKeyboardMode(gamepad);
        break;
      case XtendMode.gamepad || XtendMode.none:
        // Do nothing
        break;
    }
  }

  void _handleMouseMode(Gamepad gamepad) {
    _simulateMouse(gamepad);
    _simulateScroll(gamepad);
    _simulateMouseButtons(gamepad);
    _simulateWebNavigationButtons(gamepad);
    _simulateAltTab(gamepad);
  }

  void _simulateMouse(Gamepad gamepad) {
    int x = _zeroToTenRange(gamepad.leftThumbX);
    int y = _zeroToTenRange(gamepad.leftThumbY);
    if (_prevLeftThumbX == x && _prevLeftThumbY == y && (x == 0 && y == 0)) {
      return;
    }
    int xModifier = x * (math.pow(x, 2) / 60 + 1).toInt();
    int yModifier = y * (math.pow(y, 2) / 60 + 1).toInt();
    MousePosition? mousePosition = user32Api.getCursorPosition();
    if (mousePosition == null) {
      return;
    }
    user32Api.setCursorPosition(
      mousePosition.x + xModifier,
      mousePosition.y - yModifier,
    );
  }

  void _simulateScroll(Gamepad gamepad) {
    int y = _zeroToTenRange(gamepad.rightThumbY);
    int x = _zeroToTenRange(gamepad.rightThumbX);
    if (_prevRightThumbX == x && _prevRightThumbY == y && (x == 0 && y == 0)) {
      return;
    }
    user32Api.simulateScroll(y, x);
  }

  void _simulateMouseButtons(Gamepad gamepad) {
    _mapToMouse(
      _prevGamepad?.buttons.a,
      gamepad.buttons.a,
      MouseEvent.leftDown,
      MouseEvent.leftUp,
    );
    _mapToMouse(
      _prevGamepad?.buttons.b,
      gamepad.buttons.b,
      MouseEvent.rightDown,
      MouseEvent.rightUp,
    );
  }

  void _simulateWebNavigationButtons(Gamepad gamepad) {
    _mapToKeyboard(
      _prevGamepad?.buttons.x,
      gamepad.buttons.x,
      KeyboardEvent.browserBack,
    );
    _mapToKeyboard(
      _prevGamepad?.buttons.y,
      gamepad.buttons.y,
      KeyboardEvent.browserForward,
    );
  }

  void _handleKeyboardMode(Gamepad gamepad) {
    _simulateKeyboardNavigation(gamepad);
    _simulateKeyboardShortcuts(gamepad);
    _simulateArrowKeys(gamepad);
    _simulateAltTab(gamepad);
  }

  void _simulateAltTab(Gamepad gamepad) {
    _mapToKeyboard(
      _prevGamepad?.buttons.leftShoulder,
      gamepad.buttons.leftShoulder,
      KeyboardEvent.alt,
    );
    _mapToKeyboard(
      _prevGamepad?.buttons.rightShoulder,
      gamepad.buttons.rightShoulder,
      KeyboardEvent.tab,
    );
  }

  void _simulateKeyboardNavigation(Gamepad gamepad) {
    const int deadzone = 2;

    //normalize values
    int x = _zeroToTenRange(gamepad.leftThumbX);
    int y = _zeroToTenRange(gamepad.leftThumbY);
    int? prevX = _prevLeftThumbX;
    int? prevY = _prevLeftThumbY;

    //implement deadzone
    x = _deadzoned(x, deadzone);
    y = _deadzoned(y, deadzone);
    prevX = _nullableDeadzoned(prevX, deadzone);
    prevY = _nullableDeadzoned(prevY, deadzone);
    if ((prevX == x && prevY == y)) {
      return;
    }

    //determine direction
    bool up = y > 0;
    bool down = y < 0;
    bool left = x < 0;
    bool right = x > 0;

    bool? prevUp = _nullableTransfrom(prevY, (prevY) => prevY > 0);
    bool? prevDown = _nullableTransfrom(prevY, (prevY) => prevY < 0);
    bool? prevLeft = _nullableTransfrom(prevX, (prevX) => prevX < 0);
    bool? prevRight = _nullableTransfrom(prevX, (prevX) => prevX > 0);

    //allow detection of keyUp state
    if (prevY != null && prevX != null) {
      if (prevY.abs() > prevX.abs()) {
        _mapToControllerAction(prevUp, up, keyboardController.up);
        _mapToControllerAction(prevDown, down, keyboardController.down);
      } else if (prevY.abs() < prevX.abs()) {
        _mapToControllerAction(prevLeft, left, keyboardController.left);
        _mapToControllerAction(prevRight, right, keyboardController.right);
      }
    }
    //perform action
    if (y.abs() > x.abs()) {
      _mapToControllerAction(prevUp, up, keyboardController.up);
      _mapToControllerAction(prevDown, down, keyboardController.down);
    } else {
      _mapToControllerAction(prevLeft, left, keyboardController.left);
      _mapToControllerAction(prevRight, right, keyboardController.right);
    }
  }

  int _deadzoned(int value, int deadzone) =>
      value > deadzone
          ? value - deadzone
          : value < -deadzone
          ? value + deadzone
          : 0;

  int? _nullableDeadzoned(int? value, int deadzone) =>
      value == null ? null : _deadzoned(value, deadzone);

  T? _nullableTransfrom<T, G>(G? value, T Function(G) transform) =>
      value == null ? null : transform(value);

  void _simulateArrowKeys(Gamepad gamepad) {
    _mapToKeyboard(
      _prevGamepad?.buttons.dPadUp,
      gamepad.buttons.dPadUp,
      KeyboardEvent.up,
    );
    _mapToKeyboard(
      _prevGamepad?.buttons.dPadDown,
      gamepad.buttons.dPadDown,
      KeyboardEvent.down,
    );
    _mapToKeyboard(
      _prevGamepad?.buttons.dPadLeft,
      gamepad.buttons.dPadLeft,
      KeyboardEvent.left,
    );
    _mapToKeyboard(
      _prevGamepad?.buttons.dPadRight,
      gamepad.buttons.dPadRight,
      KeyboardEvent.right,
    );
  }

  void _simulateKeyboardShortcuts(Gamepad gamepad) {
    _mapToControllerAction(
      _prevGamepad?.buttons.a,
      gamepad.buttons.a,
      keyboardController.clickAtCursor,
    );
    _mapToControllerAction(
      _prevGamepad?.buttons.b,
      gamepad.buttons.b,
      keyboardController.backspace,
    );
    _mapToControllerAction(
      _prevGamepad?.buttons.x,
      gamepad.buttons.x,
      keyboardController.enter,
    );
    _mapToControllerAction(
      _prevGamepad?.buttons.y,
      gamepad.buttons.y,
      keyboardController.toggleCapsLock,
    );
  }

  void _updateXtendMode(Gamepad? gamepad) {
    if (gamepad == null) {
      _xtendMode = XtendMode.none;
    } else if (_prevGamepad == null ||
        _didClickTwoButtons(
          _prevGamepad?.buttons.start,
          gamepad.buttons.start,
          _prevGamepad?.buttons.back,
          gamepad.buttons.back,
        )) {
      _xtendMode = _nextXtendMode();
    } else {
      return;
    }
    _modeStreamController.add(_xtendMode);
  }

  void _mapToControllerAction(
    bool? prevButton,
    bool button,
    void Function(KeyboardKeyEvent keyEvent) action,
  ) {
    if (prevButton != button) {
      if (button) {
        action(KeyboardKeyEvent.down);
      } else if (prevButton != null) {
        action(KeyboardKeyEvent.up);
      }
    }
  }

  void _mapToMouse(
    bool? prevButton,
    bool button,
    MouseEvent mouseEventDown,
    MouseEvent mouseEventUp,
  ) {
    if (prevButton != button) {
      if (button) {
        user32Api.simulateMouseEvent(mouseEventDown);
      } else if (prevButton != null) {
        user32Api.simulateMouseEvent(mouseEventUp);
      }
    }
  }

  void _mapToKeyboard(
    bool? prevButton,
    bool button,
    KeyboardEvent keyboardEvent,
  ) {
    if (prevButton != button) {
      if (button) {
        user32Api.simulateKeyboardEvent(
          keyboardEvent: keyboardEvent,
          keyEvent: KeyboardKeyEvent.down,
        );
      } else if (prevButton != null) {
        user32Api.simulateKeyboardEvent(
          keyboardEvent: keyboardEvent,
          keyEvent: KeyboardKeyEvent.up,
        );
      }
    }
  }

  bool _didClickTwoButtons(bool? fromA, bool toA, bool? fromB, bool toB) {
    return (fromA == null || fromB == null
            ? true
            : (fromA != toA || fromB != toB)) &&
        (toA && toB);
  }

  XtendMode _nextXtendMode() {
    return switch (_xtendMode) {
      XtendMode.mouse => XtendMode.keyboard,
      XtendMode.keyboard => XtendMode.gamepad,
      XtendMode.gamepad => XtendMode.mouse,
      XtendMode.none => XtendMode.gamepad,
    };
  }
}

enum XtendMode { mouse, keyboard, gamepad, none }
