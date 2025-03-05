import 'dart:convert';
import 'dart:io';

import 'package:xtend/data/config/model/config.dart';

abstract class ConfigService {
  factory ConfigService.file() => FileConfigService();
  Config readConfig();

  void writeConfig(Config config);
}

class FileConfigService implements ConfigService {
  static final File _configFile = File('config.json');

  @override
  Config readConfig() {
    if (!_configFile.existsSync()) {
      _configFile.createSync();
      Config defaultConfig = const Config.standard();
      writeConfig(defaultConfig);
      return defaultConfig;
    }
    String rawJson = _configFile.readAsStringSync();
    Map<String, dynamic> configJson = jsonDecode(rawJson);
    return _deserialize(configJson);
  }

  Config _deserialize(Map<String, dynamic> configJson) {
    try {
      return Config.fromJson(configJson);
    } on Object catch (cause, stackTrace) {
      throw DeserializationException(cause, stackTrace);
    }
  }

  @override
  void writeConfig(Config config) {
    _configFile.writeAsStringSync(jsonEncode(config.toJson()), flush: true);
  }
}

class DeserializationException implements Exception {
  const DeserializationException(this.cause, this.stackTrace);

  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => 'DeserializationException: $cause';
}
