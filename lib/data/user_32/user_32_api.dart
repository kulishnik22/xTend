import 'dart:async';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:xtend/data/user_32/model/input/input.dart';
import 'package:xtend/data/user_32/model/keyboard_event.dart';
import 'package:xtend/data/user_32/model/input/keyboard_input.dart';
import 'package:xtend/data/user_32/model/input/mouse_input.dart';
import 'package:xtend/data/user_32/model/mouse_position.dart';
import 'package:xtend/data/user_32/model/input/point.dart';

typedef GetCursorPosNative = Int32 Function(Pointer<POINT>);
typedef GetCursorPosDart = int Function(Pointer<POINT>);

typedef SetCursorPosNative = Int32 Function(Int32, Int32);
typedef SetCursorPosDart = int Function(int, int);

typedef SendInputNative =
    Uint32 Function(Uint32 nInputs, Pointer<INPUT> pInputs, Int32 cbSize);
typedef SendInputDart =
    int Function(int nInputs, Pointer<INPUT> pInputs, int cbSize);

typedef GetKeyStateNative = Int16 Function(Int32);
typedef GetKeyStateDart = int Function(int);

typedef VkKeyScanNative = Int16 Function(Uint16 ch);
typedef VkKeyScanDart = int Function(int ch);

class User32Api {
  User32Api() {
    user32 = DynamicLibrary.open('user32.dll');
    _getCursorPos = user32.lookupFunction<GetCursorPosNative, GetCursorPosDart>(
      'GetCursorPos',
    );
    _setCursorPos = user32.lookupFunction<SetCursorPosNative, SetCursorPosDart>(
      'SetCursorPos',
    );
    _sendInput = user32.lookupFunction<SendInputNative, SendInputDart>(
      'SendInput',
    );
    _getKeyState = user32.lookupFunction<GetKeyStateNative, GetKeyStateDart>(
      'GetKeyState',
    );
    _vkKeyScan = user32.lookupFunction<VkKeyScanNative, VkKeyScanDart>(
      'VkKeyScanW',
    );
  }

  late final DynamicLibrary user32;
  late final GetCursorPosDart _getCursorPos;
  late final SetCursorPosDart _setCursorPos;
  late final SendInputDart _sendInput;
  late final GetKeyStateDart _getKeyState;
  late final VkKeyScanDart _vkKeyScan;

  static const int _scrollDelta = 8;

  Timer? _delayTimer;
  Timer? _repeatTimer;

