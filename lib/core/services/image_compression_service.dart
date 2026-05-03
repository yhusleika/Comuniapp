import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageCompressionService {
  Future<File?> compressAndGetFile(File file, String targetPath) async {
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      minWidth: 1024,
      minHeight: 1024,
      quality: 70,
    );
    
    if (result == null) return null;
    return File(result.path);
  }

  Future<String> saveCompressedImage(File imageFile) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_compressed.jpg';
    final targetPath = p.join(dir.path, fileName);
    
    // On basic file systems, we might just copy if compression fails or isn't supported on platform
    try {
        final compressed = await compressAndGetFile(imageFile, targetPath);
        return compressed?.path ?? imageFile.path;
    } catch(e) {
        // Fallback
        final newFile = await imageFile.copy(targetPath);
        return newFile.path;
    }
  }
}
