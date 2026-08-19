import 'package:flutter_test/flutter_test.dart';
import 'package:social_management_pro/features/habitantes/data/models/habitante_model.dart';
import 'package:social_management_pro/features/habitantes/domain/entities/habitante.dart';

void main() {
  final tModel = HabitanteModel(
    id: 'h1',
    cedula: '12345678',
    nombres: 'Juan',
    apellidos: 'Pérez',
    telefono: '04121234567',
    sector: 'Sector A',
    puntoReferencia: 'Casa 1',
    tieneDiscapacidad: false,
    tieneEnfermedadCronica: false,
    condicionVivienda: 'Buena',
    tipoVivienda: 'Casa',
    registeredBy: 'admin',
    fechaRegistro: DateTime(2024, 1, 1),
    sexo: 'Masculino',
  );

  final tJson = {
    'id': 'h1',
    'cedula': '12345678',
    'nombres': 'Juan',
    'apellidos': 'Pérez',
    'telefono': '04121234567',
    'sector': 'Sector A',
    'puntoReferencia': 'Casa 1',
    'tieneDiscapacidad': false,
    'detallesDiscapacidad': '',
    'tieneEnfermedadCronica': false,
    'detallesEnfermedad': '',
    'condicionVivienda': 'Buena',
    'tipoVivienda': 'Casa',
    'registeredBy': 'admin',
    'fechaRegistro': '2024-01-01T00:00:00.000',
    'fechaNacimiento': null,
    'sexo': 'Masculino',
    'isSynced': true,
    'ayudaRecibida': '',
  };

  group('HabitanteModel', () {
    test('fromJson creates correct model', () {
      final model = HabitanteModel.fromJson(tJson);
      expect(model.id, 'h1');
      expect(model.nombres, 'Juan');
      expect(model.apellidos, 'Pérez');
      expect(model.isSynced, true);
    });

    test('toJson produces correct map', () {
      final json = tModel.toJson();
      expect(json['id'], 'h1');
      expect(json['nombres'], 'Juan');
      expect(json['fechaRegistro'], '2024-01-01T00:00:00.000');
    });

    test('toEntity returns Habitante with correct fields', () {
      final entity = tModel.toEntity();
      expect(entity, isA<Habitante>());
      expect(entity.id, 'h1');
      expect(entity.nombres, 'Juan');
    });

    test('fromEntity creates correct model', () {
      final entity = tModel.toEntity();
      final model = HabitanteModel.fromEntity(entity);
      expect(model.id, entity.id);
      expect(model.nombres, entity.nombres);
      expect(model.isSynced, false);
    });

    test('copyWith updates isSynced', () {
      final updated = tModel.copyWith(isSynced: true);
      expect(updated.isSynced, true);
      expect(updated.id, 'h1');
    });

    test('fromJson handles missing fields with defaults', () {
      final minimalJson = <String, dynamic>{};
      final model = HabitanteModel.fromJson(minimalJson);
      expect(model.id, '');
      expect(model.sexo, '');
      expect(model.isSynced, true);
    });
  });
}
