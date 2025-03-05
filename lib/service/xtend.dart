import 'dart:async';
import 'dart:math' as math;
import 'package:xtend/data/config/config_service.dart';
import 'package:xtend/data/config/model/config.dart';
import 'package:xtend/data/user_32/model/keyboard_event.dart';
import 'package:xtend/data/user_32/model/input/mouse_input.dart';
import 'package:xtend/data/user_32/model/mouse_position.dart';
import 'package:xtend/data/user_32/user_32_api.dart';
import 'package:xtend/data/xinput/gamepad_service.dart';
import 'package:xtend/data/xinput/model/gamepad.dart';
import 'package:xtend/service/keyboard_interface.dart';

enum XtendExceptionType { readConfig, deserialize }

class Xtend {
  Xtend({
    required this.gamepadService,
    required this.user32Api,
    required this.configService,
  }) : _modeStreamController = StreamController.broadcast(),
       _xtendMode = XtendMode.none,
       _config = const Config.standard();
  final GamepadService gamepadService;
  final User32Api user32Api;
  final ConfigService configService;
  late final KeyboardInterface keyboard;
  Config _config;

  final StreamController<XtendMode> _modeStreamController;
  Gamepad? _prevGamepad;
  int? _prevLeftThumbX;
  int? _prevLeftThumbY;
  int? _prevRightThumbX;
  int? _prevRightThumbY;
  XtendMode _xtendMode;
  StreamSubscription? _capsLockSubscription;

  Stream<XtendMode> get modeStream => _modeStreamController.stream;

  Future<XtendExceptionType?> initialize(
    KeyboardInterface keyboardInterface,
  ) async {
    keyboard = keyboardInterface;
    await gamepadService.start();
    keyboard.charEventStream.forEach(_handleKeyboardCharEvent);
    keyboard.keyEventStream.forEach(_handleKeyboardEvent);
    gamepadService.stateStream.forEach(_updateState);
    return _tryLoadConfig();
  }

  XtendExceptionType? _tryLoadConfig() {
    try {
      _config = configService.readConfig();
      return null;
    } on DeserializationException {
      return XtendExceptionType.deserialize;
    } on Object {
      return XtendExceptionType.readConfig;
    }
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
    keyboard.capsLock = value;
  }

  void _quitListeningToCapsLock() {
    _capsLockSubscription?.cancel();
    _capsLockSubscription = null;
  }

  void _handleGamepadMapping(Gamepad gamepad, GamepadMapping mapping) {
    _getButtonAction(mapping.a)(_prevGamepad?.buttons.a, gamepad.buttons.a);
    _getButtonAction(mapping.b)(_prevGamepad?.buttons.b, gamepad.buttons.b);
    _getButtonAction(mapping.x)(_prevGamepad?.buttons.x, gamepad.buttons.x);
    _getButtonAction(mapping.y)(_prevGamepad?.buttons.y, gamepad.buttons.y);
    _getButtonAction(mapping.dPadUp)(
      _prevGamepad?.buttons.dPadUp,
      gamepad.buttons.dPadUp,
    );
    _getButtonAction(mapping.dPadDown)(
      _prevGamepad?.buttons.dPadDown,
      gamepad.buttons.dPadDown,
    );
    _getButtonAction(mapping.dPadLeft)(
      _prevGamepad?.buttons.dPadLeft,
      gamepad.buttons.dPadLeft,
    );
    _getButtonAction(mapping.dPadRight)(
      _prevGamepad?.buttons.dPadRight,
      gamepad.buttons.dPadRight,
    );
    _getButtonAction(mapping.leftThumb)(
      _prevGamepad?.buttons.leftThumb,
      gamepad.buttons.leftThumb,
    );
    _getButtonAction(mapping.rightThumb)(
      _prevGamepad?.buttons.rightThumb,
      gamepad.buttons.rightThumb,
    );
    _getButtonAction(mapping.leftShoulder)(
      _prevGamepad?.buttons.leftShoulder,
      gamepad.buttons.leftShoulder,
    );
    _getButtonAction(mapping.rightShoulder)(
      _prevGamepad?.buttons.rightShoulder,
      gamepad.buttons.rightShoulder,
    );
    _mapTriggerAsButton(_getButtonAction(mapping.leftTrigger))(
      _prevGamepad?.leftTrigger,
      gamepad.leftTrigger,
    );
    _mapTriggerAsButton(_getButtonAction(mapping.rightTrigger))(
      _prevGamepad?.rightTrigger,
      gamepad.rightTrigger,
    );
    _getJoystickAction(mapping.leftJoystick)(
      _prevLeftThumbX,
      _prevLeftThumbY,
      gamepad.leftThumbX,
      gamepad.leftThumbY,
    );
    _getJoystickAction(mapping.rightJoystick)(
      _prevRightThumbX,
      _prevRightThumbY,
      gamepad.rightThumbX,
      gamepad.rightThumbY,
    );
  }

