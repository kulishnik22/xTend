import 'dart:async';

import 'package:flutter/services.dart';

class WindowUtil {
  static const MethodChannel _channel = MethodChannel('window_util');

  static Timer? _hideTimer;
  static Future<void> showWindow([
    Duration hideDuration = const Duration(seconds: 1),
  ]) async {
    if (_hideTimer != null) {
      _hideTimer!.cancel();
      _resetHideTimer(hideDuration);
      return;
    }
    await _showWindowWithoutFocus(size: const Size(200, 200));
    _resetHideTimer(hideDuration);
  }

  static Future<void> showKeyboard() {
    if (_hideTimer != null) {
      _hideTimer!.cancel();
      _hideTimer = null;
    }
    return _showWindowWithoutFocus(
      size: const Size(1000, 500),
      center: false,
      opacity: 125,
    );
  }

  static void _resetHideTimer(Duration hideDuration) {
    _hideTimer = Timer(hideDuration, () async {
      await hideWindow();
      _hideTimer = null;
    });
  }

  static Future<void> _showWindowWithoutFocus({
    required Size size,
    bool center = true,
    int opacity = 255,
  }) {
    return _channel.invokeMethod('showWindowWithoutFocus', {
      'width': size.width,
      'height': size.height,
      'center': center,
      'opacity': opacity,
    });
  }

  static Future<void> hideWindow() {
    return _channel.invokeMethod('hideWindow');
  }

  static Future<void> closeWindow() {
    return _channel.invokeMethod('closeWindow');
  }
}
