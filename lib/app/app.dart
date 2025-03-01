import 'package:xtend/app/dependency.dart';
import 'package:xtend/controller/xtend_controller.dart';
import 'package:xtend/data/user_32/user_32_api.dart';
import 'package:xtend/data/xinput/gamepad_service.dart';
import 'package:xtend/service/xtend.dart';
import 'package:xtend/view/xtend_view.dart';

class XtendApp {
  XtendApp._internal(this._dependency);
  factory XtendApp.initialize() {
    return _instance ??= XtendApp._internal(
      Dependency.initialize(GetItDependencyAdapter()),
    );
  }

  factory XtendApp() => _instance ?? XtendApp.initialize();

  static XtendApp? _instance;
  final Dependency _dependency;

  T get<T extends Object>() => _dependency.get<T>();

  void registerDependencies() {
    _registerDataSources();
    _registerServices();
    _registerControllers();
    _registerViews();
  }

  void _registerDataSources() {
    _dependency.registerSingleton(User32Api());
    _dependency.registerSingleton(GamepadService());
  }

  void _registerServices() {
    _dependency.registerSingleton(
      Xtend(
        user32Api: _dependency.get<User32Api>(),
        gamepadService: _dependency.get<GamepadService>(),
      ),
    );
  }

  void _registerControllers() {
    _dependency.registerSingleton(
      XtendController(xtend: _dependency.get<Xtend>()),
    );
  }

  void _registerViews() {
    _dependency.registerSingleton(
      XtendView(controller: _dependency.get<XtendController>()),
    );
  }
}
