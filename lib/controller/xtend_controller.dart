import 'package:xtend/service/keyboard_interface.dart';
import 'package:xtend/service/xtend.dart';

class XtendController {
  XtendController({required this.xtend});
  final Xtend xtend;

  Stream<XtendMode> get modeStream => xtend.modeStream;
  Future<void> initialize(KeyboardInterface keyboard) {
    return xtend.initialize(keyboard);
  }

  Future<void> dispose() => xtend.dispose();
}
