// ignore_for_file: constant_identifier_names

import 'dart:ffi';

const int INPUT_MOUSE = 0;

enum MouseEvent {
  leftDown(0x0002),
  leftUp(0x0004),
  rightDown(0x0008),
  rightUp(0x0010),
  wheelVertical(0x0800),
  wheelHorizontal(0x01000);

  const MouseEvent(this.value);
  final int value;
}

final class MOUSEINPUT extends Struct {
  @Int32()
  external int dx;
  @Int32()
  external int dy;
  @Uint32()
  external int mouseData;
  @Uint32()
  external int dwFlags;
  @Uint32()
  external int time;
  external Pointer<Void> dwExtraInfo;
}
