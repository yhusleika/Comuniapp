import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> saveFile(String name, List<int> bytes, String mimeType, void Function(String) onComplete) async {
  String? savedPath;

  // 1. En Android, intentar guardar primero en la carpeta pública de Descargas (/storage/emulated/0/Download)
  if (io.Platform.isAndroid) {
    try {
      final publicDownloads = io.Directory('/storage/emulated/0/Download');
      if (await publicDownloads.exists()) {
        final publicFile = io.File('${publicDownloads.path}/$name');
        await publicFile.writeAsBytes(bytes);
        savedPath = publicFile.path;
      }
    } catch (_) {
      // Si Android deniega el acceso directo por Scoped Storage, continuamos con el fallback
    }
  }

  // 2. Si no se pudo guardar en la carpeta pública directamente, usar path_provider
  if (savedPath == null) {
    io.Directory? targetDir;
    try {
      targetDir = await getDownloadsDirectory();
    } catch (_) {}
    targetDir ??= await getApplicationDocumentsDirectory();

    final file = io.File('${targetDir.path}/$name');
    await file.writeAsBytes(bytes);
    savedPath = file.path;
  }

  // 3. Abrir el selector/compartidor nativo del teléfono para que el usuario pueda abrir o guardar donde desee
  try {
    await Share.shareXFiles(
      [XFile(savedPath, mimeType: mimeType, name: name)],
      text: 'Reporte generado: $name',
    );
  } catch (_) {}

  onComplete('Archivo guardado: $savedPath');
}
