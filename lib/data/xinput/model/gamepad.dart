import 'package:equatable/equatable.dart';
import 'package:xtend/data/xinput/model/xinput_state.dart';

class Gamepad extends Equatable {
  const Gamepad({
    required this.buttons,
    required this.leftTrigger,
    required this.rightTrigger,
    required this.leftThumbX,
    required this.leftThumbY,
    required this.rightThumbX,
    required this.rightThumbY,
  });

  factory Gamepad.fromStruct(XINPUT_GAMEPAD gamepad) => Gamepad(
    buttons: Buttons.fromBitField(gamepad.wButtons),
    leftTrigger: gamepad.bLeftTrigger,
    rightTrigger: gamepad.bRightTrigger,
    leftThumbX: gamepad.sThumbLX,
    leftThumbY: gamepad.sThumbLY,
    rightThumbX: gamepad.sThumbRX,
    rightThumbY: gamepad.sThumbRY,
  );

  factory Gamepad.fromJson(Map<String, dynamic> json) => Gamepad(
    buttons: Buttons.fromJson(json['buttons'] as Map<String, dynamic>),
    leftTrigger: json['leftTrigger'] as int,
    rightTrigger: json['rightTrigger'] as int,
    leftThumbX: json['leftThumbX'] as int,
    leftThumbY: json['leftThumbY'] as int,
    rightThumbX: json['rightThumbX'] as int,
    rightThumbY: json['rightThumbY'] as int,
  );

  final Buttons buttons;
  final int leftTrigger;
  final int rightTrigger;
  final int leftThumbX;
  final int leftThumbY;
  final int rightThumbX;
  final int rightThumbY;

  Map<String, dynamic> toJson() => {
    'buttons': buttons.toJson(),
    'leftTrigger': leftTrigger,
    'rightTrigger': rightTrigger,
    'leftThumbX': leftThumbX,
    'leftThumbY': leftThumbY,
    'rightThumbX': rightThumbX,
    'rightThumbY': rightThumbY,
  };

  @override
  List<Object?> get props => [
    buttons,
    leftTrigger,
    rightTrigger,
    leftThumbX,
    leftThumbY,
    rightThumbX,
    rightThumbY,
  ];
}

class Buttons extends Equatable {
  const Buttons({
    required this.dPadUp,
    required this.dPadDown,
    required this.dPadLeft,
    required this.dPadRight,
    required this.start,
    required this.back,
    required this.leftThumb,
    required this.rightThumb,
    required this.leftShoulder,
    required this.rightShoulder,
    required this.a,
    required this.b,
    required this.x,
    required this.y,
  });

  factory Buttons.fromBitField(int buttons) => Buttons(
    dPadUp: buttons & 0x0001 != 0,
    dPadDown: buttons & 0x0002 != 0,
    dPadLeft: buttons & 0x0004 != 0,
    dPadRight: buttons & 0x0008 != 0,
    start: buttons & 0x0010 != 0,
    back: buttons & 0x0020 != 0,
    leftThumb: buttons & 0x0040 != 0,
    rightThumb: buttons & 0x0080 != 0,
    leftShoulder: buttons & 0x0100 != 0,
    rightShoulder: buttons & 0x0200 != 0,
    a: buttons & 0x1000 != 0,
    b: buttons & 0x2000 != 0,
    x: buttons & 0x4000 != 0,
    y: buttons & 0x8000 != 0,
  );

  factory Buttons.fromJson(Map<String, dynamic> json) => Buttons(
    dPadUp: json['dPadUp'] as bool,
    dPadDown: json['dPadDown'] as bool,
    dPadLeft: json['dPadLeft'] as bool,
    dPadRight: json['dPadRight'] as bool,
    start: json['start'] as bool,
    back: json['back'] as bool,
    leftThumb: json['leftThumb'] as bool,
    rightThumb: json['rightThumb'] as bool,
    leftShoulder: json['leftShoulder'] as bool,
    rightShoulder: json['rightShoulder'] as bool,
    a: json['a'] as bool,
    b: json['b'] as bool,
    x: json['x'] as bool,
    y: json['y'] as bool,
  );

  final bool dPadUp;
  final bool dPadDown;
  final bool dPadLeft;
  final bool dPadRight;
  final bool start;
  final bool back;
  final bool leftThumb;
  final bool rightThumb;
  final bool leftShoulder;
  final bool rightShoulder;
  final bool a;
  final bool b;
  final bool x;
  final bool y;

  Map<String, dynamic> toJson() => {
    'dPadUp': dPadUp,
    'dPadDown': dPadDown,
    'dPadLeft': dPadLeft,
    'dPadRight': dPadRight,
    'start': start,
    'back': back,
    'leftThumb': leftThumb,
    'rightThumb': rightThumb,
    'leftShoulder': leftShoulder,
    'rightShoulder': rightShoulder,
    'a': a,
    'b': b,
    'x': x,
    'y': y,
  };

  @override
  List<Object?> get props => [
    dPadUp,
    dPadDown,
    dPadLeft,
    dPadRight,
    start,
    back,
    leftThumb,
    rightThumb,
    leftShoulder,
    rightShoulder,
    a,
    b,
    x,
    y,
  ];
}
