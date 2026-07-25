import 'dart:html' as html;

Future<void> saveFile(String name, List<int> bytes, String mimeType, void Function(String) onComplete) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", name)
    ..style.display = 'none';
  
  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();

  // Retrasar la revocación de la URL del Blob para permitir que Chrome complete la descarga
  Future.delayed(const Duration(seconds: 5), () {
    html.Url.revokeObjectUrl(url);
  });

  onComplete('Archivo descargado en el navegador: $name');
}
