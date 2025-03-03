import 'dart:ffi';

const int INPUT_KEYBOARD = 1;

final class KEYBDINPUT extends Struct {
  @Uint16()
  external int wVk;
  @Uint16()
  external int wScan;
  @Uint32()
  external int dwFlags;
  @Uint32()
  external int time;
  external Pointer<Void> dwExtraInfo;
}