  void Function(int? prev, int trigger) _mapTriggerAsButton(
    void Function(bool?, bool) action,
  ) {
    return (prev, trigger) {
      bool? prevPressed = prev == null ? null : prev > 0;
      bool pressed = trigger > 0;
      action(prevPressed, pressed);
    };
  }

  void Function(bool? prev, bool button) _getButtonAction(ButtonAction action) {
    if (_xtendMode != XtendMode.keyboard &&
        action == ButtonAction.clickAtKeyboardCursor) {
      return (prev, button) {};
    }
    if (_xtendMode != XtendMode.mouse &&
        (action == ButtonAction.mouseLeftClick ||
            action == ButtonAction.mouseRightClick)) {
      return (prev, button) {};
    }
    return switch (action) {
      ButtonAction.mouseLeftClick => _simulateMouseLeftClick,
      ButtonAction.mouseRightClick => _simulateMouseRightClick,
      ButtonAction.browserBack => _simulateBrowserBack,
      ButtonAction.browserForward => _simulateBrowserForward,
      ButtonAction.alt => _simulateAlt,
      ButtonAction.tab => _simulateTab,
      ButtonAction.arrowUp => _simulateArrowUp,
      ButtonAction.arrowDown => _simulateArrowDown,
      ButtonAction.arrowLeft => _simulateArrowLeft,
      ButtonAction.arrowRight => _simulateArrowRight,
      ButtonAction.backspace => _simulateBackspace,
      ButtonAction.enter => _simulateEnter,
      ButtonAction.capsLock => _simulateCapsLock,
      ButtonAction.clickAtKeyboardCursor => _simulateClickAtCursor,
      ButtonAction.volumeUp => _simulateVolumeUp,
      ButtonAction.volumeDown => _simulateVolumeDown,
      ButtonAction.shift => _simulateShift,
      ButtonAction.win => _simulateWin,
      ButtonAction.ctrl => _simulateCtrl,
      ButtonAction.ctrlC => _simulateCtrlC,
      ButtonAction.ctrlV => _simulateCtrlV,
      ButtonAction.ctrlX => _simulateCtrlX,
      ButtonAction.ctrlW => _simulateCtrlW,
      ButtonAction.ctrlA => _simulateCtrlA,
      ButtonAction.ctrlS => _simulateCtrlS,
      ButtonAction.none => (prev, button) {},
    };
  }

  void Function(int? prevThumbX, int? prevThumbY, int thumbX, int thumbY)
  _getJoystickAction(JoystickAction action) {
    if (_xtendMode != XtendMode.keyboard &&
        action == JoystickAction.keyboardNavigation) {
      return (prevThumbX, prevThumbY, thumbX, thumbY) {};
    }
    return switch (action) {
      JoystickAction.keyboardNavigation => _simulateKeyboardNavigation,
      JoystickAction.mouse => _simulateMouse,
      JoystickAction.scroll => _simulateScroll,
      JoystickAction.none => (prevThumbX, prevThumbY, thumbX, thumbY) {},
    };
  }

  void _handleMouseMode(Gamepad gamepad) {
    _handleGamepadMapping(gamepad, _config.mouse);
  }

  void _handleKeyboardMode(Gamepad gamepad) {
    _handleGamepadMapping(gamepad, _config.keyboard);
  }

