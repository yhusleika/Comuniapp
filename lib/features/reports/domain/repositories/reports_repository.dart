import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/reporte.dart';

abstract class ReportsRepository {
  Future<Either<Failure, List<Reporte>>> getReports();
  Future<Either<Failure, void>> createReporte(Reporte reporte);
  Future<Either<Failure, List<Reporte>>> getUnsyncedReports();
  Future<Either<Failure, void>> markAsSynced(String id);
}
