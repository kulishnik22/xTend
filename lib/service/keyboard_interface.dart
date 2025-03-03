import 'package:xtend/data/user_32/model/keyboard_event.dart';

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
