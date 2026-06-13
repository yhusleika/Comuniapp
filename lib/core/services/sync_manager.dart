import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../features/habitants/domain/repositories/habitants_repository.dart';
import '../../features/habitants/data/models/habitante_model.dart';
import '../../features/reports/domain/repositories/reports_repository.dart';
import '../../features/reports/data/models/reporte_model.dart';
import 'mongodb_service.dart';

class SyncManager {
  final Connectivity connectivity;
  final HabitantsRepository habitantsRepository;
  final ReportsRepository reportsRepository;
  final MongoDBService mongoDBService;

  StreamSubscription? _subscription;

  SyncManager({
    required this.connectivity,
    required this.habitantsRepository,
    required this.reportsRepository,
    required this.mongoDBService,
  });

  void init() {
    _subscription = connectivity.onConnectivityChanged.listen((result) {
      bool isConnected = false;
      if (result is List<ConnectivityResult>) {
        isConnected = result.contains(ConnectivityResult.mobile) ||
            result.contains(ConnectivityResult.wifi) ||
            result.contains(ConnectivityResult.ethernet);
      } else {
        isConnected = result != ConnectivityResult.none;
      }

      if (isConnected) {
        syncData();
      }
    } as void Function(dynamic)?);
  }

  Future<void> syncData() async {
    debugPrint('Syncing data...');
    await _syncHabitants();
    await _syncReports();
    debugPrint('Sync complete.');
  }

  Future<void> _syncHabitants() async {
    final result = await habitantsRepository.getUnsyncedHabitants();
    result.fold(
      (failure) =>
          debugPrint('Error fetching unsynced habitants: ${failure.message}'),
      (habitants) async {
        for (final habitant in habitants) {
          final model = habitant as HabitanteModel;
          final success = await mongoDBService.createRecord('habitants', model.toJson());
          if (success) {
            await habitantsRepository.markAsSynced(habitant.id);
            debugPrint('Synced habitant to MongoDB: ${habitant.nombres}');
          }
        }
      },
    );
  }

  Future<void> _syncReports() async {
    final result = await reportsRepository.getUnsyncedReports();
    result.fold(
      (failure) =>
          debugPrint('Error fetching unsynced reports: ${failure.message}'),
      (reports) async {
        for (final report in reports) {
          final model = report as ReporteModel;
          final success = await mongoDBService.createRecord('reports', model.toJson());
          if (success) {
            await reportsRepository.markAsSynced(report.id);
            debugPrint('Synced report to MongoDB: ${report.titulo}');
          }
        }
      },
    );
  }

  void dispose() {
    _subscription?.cancel();
  }
}
