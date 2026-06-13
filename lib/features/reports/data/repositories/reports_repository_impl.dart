import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/mongodb_service.dart';
import '../../domain/entities/reporte.dart';
import '../../domain/repositories/reports_repository.dart';
import '../datasources/reports_local_data_source.dart';
import '../models/reporte_model.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final MongoDBService mongoDBService;

  ReportsRepositoryImpl({
    required this.localDataSource,
    required this.networkInfo,
    required this.mongoDBService,
  });

  @override
  Future<Either<Failure, List<Reporte>>> getReports() async {
    try {
      final reports = await localDataSource.getReports();
      return Right(reports);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createReporte(Reporte reporte) async {
    try {
      final isConnected = await networkInfo.isConnected;
      bool apiSynced = false;
      
      final model = ReporteModel.fromEntity(reporte);
      
      if (isConnected) {
        apiSynced = await mongoDBService.createRecord('reports', model.toJson());
      }
      
      final cacheModel = ReporteModel(
        id: model.id,
        titulo: model.titulo,
        descripcion: model.descripcion,
        tipo: model.tipo,
        prioridad: model.prioridad,
        estatus: model.estatus,
        fotosPaths: model.fotosPaths,
        latitud: model.latitud,
        longitud: model.longitud,
        createdBy: model.createdBy,
        fechaRegistro: model.fechaRegistro,
        isSynced: apiSynced,
      );
      
      await localDataSource.cacheReporte(cacheModel);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Reporte>>> getUnsyncedReports() async {
    try {
      final reports = await localDataSource.getReports();
      return Right(reports.where((element) => !element.isSynced).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAsSynced(String id) async {
    try {
      final reports = await localDataSource.getReports();
      final index = reports.indexWhere((r) => r.id == id);
      if (index != -1) {
        final reporte = reports[index];
        final updated = ReporteModel(
          id: reporte.id,
          titulo: reporte.titulo,
          descripcion: reporte.descripcion,
          tipo: reporte.tipo,
          prioridad: reporte.prioridad,
          estatus: reporte.estatus,
          fotosPaths: reporte.fotosPaths,
          latitud: reporte.latitud,
          longitud: reporte.longitud,
          createdBy: reporte.createdBy,
          fechaRegistro: reporte.fechaRegistro,
          isSynced: true,
        );
        await localDataSource.cacheReporte(updated);
      }
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
