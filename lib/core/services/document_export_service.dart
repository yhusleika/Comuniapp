import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import '../utils/file_saver.dart';

/// Servicio centralizado para exportación de documentos PDF y Excel
/// con plantilla visual corporativa unificada (estilo Auditoría).
class DocumentExportService {
  DocumentExportService._();

  // ─── Colores Corporativos ─────────────────────────────────────────────────
  static const _headerColor = PdfColors.indigo900;
  static const _headerTextColor = PdfColors.white;
  static const _subtitleColor = PdfColors.grey700;
  static const _dateColor = PdfColors.grey600;
  static const _bodyColor = PdfColors.black;
  static const _oddRowColor = PdfColors.grey100;
  static const _signatureColor = PdfColors.grey800;

  // ─── Exportar PDF Tabular ─────────────────────────────────────────────────
  /// Genera un PDF con la plantilla corporativa unificada y lo envía a descarga.
  ///
  /// [moduleName] - Nombre del módulo (ej. "AUDITORÍA", "CENSOS")
  /// [reportSubtitle] - Subtítulo descriptivo del reporte
  /// [reportTitle] - Título central del reporte (ej. "REPORTE FORMAL DE CENSOS")
  /// [description] - Párrafo descriptivo del reporte
  /// [headers] - Encabezados de la tabla
  /// [data] - Filas de datos de la tabla
  /// [fileName] - Nombre del archivo PDF generado
  /// [landscape] - Si es true, usa formato apaisado (útil para muchas columnas)
  /// [signatureLeft] - Etiqueta firma izquierda
  /// [signatureRight] - Etiqueta firma derecha
  /// [showSignatures] - Si es true, muestra las firmas al final
  static Future<void> exportToPDF({
    required String moduleName,
    required String reportSubtitle,
    required String reportTitle,
    required String description,
    required List<String> headers,
    required List<List<String>> data,
    required String fileName,
    bool landscape = false,
    String signatureLeft = 'Firma del Administrador',
    String signatureRight = 'Firma del Supervisor de Control',
    bool showSignatures = true,
  }) async {
    final pdf = pw.Document();
    final pageFormat = landscape
        ? PdfPageFormat.letter.landscape
        : PdfPageFormat.letter;
    final now = DateTime.now();

    // Ajustar tamaños de fuente según orientación
    final double cellFontSize = landscape ? 7 : 8;
    final double headerFontSize = landscape ? 8 : 9;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'COMUNIAPP - SISTEMA DE $moduleName',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: _headerColor,
                        ),
                      ),
                      pw.Text(
                        reportSubtitle,
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: _subtitleColor,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(now)}',
                        style: const pw.TextStyle(fontSize: 8, color: _dateColor),
                      ),
                      pw.Text(
                        'Página ${context.pageNumber} de ${context.pagesCount}',
                        style: const pw.TextStyle(fontSize: 8, color: _dateColor),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 1, color: _headerColor),
              pw.SizedBox(height: 10),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Reporte Oficial ComuniApp',
                    style: const pw.TextStyle(fontSize: 8, color: _dateColor),
                  ),
                  pw.Text(
                    'Pág. ${context.pageNumber} de ${context.pagesCount}',
                    style: const pw.TextStyle(fontSize: 8, color: _dateColor),
                  ),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) => [
          // ── Título Central ──
          pw.Center(
            child: pw.Text(
              reportTitle,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                decoration: pw.TextDecoration.underline,
              ),
            ),
          ),
          pw.SizedBox(height: 15),

          // ── Descripción ──
          pw.Text(
            description,
            style: const pw.TextStyle(fontSize: 10, color: _bodyColor),
          ),
          pw.SizedBox(height: 20),

          // ── Tabla de Datos ──
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: data,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: _headerTextColor,
              fontSize: headerFontSize,
            ),
            headerDecoration: const pw.BoxDecoration(color: _headerColor),
            cellStyle: pw.TextStyle(fontSize: cellFontSize),
            oddRowDecoration: const pw.BoxDecoration(color: _oddRowColor),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
          ),

          pw.SizedBox(height: 40),

          // ── Firmas ──
          if (showSignatures)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(
                  children: [
                    pw.Container(width: 150, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      signatureLeft,
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: _signatureColor,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Container(width: 150, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      signatureRight,
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: _signatureColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );

    final bytes = await pdf.save();
    await FileSaver.save(
      fileName,
      bytes,
      'application/pdf',
      (_) {},
    );
  }

  // ─── Exportar Excel ───────────────────────────────────────────────────────
  /// Genera un archivo Excel con cabecera estilizada y lo descarga.
  ///
  /// [fileName] - Nombre del archivo (ej. "Reporte_Habitantes")
  /// [sheetName] - Nombre de la hoja
  /// [headers] - Lista de encabezados de columna
  /// [data] - Filas de datos como strings (cada fila debe tener la misma longitud que headers)
  static Future<void> exportToExcel({
    required String fileName,
    required String sheetName,
    required List<String> headers,
    required List<List<String>> data,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel[sheetName];

    sheet.appendRow(
      headers.map((h) => TextCellValue(h) as CellValue?).toList(),
    );

    for (final row in data) {
      sheet.appendRow(
        row.map((cell) => TextCellValue(cell) as CellValue?).toList(),
      );
    }

    final bytes = excel.save();
    if (bytes != null) {
      await FileSaver.save(
        fileName.endsWith('.xlsx') ? fileName : '$fileName.xlsx',
        bytes,
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        (_) {},
      );
    }
  }
  /// Guarda un archivo Excel ya generado usando el FileSaver centralizado.
  static Future<void> saveExcel({
    required String fileName,
    required List<int> bytes,
    required void Function(String) onComplete,
  }) async {
    await FileSaver.save(
      fileName,
      bytes,
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      onComplete,
    );
  }
}
