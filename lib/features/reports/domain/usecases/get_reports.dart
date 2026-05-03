import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/reporte.dart';
import '../repositories/reports_repository.dart';

class GetReports implements UseCase<List<Reporte>, NoParams> {
  final ReportsRepository repository;

  GetReports(this.repository);

  @override
  Future<Either<Failure, List<Reporte>>> call(NoParams params) async {
    return await repository.getReports();
  }
}
