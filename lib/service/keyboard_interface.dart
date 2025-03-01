import 'package:xtend/data/user_32/model/keyboard_event.dart';

class KeyboardInterface {
  KeyboardInterface({
    required this.charEventStream,
    required this.keyEventStream,
    required this.capsLock,
    required this.setCapsLock,
    required this.up,
    required this.down,
    required this.left,
    required this.right,
    required this.clickAtCursor,
    required this.backspace,
    required this.enter,
    required this.toggleCapsLock,
  });
  final Stream<({int char, KeyboardEventType eventType})> charEventStream;

  final Stream<
    ({KeyboardEvent keyboardEvent, KeyboardEventType eventType, bool repeat})
  >
  keyEventStream;

  final bool capsLock;

  void Function(bool value) setCapsLock;

  void Function(KeyboardEventType eventType) up;

  void Function(KeyboardEventType eventType) down;

  void Function(KeyboardEventType eventType) left;

  void Function(KeyboardEventType eventType) right;

  void Function(KeyboardEventType eventType) clickAtCursor;

  void Function(KeyboardEventType eventType) backspace;

  void Function(KeyboardEventType eventType) enter;

  void Function(KeyboardEventType eventType) toggleCapsLock;
}
