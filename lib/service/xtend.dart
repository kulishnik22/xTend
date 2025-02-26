import 'dart:async';
import 'dart:math' as math;
import 'package:xtend/data/user_32/model/keyboard_event.dart';
import 'package:xtend/data/user_32/model/input/mouse_input.dart';
import 'package:xtend/data/user_32/model/mouse_position.dart';
import 'package:xtend/data/user_32/user_32_api.dart';
import 'package:xtend/data/xinput/gamepad_service.dart';
import 'package:xtend/data/xinput/model/gamepad.dart';
import 'package:xtend/keyboard/keyboard_controller.dart';
import 'package:xtend/keyboard/keyboard_layout.dart';

class Xtend {
  Xtend({required this.keyboardController})
    : _gamepadService = GamepadService(),
      _user32Api = User32Api(),
      _modeStreamController = StreamController.broadcast(),
      _xtendMode = XtendMode.none;
  final GamepadService _gamepadService;
  final User32Api _user32Api;
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

  Future<void> initialize() async {
    await _gamepadService.start();
    keyboardController.onKey.forEach(_executeKey);
    _gamepadService.stateStream.forEach(_updateState);
  }

  Future<void> dispose() async {
    await _gamepadService.stop();
    _user32Api.dispose();
    await _modeStreamController.close();
    _capsLockSubscription?.cancel();
  }

