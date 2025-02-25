import 'dart:ffi';

final class POINT extends Struct {
  @Int32()
  external int x;

  @Int32()
  external int y;
}
