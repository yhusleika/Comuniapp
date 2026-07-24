import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> saveFile(String name, List<int> bytes, String mimeType, void Function(String) onComplete) async {
  final directory = await getTemporaryDirectory();
  final file = io.File('${directory.path}/$name');
  await file.writeAsBytes(bytes);
  
  await Share.shareXFiles(
    [XFile(file.path, mimeType: mimeType)],
    text: name,
  );
  
  onComplete('Archivo exportado correctamente');
}
