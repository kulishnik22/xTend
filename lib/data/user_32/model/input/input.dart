import 'dart:ffi';

import 'package:xtend/data/user_32/model/input/keyboard_input.dart';
import 'package:xtend/data/user_32/model/input/mouse_input.dart';

final class InputUnion extends Union {
  external MOUSEINPUT mi;
  external KEYBDINPUT ki;
}

final class INPUT extends Struct {
  @Uint32()
  external int type;
  external InputUnion u;
}
