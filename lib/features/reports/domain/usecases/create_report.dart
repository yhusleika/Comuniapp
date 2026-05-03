import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/reporte.dart';
import '../repositories/reports_repository.dart';

class CreateReport implements UseCase<void, CreateReportParams> {
  final ReportsRepository repository;

  CreateReport(this.repository);

  @override
  Future<Either<Failure, void>> call(CreateReportParams params) async {
    return await repository.createReporte(params.reporte);
  }
}

class CreateReportParams extends Equatable {
  final Reporte reporte;

  const CreateReportParams({required this.reporte});

  @override
  List<Object> get props => [reporte];
}
