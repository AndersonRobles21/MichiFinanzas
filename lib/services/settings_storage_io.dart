import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<File> _settingsFile() async {
  final directory = await getApplicationDocumentsDirectory();
  return File(
    '${directory.path}${Platform.pathSeparator}finanzas_app_settings.json',
  );
}

Future<String?> readSettings() async {
  final file = await _settingsFile();
  if (!await file.exists()) return null;
  return file.readAsString();
}

Future<void> writeSettings(String contents) async {
  final file = await _settingsFile();
  await file.parent.create(recursive: true);
  await file.writeAsString(contents, flush: true);
}

Future<void> deleteSettings() async {
  final file = await _settingsFile();
  if (await file.exists()) await file.delete();
}
