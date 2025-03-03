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
    return Config.fromJson(configJson);
  }

  @override
  void writeConfig(Config config) {
    _configFile.writeAsStringSync(jsonEncode(config.toJson()), flush: true);
  }
}
