// ignore_for_file: camel_case_types, non_constant_identifier_names

import 'dart:ffi';

final class XINPUT_GAMEPAD extends Struct {
  @Uint16()
  external int wButtons;

  @Uint8()
  external int bLeftTrigger;

  @Uint8()
  external int bRightTrigger;

  @Int16()
  external int sThumbLX;

  @Int16()
  external int sThumbLY;

  @Int16()
  external int sThumbRX;

  @Int16()
  external int sThumbRY;
}

final class XINPUT_STATE extends Struct {
  @Uint32()
  external int dwPacketNumber;

  external XINPUT_GAMEPAD Gamepad;
}
