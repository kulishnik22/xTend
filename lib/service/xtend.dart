import 'dart:async';
import 'dart:math' as math;
import 'package:xtend/data/user_32/model/keyboard_event.dart';
import 'package:xtend/data/user_32/model/input/mouse_input.dart';
import 'package:xtend/data/user_32/model/mouse_position.dart';
import 'package:xtend/data/user_32/user_32_api.dart';
import 'package:xtend/data/xinput/gamepad_service.dart';
import 'package:xtend/data/xinput/model/gamepad.dart';
import 'package:xtend/service/keyboard_interface.dart';

class Xtend {
  Xtend({required this.gamepadService, required this.user32Api})
    : _modeStreamController = StreamController.broadcast(),
      _xtendMode = XtendMode.none;
  final GamepadService gamepadService;
  final User32Api user32Api;
  late final KeyboardInterface keyboard;

  final StreamController<XtendMode> _modeStreamController;
  Gamepad? _prevGamepad;
  int? _prevLeftThumbX;
  int? _prevLeftThumbY;
  int? _prevRightThumbX;
  int? _prevRightThumbY;
  XtendMode _xtendMode;
  StreamSubscription? _capsLockSubscription;

  Stream<XtendMode> get modeStream => _modeStreamController.stream;

  Future<void> initialize(KeyboardInterface keyboardInterface) async {
    keyboard = keyboardInterface;
    await gamepadService.start();
    keyboard.charEventStream.forEach(_handleKeyboardCharEvent);
    keyboard.keyEventStream.forEach(_handleKeyboardEvent);
    gamepadService.stateStream.forEach(_updateState);
  }

  Future<void> dispose() async {
    await gamepadService.stop();
    user32Api.dispose();
    await _modeStreamController.close();
    _capsLockSubscription?.cancel();
  }

  void _handleKeyboardCharEvent(
    ({int char, KeyboardEventType eventType}) charEvent,
  ) {
    user32Api.simulateCharacter(
      char: charEvent.char,
      isCapsLockActive: keyboard.capsLock,
      eventType: charEvent.eventType,
    );
  }

  void _handleKeyboardEvent(
    ({KeyboardEvent keyboardEvent, KeyboardEventType eventType, bool repeat})
    keyboardEvent,
  ) {
    user32Api.simulateKeyboardEvent(
      keyboardEvent: keyboardEvent.keyboardEvent,
      eventType: keyboardEvent.eventType,
      repeatOnKeyDown: keyboardEvent.repeat,
    );
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
    _capsLockSubscription = user32Api.getCapsLockStream().listen(
      _updateCapsLock,
    );
  }

  void _updateCapsLock(bool value) {
    keyboard.setCapsLock(value);
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
    MousePosition? mousePosition = user32Api.getCursorPosition();
    if (mousePosition == null) {
      return;
    }
    int xModifier = x * (math.pow(x, 2) / 60 + 1).toInt();
    int yModifier = y * (math.pow(y, 2) / 60 + 1).toInt();
    user32Api.setCursorPosition(
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
    user32Api.simulateScroll(y, x);
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
        _mapToControllerAction(prevUp, up, keyboard.up);
        _mapToControllerAction(prevDown, down, keyboard.down);
      } else if (prevY.abs() < prevX.abs()) {
        _mapToControllerAction(prevLeft, left, keyboard.left);
        _mapToControllerAction(prevRight, right, keyboard.right);
      }
    }
    //perform action
    if (y.abs() > x.abs()) {
      _mapToControllerAction(prevUp, up, keyboard.up);
      _mapToControllerAction(prevDown, down, keyboard.down);
    } else {
      _mapToControllerAction(prevLeft, left, keyboard.left);
      _mapToControllerAction(prevRight, right, keyboard.right);
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
      keyboard.clickAtCursor,
    );
    _mapToControllerAction(
      _prevGamepad?.buttons.b,
      gamepad.buttons.b,
      keyboard.backspace,
    );
    _mapToControllerAction(
      _prevGamepad?.buttons.x,
      gamepad.buttons.x,
      keyboard.enter,
    );
    _mapToControllerAction(
      _prevGamepad?.buttons.y,
      gamepad.buttons.y,
      keyboard.toggleCapsLock,
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
    void Function(KeyboardEventType eventType) action,
  ) {
    _mapControllerButtonToAction(
      prevButton,
      button,
      () => action(KeyboardEventType.down),
      () => action(KeyboardEventType.up),
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
      () => user32Api.simulateMouseEvent(mouseEventDown),
      () => user32Api.simulateMouseEvent(mouseEventUp),
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
      () => user32Api.simulateKeyboardEvent(
        keyboardEvent: keyboardEvent,
        eventType: KeyboardEventType.down,
      ),
      () => user32Api.simulateKeyboardEvent(
        keyboardEvent: keyboardEvent,
        eventType: KeyboardEventType.up,
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
