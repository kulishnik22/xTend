import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

typedef IconGetter = Widget Function({double? size, Color? color, BoxFit? fit});

class XtendIcons {
  XtendIcons._();
  static const double defaultSize = 100;

  static IconGetter gamepad = _getIconGetter('gamepad');
  static IconGetter mouse = _getIconGetter('mouse');
  static IconGetter none = _getIconGetter('none');

  static IconGetter _getIconGetter(String asset) {
    return ({double? size, Color? color, BoxFit? fit}) => SizedBox(
      width: size ?? defaultSize,
      height: size ?? defaultSize,
      child: SvgPicture.asset(
        'assets/$asset.svg',
        fit: fit ?? BoxFit.fill,
        colorFilter: ColorFilter.mode(color ?? Colors.white, BlendMode.srcIn),
      ),
    );
  }
}
