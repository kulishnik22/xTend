import 'package:flutter/services.dart';

class SystemTrayUtil {
  const SystemTrayUtil._();
  static const MethodChannel _channel = MethodChannel('system_tray_util');

  /// Initialize the system tray callback.
  static void initialize({required VoidCallback onExitMenuSelected}) {
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'onExitMenuSelected') {
        onExitMenuSelected();
      }
    });
  }

  /// Add the tray icon.
  static Future<void> addTrayIcon() async {
    try {
      final bool result = await _channel.invokeMethod('addTrayIcon');
      if (!result) {
        throw const TrayMessageException(message: 'Failed to add tray icon.');
      }
    } on PlatformException catch (cause, stackTrace) {
      throw TrayException(cause: cause, stackTrace: stackTrace);
    }
  }

  /// Remove the tray icon.
  static Future<void> removeTrayIcon() async {
    try {
      final bool result = await _channel.invokeMethod('removeTrayIcon');
      if (!result) {
        throw const TrayMessageException(
          message: 'Failed to remove tray icon.',
        );
      }
    } on PlatformException catch (cause, stackTrace) {
      throw TrayException(cause: cause, stackTrace: stackTrace);
    }
  }
}

class TrayException implements Exception {
  const TrayException({this.cause, this.stackTrace});
  final Object? cause;
  final StackTrace? stackTrace;
}

class TrayMessageException implements Exception {
  const TrayMessageException({this.message});
  final String? message;
}
