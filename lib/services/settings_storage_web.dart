import 'package:web/web.dart' as web;

const _settingsKey = 'finanzas_app_settings';

Future<String?> readSettings() async {
  return web.window.localStorage.getItem(_settingsKey);
}

Future<void> writeSettings(String contents) async {
  web.window.localStorage.setItem(_settingsKey, contents);
}

Future<void> deleteSettings() async {
  web.window.localStorage.removeItem(_settingsKey);
}
