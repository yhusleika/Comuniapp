import 'file_saver_mobile.dart'
    if (dart.library.html) 'file_saver_web.dart' as platform;

class FileSaver {
  static Future<void> save(String name, List<int> bytes, String mimeType, void Function(String) onComplete) async {
    await platform.saveFile(name, bytes, mimeType, onComplete);
  }
}