  void _startRepeat(void Function() callback) {
    _stopRepeat();
    _delayTimer = Timer(const Duration(milliseconds: 500), () {
      _repeatTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
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

  MousePosition? getCursorPosition() {
    Pointer<POINT> point = calloc<POINT>();
    try {
      int result = _getCursorPos(point);
      if (result == 0) {
        return null;
      }
      return MousePosition.fromStruct(point.ref);
    } finally {
      calloc.free(point);
    }
  }

  bool setCursorPosition(int x, int y) {
    int result = _setCursorPos(x, y);
    return result != 0;
  }

  void simulateMouseEvent(MouseEvent event) {
    int inputCount = 1;
    Pointer<INPUT> inputs = calloc<INPUT>(inputCount);
    try {
      (inputs + 0).ref.type = INPUT_MOUSE;
      (inputs + 0).ref.u.mi
        ..dx = 0
        ..dy = 0
        ..mouseData = 0
        ..dwFlags = event.value
        ..time = 0
        ..dwExtraInfo = nullptr;
      int inputSize = sizeOf<INPUT>();
      _sendInput(inputCount, inputs, inputSize);
    } finally {
      calloc.free(inputs);
    }
  }

  void simulateScroll(
    int verticalScrollMultiplier,
    int horizontalScrollMultiplier,
  ) {
    const int inputCount = 2;
    final Pointer<INPUT> inputs = calloc<INPUT>(inputCount);
    try {
      (inputs + 0).ref.type = INPUT_MOUSE;
      (inputs + 0).ref.u.mi
        ..dx = 0
        ..dy = 0
        ..mouseData = _scrollDelta * verticalScrollMultiplier
        ..dwFlags = MouseEvent.wheelVertical.value
        ..time = 0
        ..dwExtraInfo = nullptr;

      (inputs + 1).ref.type = INPUT_MOUSE;
      (inputs + 1).ref.u.mi
        ..dx = 0
        ..dy = 0
        ..mouseData = _scrollDelta * horizontalScrollMultiplier
        ..dwFlags = MouseEvent.wheelHorizontal.value
        ..time = 0
        ..dwExtraInfo = nullptr;

      final int inputSize = sizeOf<INPUT>();
      _sendInput(inputCount, inputs, inputSize);
    } finally {
      calloc.free(inputs);
    }
  }

  void simulateCharacter({
    required int char,
    required bool isCapsLockActive,
    required KeyboardEventType eventType,
  }) {
    KeyData keyData = getKeyData(char);
    if (isCapsLockActive &&
        keyData.requirements.singleOrNull == KeyboardEvent.shift) {
      simulateKeyboardEvent(
        keyboardEvent: keyData.keyboardEvent,
        eventType: eventType,
      );
      return;
    }
    if (eventType == KeyboardEventType.down) {
      for (var key in keyData.requirements) {
        simulateKeyboardEvent(
          keyboardEvent: key,
          eventType: KeyboardEventType.down,
          repeatOnKeyDown: false,
        );
      }
    }
    simulateKeyboardEvent(
      keyboardEvent: keyData.keyboardEvent,
      eventType: eventType,
    );
    if (eventType == KeyboardEventType.up) {
      for (var key in keyData.requirements) {
        simulateKeyboardEvent(
          keyboardEvent: key,
          eventType: KeyboardEventType.up,
          repeatOnKeyDown: false,
        );
      }
    }
  }

  void simulateKeyboardEvent({
    required KeyboardEvent keyboardEvent,
    required KeyboardEventType eventType,
    bool repeatOnKeyDown = true,
  }) {
    _repeatingKeyboardEvent(
      keyPress: () => _performKeyPress(keyboardEvent, eventType),
      eventType: eventType,
      repeatOnKeyDown: repeatOnKeyDown,
    );
  }

  void _repeatingKeyboardEvent({
    required void Function() keyPress,
    required KeyboardEventType eventType,
    bool repeatOnKeyDown = true,
  }) {
    keyPress();
    if (repeatOnKeyDown) {
      switch (eventType) {
        case KeyboardEventType.down:
          _startRepeat(keyPress);
          break;
        case KeyboardEventType.up:
          _stopRepeat();
          break;
      }
    }
  }

  void _performKeyPress(
    KeyboardEvent keyboardEvent,
    KeyboardEventType eventType,
  ) {
    int inputCount = 1;
    Pointer<INPUT> inputs = calloc<INPUT>(inputCount);
    try {
      inputs.ref.type = INPUT_KEYBOARD;
      inputs.ref.u.ki
        ..wVk = keyboardEvent.value
        ..wScan = 0
        ..dwFlags = eventType.value
        ..time = 0
        ..dwExtraInfo = nullptr;
      int inputSize = sizeOf<INPUT>();
      _sendInput(inputCount, inputs, inputSize);
    } finally {
      calloc.free(inputs);
    }
  }

  Stream<bool> getCapsLockStream() async* {
    while (true) {
      yield _isCapsLockActive();
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  bool _isCapsLockActive() {
    final state = _getKeyState(KeyboardEvent.capital.value);
    return (state & 0x0001) != 0;
  }

  KeyData getKeyData(int ascii) {
    int result = _vkKeyScan(ascii);
    int vk = result & 0xFF;
    int shiftState = (result >> 8) & 0xFF;
    return KeyData(
      KeyboardEvent.values.firstWhere((event) => event.value == vk),
      _parseShiftState(shiftState),
    );
  }

  List<KeyboardEvent> _parseShiftState(int shiftState) {
    List<KeyboardEvent> modifiers = [];
    if ((shiftState & 0x01) != 0) {
      modifiers.add(KeyboardEvent.shift);
    }
    if ((shiftState & 0x02) != 0) {
      modifiers.add(KeyboardEvent.control);
    }
    if ((shiftState & 0x04) != 0) {
      modifiers.add(KeyboardEvent.alt);
    }

    return modifiers;
  }

  void dispose() {
    _stopRepeat();
    user32.close();
  }
}
