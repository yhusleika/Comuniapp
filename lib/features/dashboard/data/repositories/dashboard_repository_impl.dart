import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_local_data_source.dart';
import '../datasources/dashboard_remote_data_source.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;
  final DashboardLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  DashboardRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, DashboardStats>> getStats() async {
    try {
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        try {
          final remoteStats = await remoteDataSource.getStats();
          await localDataSource.cacheStats(remoteStats);
          return Right(remoteStats);
        } catch (e) {
          return Left(ServerFailure(e.toString()));
        }
      }
      final cached = await localDataSource.getCachedStats();
      return Right(cached);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