  void _simulateMouse(
    int? prevThumbX,
    int? prevThumbY,
    int thumbX,
    int thumbY,
  ) {
    int x = _zeroToTenRange(thumbX);
    int y = _zeroToTenRange(thumbY);
    if (_staysAtZeroZero(prevThumbX, x, prevThumbY, y)) {
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

  void _simulateScroll(
    int? prevThumbX,
    int? prevThumbY,
    int thumbX,
    int thumbY,
  ) {
    int y = _zeroToTenRange(thumbY);
    int x = _zeroToTenRange(thumbX);
    if (_staysAtZeroZero(prevThumbX, x, prevThumbY, y)) {
      return;
    }
    user32Api.simulateScroll(y, x);
  }

  bool _staysAtZeroZero(int? prevX, int x, int? prevY, int y) {
    return prevX == x && prevY == y && (x == 0 && y == 0);
  }

  void _simulateMouseLeftClick(bool? prev, bool button) {
    _mapToMouse(prev, button, MouseEvent.leftDown, MouseEvent.leftUp);
  }

  void _simulateMouseRightClick(bool? prev, bool button) {
    _mapToMouse(prev, button, MouseEvent.rightDown, MouseEvent.rightUp);
  }

  void _simulateBrowserBack(bool? prev, bool button) {
    _mapToKeyboard(prev, button, KeyboardEvent.browserBack);
  }

  void _simulateBrowserForward(bool? prev, bool button) {
    _mapToKeyboard(prev, button, KeyboardEvent.browserForward);
  }

  void _simulateKeyboardNavigation(
    int? prevThumbX,
    int? prevThumbY,
    int thumbX,
    int thumbY,
  ) {
    const int deadZone = 2;

    //normalize values
    int x = _zeroToTenRange(thumbX);
    int y = _zeroToTenRange(thumbY);
    int? prevX = prevThumbX;
    int? prevY = prevThumbY;

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

  void _simulateVolumeUp(bool? prev, bool button) {
    _mapToKeyboard(prev, button, KeyboardEvent.volumeUp);
  }

  void _simulateVolumeDown(bool? prev, bool button) {
    _mapToKeyboard(prev, button, KeyboardEvent.volumeDown);
  }

  void _simulateWin(bool? prev, bool button) {
    _mapToKeyboard(prev, button, KeyboardEvent.lWin);
  }

  void _simulateShift(bool? prev, bool button) {
    _mapToKeyboard(prev, button, KeyboardEvent.shift);
  }

  void _simulateCtrl(bool? prev, bool button) {
    _mapToKeyboard(prev, button, KeyboardEvent.control);
  }

  void _simulateCtrlC(bool? prev, bool button) {
    const KeyboardEvent ctrl = KeyboardEvent.control;
    const KeyboardEvent c = KeyboardEvent.c;
    _mapToKeyCombination(prev, button, ctrl, c);
  }

  void _simulateCtrlV(bool? prev, bool button) {
    const KeyboardEvent ctrl = KeyboardEvent.control;
    const KeyboardEvent v = KeyboardEvent.v;
    _mapToKeyCombination(prev, button, ctrl, v);
  }

  void _simulateCtrlX(bool? prev, bool button) {
    const KeyboardEvent ctrl = KeyboardEvent.control;
    const KeyboardEvent x = KeyboardEvent.x;
    _mapToKeyCombination(prev, button, ctrl, x);
  }

  void _simulateCtrlW(bool? prev, bool button) {
    const KeyboardEvent ctrl = KeyboardEvent.control;
    const KeyboardEvent w = KeyboardEvent.w;
    _mapToKeyCombination(prev, button, ctrl, w);
  }

  void _simulateCtrlA(bool? prev, bool button) {
    const KeyboardEvent ctrl = KeyboardEvent.control;
    const KeyboardEvent a = KeyboardEvent.a;
    _mapToKeyCombination(prev, button, ctrl, a);
  }

  void _simulateCtrlS(bool? prev, bool button) {
    const KeyboardEvent ctrl = KeyboardEvent.control;
    const KeyboardEvent s = KeyboardEvent.s;
    _mapToKeyCombination(prev, button, ctrl, s);
  }

  void _simulateClickAtCursor(bool? prev, bool button) {
    _mapToControllerAction(prev, button, keyboard.clickAtCursor);
  }

  void _simulateEnter(bool? prev, bool button) {
    _mapToControllerAction(prev, button, keyboard.enter);
  }

  void _simulateBackspace(bool? prev, bool button) {
    _mapToControllerAction(prev, button, keyboard.backspace);
  }

  void _simulateCapsLock(bool? prev, bool button) {
    _mapToControllerAction(prev, button, keyboard.toggleCapsLock);
  }

  void _simulateArrowUp(bool? prev, bool button) {
    _mapToKeyboard(prev, button, KeyboardEvent.up);
  }

  void _simulateArrowDown(bool? prev, bool button) {
    _mapToKeyboard(prev, button, KeyboardEvent.down);
  }

  void _simulateArrowLeft(bool? prev, bool button) {
    _mapToKeyboard(prev, button, KeyboardEvent.left);
  }

  void _simulateArrowRight(bool? prev, bool button) {
    _mapToKeyboard(prev, button, KeyboardEvent.right);
  }

  void _simulateAlt(bool? prev, bool button) {
    _mapToKeyboard(prev, button, KeyboardEvent.alt);
  }

  void _simulateTab(bool? prev, bool button) {
    _mapToKeyboard(prev, button, KeyboardEvent.tab);
  }

  void _mapToKeyCombination(
    bool? prev,
    bool button,
    KeyboardEvent primary,
    KeyboardEvent secondary,
  ) {
    _mapToControllerAction(prev, button, (eventType) {
      if (eventType == KeyboardEventType.up) {
        user32Api.simulateKeyboardEvent(
          keyboardEvent: secondary,
          eventType: eventType,
        );
      }
      user32Api.simulateKeyboardEvent(
        keyboardEvent: primary,
        eventType: eventType,
      );
      if (eventType == KeyboardEventType.down) {
        user32Api.simulateKeyboardEvent(
          keyboardEvent: secondary,
          eventType: eventType,
        );
      }
    });
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
