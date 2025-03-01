import 'package:xtend/data/user_32/model/keyboard_event.dart';
import 'package:xtend/view/keyboard/keyboard_controller.dart';
import 'package:xtend/view/keyboard/keyboard_layout.dart';

abstract class KeyboardInterface {
  Stream<({int char, KeyboardEventType eventType})> get charEventStream;

  Stream<
    ({KeyboardEvent keyboardEvent, KeyboardEventType eventType, bool repeat})
  >
  get keyEventStream;

  bool get capsLock;

  set capsLock(bool value);

  void up(KeyboardEventType eventType);

  void down(KeyboardEventType eventType);

  void left(KeyboardEventType eventType);

  void right(KeyboardEventType eventType);

  void clickAtCursor(KeyboardEventType eventType);

  void backspace(KeyboardEventType eventType);

  void enter(KeyboardEventType eventType);

  void toggleCapsLock(KeyboardEventType eventType);
}

class VirtualKeyboardInterface extends KeyboardInterface {
  VirtualKeyboardInterface({required this.keyboardController});

  final KeyboardController keyboardController;

  @override
  Stream<({int char, KeyboardEventType eventType})> get charEventStream =>
      keyboardController.onKey
          .where((keyEvent) => keyEvent.key is TextKey)
          .map(
            (keyEvent) => (
              char: (keyEvent.key as TextKey).value.codeUnitAt(0),
              eventType: keyEvent.eventType,
            ),
          )
          .asBroadcastStream();

  @override
  Stream<
    ({KeyboardEventType eventType, KeyboardEvent keyboardEvent, bool repeat})
  >
  get keyEventStream =>
      keyboardController.onKey
          .where((keyEvent) => keyEvent.key is FunctionalKey)
          .map((keyEvent) {
            FunctionalKey functionalKey = keyEvent.key as FunctionalKey;
            if (functionalKey.value == FunctionalKeyType.capsLock) {
              return (
                eventType: keyEvent.eventType,
                keyboardEvent: KeyboardEvent.capital,
                repeat: false,
              );
            }
            return (
              eventType: keyEvent.eventType,
              keyboardEvent: _fromFunctionalKeyType(functionalKey.value),
              repeat: true,
            );
          })
          .asBroadcastStream();

  KeyboardEvent _fromFunctionalKeyType(FunctionalKeyType functionalKeyType) {
    return switch (functionalKeyType) {
      FunctionalKeyType.backspace => KeyboardEvent.back,
      FunctionalKeyType.enter => KeyboardEvent.enter,
      FunctionalKeyType.capsLock => KeyboardEvent.capital,
    };
  }

  @override
  bool get capsLock => keyboardController.capsLockState.value;

  @override
  set capsLock(bool value) {
    keyboardController.setCapsLock(value);
  }

  @override
  void backspace(KeyboardEventType eventType) {
    keyboardController.backspace(eventType);
  }

  @override
  void clickAtCursor(KeyboardEventType eventType) {
    keyboardController.clickAtCursor(eventType);
  }

  @override
  void down(KeyboardEventType eventType) {
    keyboardController.down(eventType);
  }

  @override
  void enter(KeyboardEventType eventType) {
    keyboardController.enter(eventType);
  }

  @override
  void left(KeyboardEventType eventType) {
    keyboardController.left(eventType);
  }

  @override
  void right(KeyboardEventType eventType) {
    keyboardController.right(eventType);
  }

  @override
  void toggleCapsLock(KeyboardEventType eventType) {
    keyboardController.toggleCapsLock(eventType);
  }

  @override
  void up(KeyboardEventType eventType) {
    keyboardController.up(eventType);
  }
}