  void _executeKey(VirtualKeyEvent keyEvent) {
    VirtualKeyboardKey key = keyEvent.key;
    if (key is TextKey) {
      _user32Api.simulateCharacter(
        char: key.value.codeUnitAt(0),
        isCapsLockActive: keyboardController.capsLockState.value,
        keyEvent: keyEvent.keyEvent,
      );
    }
    if (key is FunctionalKey) {
      if (key.value == FunctionalKeyType.capsLock) {
        _user32Api.simulateKeyboardEvent(
          keyboardEvent: KeyboardEvent.capital,
          keyEvent: keyEvent.keyEvent,
          repeatOnKeyDown: false,
        );
      } else if (key.value == FunctionalKeyType.backspace) {
        _user32Api.simulateKeyboardEvent(
          keyboardEvent: KeyboardEvent.back,
          keyEvent: keyEvent.keyEvent,
        );
      } else if (key.value == FunctionalKeyType.enter) {
        _user32Api.simulateKeyboardEvent(
          keyboardEvent: KeyboardEvent.enter,
          keyEvent: keyEvent.keyEvent,
        );
      }
    }
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
      _nullableMap(value, _zeroToTenRange);

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

  void _listenToCapsLock() {
    if (_capsLockSubscription != null) {
      return;
    }
    _capsLockSubscription = _user32Api.getCapsLockStream().listen(
      _updateCapsLock,
    );
  }

  void _updateCapsLock(bool value) {
    keyboardController.setCapsLock(value);
  }

  void _quitListeningToCapsLock() {
    _capsLockSubscription?.cancel();
    _capsLockSubscription = null;
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
    if (_staysAtZeroZero(_prevLeftThumbX, x, _prevLeftThumbY, y)) {
      return;
    }
    MousePosition? mousePosition = _user32Api.getCursorPosition();
    if (mousePosition == null) {
      return;
    }
    int xModifier = x * (math.pow(x, 2) / 60 + 1).toInt();
    int yModifier = y * (math.pow(y, 2) / 60 + 1).toInt();
    _user32Api.setCursorPosition(
      mousePosition.x + xModifier,
      mousePosition.y - yModifier,
    );
  }

  void _simulateScroll(Gamepad gamepad) {
    int y = _zeroToTenRange(gamepad.rightThumbY);
    int x = _zeroToTenRange(gamepad.rightThumbX);
    if (_staysAtZeroZero(_prevRightThumbX, x, _prevRightThumbY, y)) {
      return;
    }
    _user32Api.simulateScroll(y, x);
  }

  bool _staysAtZeroZero(int? prevX, int x, int? prevY, int y) {
    return prevX == x && prevY == y && (x == 0 && y == 0);
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

  void _simulateKeyboardNavigation(Gamepad gamepad) {
    const int deadZone = 2;

    //normalize values
    int x = _zeroToTenRange(gamepad.leftThumbX);
    int y = _zeroToTenRange(gamepad.leftThumbY);
    int? prevX = _prevLeftThumbX;
    int? prevY = _prevLeftThumbY;

    //implement deadZone
    x = _deadZoned(x, deadZone);
    y = _deadZoned(y, deadZone);
    prevX = _nullableDeadZoned(prevX, deadZone);
    prevY = _nullableDeadZoned(prevY, deadZone);
    if ((prevX == x && prevY == y)) {
      return;
    }

    //determine direction
    bool up = y > 0;
    bool down = y < 0;
    bool left = x < 0;
    bool right = x > 0;

    bool? prevUp = _nullableMap(prevY, (prevY) => prevY > 0);
    bool? prevDown = _nullableMap(prevY, (prevY) => prevY < 0);
    bool? prevLeft = _nullableMap(prevX, (prevX) => prevX < 0);
    bool? prevRight = _nullableMap(prevX, (prevX) => prevX > 0);

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

  int _deadZoned(int value, int deadZone) =>
      value > deadZone
          ? value - deadZone
          : value < -deadZone
          ? value + deadZone
          : 0;

  int? _nullableDeadZoned(int? value, int deadZone) =>
      _nullableMap(value, (int nonNull) => _deadZoned(nonNull, deadZone));

  T? _nullableMap<T, G>(G? value, T Function(G nonNull) transform) =>
      value == null ? null : transform(value);

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

  void _mapToControllerAction(
    bool? prevButton,
    bool button,
    void Function(KeyboardKeyEvent keyEvent) action,
  ) {
    _mapControllerButtonToAction(
      prevButton,
      button,
      () => action(KeyboardKeyEvent.down),
      () => action(KeyboardKeyEvent.up),
    );
  }

  void _mapToMouse(
    bool? prevButton,
    bool button,
    MouseEvent mouseEventDown,
    MouseEvent mouseEventUp,
  ) {
    _mapControllerButtonToAction(
      prevButton,
      button,
      () => _user32Api.simulateMouseEvent(mouseEventDown),
      () => _user32Api.simulateMouseEvent(mouseEventUp),
    );
  }

  void _mapToKeyboard(
    bool? prevButton,
    bool button,
    KeyboardEvent keyboardEvent,
  ) {
    _mapControllerButtonToAction(
      prevButton,
      button,
      () => _user32Api.simulateKeyboardEvent(
        keyboardEvent: keyboardEvent,
        keyEvent: KeyboardKeyEvent.down,
      ),
      () => _user32Api.simulateKeyboardEvent(
        keyboardEvent: keyboardEvent,
        keyEvent: KeyboardKeyEvent.up,
      ),
    );
  }

  void _mapControllerButtonToAction(
    bool? prevButton,
    bool button,
    void Function() onDown,
    void Function() onUp,
  ) {
    if (prevButton != button) {
      if (button) {
        onDown();
      } else if (prevButton != null) {
        onUp();
      }
    }
  }

  void _updateXtendMode(Gamepad? gamepad) {
    if (gamepad == null) {
      _xtendMode = XtendMode.none;
    } else if (_prevGamepad == null || _didClickChangeMode(gamepad)) {
      _xtendMode = _nextXtendMode();
    } else {
      return;
    }
    _modeStreamController.add(_xtendMode);
  }

  bool _didClickChangeMode(Gamepad gamepad) {
    return (_prevGamepad!.buttons.start != gamepad.buttons.start ||
            _prevGamepad!.buttons.back != gamepad.buttons.back) &&
        (gamepad.buttons.start && gamepad.buttons.back);
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
