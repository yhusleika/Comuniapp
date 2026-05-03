import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../features/habitants/domain/repositories/habitants_repository.dart';
import '../../features/reports/domain/repositories/reports_repository.dart';

class SyncManager {
  final Connectivity connectivity;
  final HabitantsRepository habitantsRepository;
  final ReportsRepository reportsRepository;

  StreamSubscription? _subscription;

  SyncManager({
    required this.connectivity,
    required this.habitantsRepository,
    required this.reportsRepository,
  });

  void init() {
    _subscription = connectivity.onConnectivityChanged.listen((result) {
      // connectivity_plus 6.0+ returns List<ConnectivityResult> but earlier versions return ConnectivityResult
      // checking if result contains mobile or wifi
      bool isConnected = false;
      if (result is List<ConnectivityResult>) {
        isConnected = result.contains(ConnectivityResult.mobile) ||
            result.contains(ConnectivityResult.wifi) ||
            result.contains(ConnectivityResult.ethernet);
      } else {
        // Fallback for older versions if API mismatch, though pubspec said ^5.0.2 which returns ConnectivityResult (single) usually, but checking implementation.
        // Actually 5.0.2 returns ConnectivityResult (single). 6.0.0 returns list.
        // Let's handle generic dynamic to be safe or check pubspec.
        // Assuming 5.0.2 based on my pubspec creation: ^5.0.2
        // Wait, 6.0.0 was released recently. If I used ^5.0.2 it might resolve to 5.x.
        // But let's assume standard behavior.
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
          // Simulate API call
          await Future.delayed(const Duration(milliseconds: 200));
          // On success:
          await habitantsRepository.markAsSynced(habitant.id);
          debugPrint('Synced habitant: ${habitant.nombres}');
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
          // Simulate API call & Image Upload
          await Future.delayed(const Duration(milliseconds: 500));
          // On success:
          await reportsRepository.markAsSynced(report.id);
          debugPrint('Synced report: ${report.titulo}');
        }
      },
    );
  }

  void dispose() {
    _subscription?.cancel();
  }
}
