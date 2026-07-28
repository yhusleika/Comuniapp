import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:social_management_pro/core/error/failures.dart';
import 'package:social_management_pro/core/network/network_info.dart';
import 'package:social_management_pro/core/services/mongodb_service.dart';
import 'package:social_management_pro/features/habitantes/data/datasources/habitants_local_data_source.dart';
import 'package:social_management_pro/features/habitantes/data/models/habitante_model.dart';
import 'package:social_management_pro/features/habitantes/data/repositories/habitants_repository_impl.dart';
import 'package:social_management_pro/features/habitantes/domain/entities/habitante.dart';

class MockLocalDataSource extends Mock implements HabitantsLocalDataSource {}
class MockNetworkInfo extends Mock implements NetworkInfo {}
class MockMongoDBService extends Mock implements MongoDBService {}

void main() {
  late HabitantsRepositoryImpl repository;
  late MockLocalDataSource mockLocal;
  late MockNetworkInfo mockNetwork;
  late MockMongoDBService mockMongo;

  setUp(() {
    mockLocal = MockLocalDataSource();
    mockNetwork = MockNetworkInfo();
    mockMongo = MockMongoDBService();
    repository = HabitantsRepositoryImpl(
      localDataSource: mockLocal,
      networkInfo: mockNetwork,
      mongoDBService: mockMongo,
    );
  });

  final tModel = HabitanteModel(
    id: 'h1', cedula: '12345678', nombres: 'Juan', apellidos: 'Pérez',
    telefono: '0412', sector: 'A', puntoReferencia: 'C1',
    tieneDiscapacidad: false, tieneEnfermedadCronica: false,
    condicionVivienda: 'B', tipoVivienda: 'Casa',
    registeredBy: 'admin', fechaRegistro: DateTime(2024, 1, 1),
  );

  group('getHabitants', () {
    test('should return local habitants when offline', () async {
      when(() => mockNetwork.isConnected).thenAnswer((_) async => false);
      when(() => mockLocal.getHabitants()).thenAnswer((_) async => [tModel]);

      final result = await repository.getHabitants('');

      expect(result.isRight(), true);
      result.fold((l) => null, (r) {
        expect(r.length, 1);
        expect(r.first.nombres, 'Juan');
      });
    });

    test('should sync remote data then return local when online', () async {
      when(() => mockNetwork.isConnected).thenAnswer((_) async => true);
      when(() => mockMongo.getRecords('habitants')).thenAnswer((_) async => []);
      when(() => mockLocal.getHabitants()).thenAnswer((_) async => [tModel]);

      final result = await repository.getHabitants('');

      expect(result.isRight(), true);
      verify(() => mockMongo.getRecords('habitants')).called(1);
    });

    test('should return CacheFailure on local data source error', () async {
      when(() => mockNetwork.isConnected).thenAnswer((_) async => false);
      when(() => mockLocal.getHabitants()).thenThrow(Exception('Hive error'));

      final result = await repository.getHabitants('');

      expect(result.isLeft(), true);
      result.fold((l) => expect(l, isA<CacheFailure>()), (r) => null);
    });
  });

  group('addHabitante', () {
    test('should return ServerFailure on remote error', () async {
      when(() => mockNetwork.isConnected).thenAnswer((_) async => true);
      when(() => mockLocal.getHabitants()).thenAnswer((_) async => []);
      when(() => mockMongo.createRecord(any(), any())).thenThrow(Exception('Mongo error'));

      final result = await repository.addHabitante(tModel.toEntity());

      expect(result.isLeft(), true);
      result.fold((l) => expect(l, isA<ServerFailure>()), (r) => null);
    });

    test('should return CacheFailure on duplicate cédula', () async {
      when(() => mockLocal.getHabitants()).thenAnswer((_) async => [tModel]);

      final duplicate = Habitante(
        id: 'h2', cedula: '12345678', nombres: 'Otro', apellidos: '',
        telefono: '', sector: '', puntoReferencia: '',
        tieneDiscapacidad: false, tieneEnfermedadCronica: false,
        condicionVivienda: '', tipoVivienda: '',
        registeredBy: '', fechaRegistro: DateTime.now(),
      );

      final result = await repository.addHabitante(duplicate);

      expect(result.isLeft(), true);
      result.fold((l) => expect(l, isA<CacheFailure>()), (r) => null);
    });
  });
}
