import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';

Future<void> saveFile(String name, List<int> bytes, String mimeType, void Function(String) onComplete) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = io.File('${directory.path}/$name');
  await file.writeAsBytes(bytes);
  onComplete('Archivo guardado en: ${file.path}');
}
