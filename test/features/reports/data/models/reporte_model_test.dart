import 'package:flutter_test/flutter_test.dart';
import 'package:social_management_pro/features/reports/data/models/reporte_model.dart';
import 'package:social_management_pro/features/reports/domain/entities/reporte.dart';

void main() {
  final tModel = ReporteModel(
    id: 'r1',
    titulo: 'Reporte de prueba',
    descripcion: 'Descripción',
    tipo: 'Agua',
    prioridad: 'Alta',
    estatus: 'Pendiente',
    fotosPaths: [],
    latitud: 10.0,
    longitud: -66.0,
    createdBy: 'admin',
    fechaRegistro: DateTime(2024, 1, 1),
  );

  final tJson = {
    'id': 'r1',
    'titulo': 'Reporte de prueba',
    'descripcion': 'Descripción',
    'tipo': 'Agua',
    'prioridad': 'Alta',
    'estatus': 'Pendiente',
    'fotosPaths': [],
    'latitud': 10.0,
    'longitud': -66.0,
    'createdBy': 'admin',
    'fechaRegistro': '2024-01-01T00:00:00.000',
    'isSynced': true,
  };

  group('ReporteModel', () {
    test('fromJson creates correct model', () {
      final model = ReporteModel.fromJson(tJson);
      expect(model.id, 'r1');
      expect(model.titulo, 'Reporte de prueba');
      expect(model.isSynced, true);
    });

    test('toJson produces correct map', () {
      final json = tModel.toJson();
      expect(json['id'], 'r1');
      expect(json['fechaRegistro'], '2024-01-01T00:00:00.000');
    });

    test('toEntity returns Reporte with correct fields', () {
      final entity = tModel.toEntity();
      expect(entity, isA<Reporte>());
      expect(entity.id, 'r1');
      expect(entity.titulo, 'Reporte de prueba');
    });

    test('fromEntity creates correct model', () {
      final entity = tModel.toEntity();
      final model = ReporteModel.fromEntity(entity);
      expect(model.id, entity.id);
      expect(model.isSynced, false);
    });

    test('copyWith updates isSynced', () {
      final updated = tModel.copyWith(isSynced: true);
      expect(updated.isSynced, true);
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};
      final model = ReporteModel.fromJson(json);
      expect(model.id, '');
      expect(model.estatus, '');
      expect(model.isSynced, true);
    });
  });
}
