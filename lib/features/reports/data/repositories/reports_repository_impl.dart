import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/reporte.dart';
import '../../domain/repositories/reports_repository.dart';
import '../datasources/reports_local_data_source.dart';
import '../models/reporte_model.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  ReportsRepositoryImpl({
    required this.localDataSource,
    required this.networkInfo,
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
      final model = ReporteModel.fromEntity(reporte);
      await localDataSource.cacheReporte(model);
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
