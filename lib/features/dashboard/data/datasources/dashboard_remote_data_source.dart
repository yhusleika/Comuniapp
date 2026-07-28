import '../../../../core/services/mongodb_service.dart';
import '../../domain/entities/dashboard_stats.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardStats> getStats();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final MongoDBService mongoDBService;

  DashboardRemoteDataSourceImpl({required this.mongoDBService});

  @override
  Future<DashboardStats> getStats() async {
    final data = await mongoDBService.getStats();
    final eventosData = await mongoDBService.getRecords('eventos');

    final counts = data['counts'] as Map<String, dynamic>? ?? {};
    final recentActivityRaw = data['recentActivity'] as List<dynamic>? ?? [];

    return DashboardStats(
      counts: {
        'Habitantes': counts['habitants'] ?? 0,
        'Ayudas': counts['ayudas'] ?? 0,
        'Censos': counts['censos'] ?? 0,
        'Eventos': counts['eventos'] ?? 0,
      },
      recentActivity: recentActivityRaw.take(10).map((act) {
        return DashboardActivity(
          type: act['type'] ?? 'info',
          title: act['title'] ?? '',
          subtitle: act['subtitle'],
          date: DateTime.tryParse(act['date'] ?? '') ?? DateTime.now(),
        );
      }).toList(),
      eventos: eventosData.map((e) {
        return DashboardEvent(
          id: e['id'] ?? e['_id'] ?? '',
          name: e['name'] ?? e['title'] ?? '',
          category: e['category'] ?? '',
          status: e['status'] ?? 'Pendiente',
          responsible: e['responsible'],
          createdAt:
              DateTime.tryParse(e['createdAt'] ?? '') ?? DateTime.now(),
        );
      }).toList(),
    );
  }
}
