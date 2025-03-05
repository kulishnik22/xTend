import 'package:xtend/service/xtend.dart';
import 'package:xtend/view/keyboard/keyboard_controller.dart';
import 'package:xtend/view/keyboard/virtual_keyboard_interface.dart';

class XtendController {
  XtendController({required this.xtend});
  final Xtend xtend;

  Stream<XtendMode> get modeStream => xtend.modeStream;

  Future<XtendExceptionType?> initialize(KeyboardController keyboard) {
    return xtend.initialize(
      VirtualKeyboardInterface(keyboardController: keyboard),
    );
  }

  Future<void> dispose() => xtend.dispose();
}
