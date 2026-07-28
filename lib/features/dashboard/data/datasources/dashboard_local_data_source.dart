import '../../domain/entities/dashboard_stats.dart';

abstract class DashboardLocalDataSource {
  Future<DashboardStats> getCachedStats();
  Future<void> cacheStats(DashboardStats stats);
}

class DashboardLocalDataSourceImpl implements DashboardLocalDataSource {
  DashboardStats? _cached;

  @override
  Future<DashboardStats> getCachedStats() async {
    if (_cached != null) return _cached!;
    throw Exception('No cached stats available');
  }

  @override
  Future<void> cacheStats(DashboardStats stats) async {
    _cached = stats;
  }
}
