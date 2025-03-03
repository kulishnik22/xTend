import 'package:get_it/get_it.dart';

abstract class DependencyAdapter {
  T get<T extends Object>();
  void registerSingleton<T extends Object>(T value);
}

class GetItDependencyAdapter implements DependencyAdapter {
  final GetIt _getIt = GetIt.instance;
  @override
  T get<T extends Object>() {
    return _getIt.get<T>();
  }

  @override
  void registerSingleton<T extends Object>(T value) {
    _getIt.registerSingleton<T>(value);
  }
}

class Dependency implements DependencyAdapter {
  Dependency._internal(DependencyAdapter adapter) {
    _adapter = adapter;
  }
  factory Dependency.initialize(DependencyAdapter adapter) {
    return _instance ??= Dependency._internal(adapter);
  }

  static Dependency get instance => _instance!;

  static Dependency? _instance;

  static late final DependencyAdapter _adapter;

  @override
  T get<T extends Object>() {
    return _adapter.get<T>();
  }

  @override
  void registerSingleton<T extends Object>(T value) {
    _adapter.registerSingleton<T>(value);
  }
}
