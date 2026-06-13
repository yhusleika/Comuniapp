import 'dart:html' as html;

Future<void> saveFile(String name, List<int> bytes, String mimeType, void Function(String) onComplete) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", name)
    ..click();
  html.Url.revokeObjectUrl(url);
  onComplete('Archivo descargado en el navegador: $name');
}
