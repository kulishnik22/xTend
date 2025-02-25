// ignore_for_file: non_constant_identifier_names

import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:xtend/data/xinput/model/gamepad.dart';
import 'package:xtend/data/xinput/model/xinput_state.dart';

typedef XInputGetStateNative = Uint32 Function(Uint32, Pointer<XINPUT_STATE>);
typedef XInputGetStateDart = int Function(int, Pointer<XINPUT_STATE>);

const String libraryName = 'xinput1_4.dll';
const String functionName = 'XInputGetState';

class XinputApi {
  XinputApi() {
    xinput = DynamicLibrary.open(libraryName);
    XInputGetState = xinput
        .lookupFunction<XInputGetStateNative, XInputGetStateDart>(functionName);
  }
  late final DynamicLibrary xinput;
  late final XInputGetStateDart XInputGetState;

  Gamepad? readState(int controllerId) {
    Pointer<XINPUT_STATE> state = calloc<XINPUT_STATE>();
    try {
      int result = XInputGetState(controllerId, state);
      if (result != 0) {
        return null;
      }
      Gamepad gamepad = Gamepad.fromStruct(state.ref.Gamepad);
      return gamepad;
    } finally {
      calloc.free(state);
    }
  }

  void dispose() {
    xinput.close();
  }
}
