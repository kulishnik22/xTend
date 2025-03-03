import 'package:equatable/equatable.dart';

class Config extends Equatable {
  const Config({required this.mouse, required this.keyboard});

  const Config.standard()
    : this(
        mouse: const GamepadMapping.mouseStandard(),
        keyboard: const GamepadMapping.keyboardStandard(),
      );

  factory Config.fromJson(Map<String, dynamic> json) => Config(
    mouse: GamepadMapping.fromJson(json['mouse'] as Map<String, dynamic>),
    keyboard: GamepadMapping.fromJson(json['keyboard'] as Map<String, dynamic>),
  );
  final GamepadMapping mouse;
  final GamepadMapping keyboard;

  Map<String, dynamic> toJson() => {
    'mouse': mouse.toJson(),
    'keyboard': keyboard.toJson(),
  };

  @override
  List<Object?> get props => [mouse, keyboard];
}

class GamepadMapping extends Equatable {
  const GamepadMapping({
    required this.a,
    required this.b,
    required this.x,
    required this.y,
    required this.dPadUp,
    required this.dPadDown,
    required this.dPadLeft,
    required this.dPadRight,
    required this.leftThumb,
    required this.rightThumb,
    required this.leftShoulder,
    required this.rightShoulder,
    required this.leftJoystick,
    required this.rightJoystick,
    required this.leftTrigger,
    required this.rightTrigger,
  });

  const GamepadMapping.mouseStandard()
    : this(
        a: ButtonAction.mouseLeftClick,
        b: ButtonAction.mouseRightClick,
        x: ButtonAction.browserBack,
        y: ButtonAction.browserForward,
        dPadUp: ButtonAction.none,
        dPadDown: ButtonAction.none,
        dPadLeft: ButtonAction.none,
        dPadRight: ButtonAction.none,
        leftThumb: ButtonAction.none,
        rightThumb: ButtonAction.none,
        leftShoulder: ButtonAction.alt,
        rightShoulder: ButtonAction.tab,
        leftJoystick: JoystickAction.mouse,
        rightJoystick: JoystickAction.scroll,
        leftTrigger: ButtonAction.volumeUp,
        rightTrigger: ButtonAction.volumeDown,
      );

  const GamepadMapping.keyboardStandard()
    : this(
        a: ButtonAction.clickAtKeyboardCursor,
        b: ButtonAction.backspace,
        x: ButtonAction.enter,
        y: ButtonAction.capsLock,
        dPadUp: ButtonAction.arrowUp,
        dPadDown: ButtonAction.arrowDown,
        dPadLeft: ButtonAction.arrowLeft,
        dPadRight: ButtonAction.arrowRight,
        leftThumb: ButtonAction.none,
        rightThumb: ButtonAction.none,
        leftShoulder: ButtonAction.alt,
        rightShoulder: ButtonAction.tab,
        leftJoystick: JoystickAction.keyboardNavigation,
        rightJoystick: JoystickAction.none,
        leftTrigger: ButtonAction.ctrlC,
        rightTrigger: ButtonAction.ctrlV,
      );

  factory GamepadMapping.fromJson(Map<String, dynamic> json) => GamepadMapping(
    a: ButtonAction.values.firstWhere((action) => action.name == json['a']),
    b: ButtonAction.values.firstWhere((action) => action.name == json['b']),
    x: ButtonAction.values.firstWhere((action) => action.name == json['x']),
    y: ButtonAction.values.firstWhere((action) => action.name == json['y']),
    dPadUp: ButtonAction.values.firstWhere(
      (action) => action.name == json['dPadUp'],
    ),
    dPadDown: ButtonAction.values.firstWhere(
      (action) => action.name == json['dPadDown'],
    ),
    dPadLeft: ButtonAction.values.firstWhere(
      (action) => action.name == json['dPadLeft'],
    ),
    dPadRight: ButtonAction.values.firstWhere(
      (action) => action.name == json['dPadRight'],
    ),
    leftThumb: ButtonAction.values.firstWhere(
      (action) => action.name == json['leftThumb'],
    ),
    rightThumb: ButtonAction.values.firstWhere(
      (action) => action.name == json['rightThumb'],
    ),
    leftShoulder: ButtonAction.values.firstWhere(
      (action) => action.name == json['leftShoulder'],
    ),
    rightShoulder: ButtonAction.values.firstWhere(
      (action) => action.name == json['rightShoulder'],
    ),
    leftTrigger: ButtonAction.values.firstWhere(
      (action) => action.name == json['leftTrigger'],
    ),
    rightTrigger: ButtonAction.values.firstWhere(
      (action) => action.name == json['rightTrigger'],
    ),
    leftJoystick: JoystickAction.values.firstWhere(
      (action) => action.name == json['leftJoystick'],
    ),
    rightJoystick: JoystickAction.values.firstWhere(
      (action) => action.name == json['rightJoystick'],
    ),
  );

  final ButtonAction a;
  final ButtonAction b;
  final ButtonAction x;
  final ButtonAction y;
  final ButtonAction dPadUp;
  final ButtonAction dPadDown;
  final ButtonAction dPadLeft;
  final ButtonAction dPadRight;
  final ButtonAction leftThumb;
  final ButtonAction rightThumb;
  final ButtonAction leftShoulder;
  final ButtonAction rightShoulder;
  final ButtonAction leftTrigger;
  final ButtonAction rightTrigger;
  final JoystickAction leftJoystick;
  final JoystickAction rightJoystick;

  Map<String, dynamic> toJson() => {
    'a': a.name,
    'b': b.name,
    'x': x.name,
    'y': y.name,
    'dPadUp': dPadUp.name,
    'dPadDown': dPadDown.name,
    'dPadLeft': dPadLeft.name,
    'dPadRight': dPadRight.name,
    'leftThumb': leftThumb.name,
    'rightThumb': rightThumb.name,
    'leftShoulder': leftShoulder.name,
    'rightShoulder': rightShoulder.name,
    'leftTrigger': leftTrigger.name,
    'rightTrigger': rightTrigger.name,
    'leftJoystick': leftJoystick.name,
    'rightJoystick': rightJoystick.name,
  };

  @override
  List<Object?> get props => [
    a,
    b,
    x,
    y,
    dPadUp,
    dPadDown,
    dPadLeft,
    dPadRight,
    leftThumb,
    rightThumb,
    leftShoulder,
    rightShoulder,
    leftTrigger,
    rightTrigger,
    leftJoystick,
    rightJoystick,
  ];
}

enum ButtonAction {
  mouseLeftClick,
  mouseRightClick,
  browserBack,
  browserForward,
  alt,
  tab,
  arrowUp,
  arrowDown,
  arrowLeft,
  arrowRight,
  backspace,
  enter,
  capsLock,
  clickAtKeyboardCursor,
  volumeUp,
  volumeDown,
  shift,
  win,
  ctrl,
  ctrlC,
  ctrlV,
  ctrlX,
  ctrlW,
  ctrlA,
  ctrlS,
  none,
}

enum JoystickAction { mouse, scroll, keyboardNavigation, none }
