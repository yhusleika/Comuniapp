import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../features/habitants/domain/repositories/habitants_repository.dart';
import '../../features/habitants/data/models/habitante_model.dart';
import '../../features/reports/domain/repositories/reports_repository.dart';
import '../../features/reports/data/models/reporte_model.dart';
import '../../features/censos/domain/repositories/censos_repository.dart';
import '../../features/censos/data/models/censo_model.dart';
import '../../features/censos/data/models/censo_record_model.dart';
import '../../features/auditoria/domain/repositories/auditoria_repository.dart';
import '../../features/auditoria/data/models/audit_log_model.dart';
import '../../features/eventos/domain/repositories/eventos_repository.dart';
import '../../features/eventos/data/models/evento_model.dart';
import 'mongodb_service.dart';

enum SyncStateEnum { idle, syncing, synced, offline }

class SyncManager extends ChangeNotifier {
  final Connectivity connectivity;
  final HabitantsRepository habitantsRepository;
  final ReportsRepository reportsRepository;
  final CensosRepository censosRepository;
  final AuditoriaRepository auditoriaRepository;
  final EventosRepository eventosRepository;
  final MongoDBService mongoDBService;

  StreamSubscription? _subscription;
  Timer? _hideTimer;

  SyncStateEnum _state = SyncStateEnum.idle;
  String _message = '';
  bool _isOffline = false;

  SyncStateEnum get state => _state;
  String get message => _message;

  SyncManager({
    required this.connectivity,
    required this.habitantsRepository,
    required this.reportsRepository,
    required this.censosRepository,
    required this.auditoriaRepository,
    required this.eventosRepository,
    required this.mongoDBService,
  });

  void _setStatus(SyncStateEnum newState, String newMsg, {int? autoHideSeconds}) {
    _hideTimer?.cancel();
    _state = newState;
    _message = newMsg;
    notifyListeners();

    if (autoHideSeconds != null) {
      _hideTimer = Timer(Duration(seconds: autoHideSeconds), () {
        _state = SyncStateEnum.idle;
        _message = '';
        notifyListeners();
      });
    }
  }

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

      if (!isConnected) {
        _isOffline = true;
        _setStatus(
          SyncStateEnum.offline,
          'Modo Offline — Los cambios se guardarán localmente',
          autoHideSeconds: 5,
        );
      } else {
        if (_isOffline) {
          _isOffline = false;
        }
        syncData();
      }
    } as void Function(dynamic)?);
  }

  Future<void> syncData() async {
    // Sincronizando: se mantiene activo sin temporizador hasta que termine
    _setStatus(
      SyncStateEnum.syncing,
      'Sincronizando con la base de datos...',
    );

    try {
      await _syncHabitants();
      await _syncReports();
      await _syncCensos();
      await _syncCensoRecords();
      await _syncDeletedCensos();
      await _syncAuditLogs();
      await _syncEventos();

      // Al terminar: pasa a Sincronizado y dura exactamente 5 segundos
      _setStatus(
        SyncStateEnum.synced,
        'Base de datos sincronizada',
        autoHideSeconds: 5,
      );
    } catch (e) {
      debugPrint('Sync error: $e');
      if (_isOffline) {
        _setStatus(
          SyncStateEnum.offline,
          'Modo Offline — Los cambios se guardarán localmente',
          autoHideSeconds: 5,
        );
      } else {
        _setStatus(
          SyncStateEnum.synced,
          'Base de datos sincronizada',
          autoHideSeconds: 5,
        );
      }
    }
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

  Future<void> _syncCensos() async {
    final result = await censosRepository.getUnsyncedCensos();
    result.fold(
      (failure) => debugPrint('Error fetching unsynced censos: ${failure.message}'),
      (censos) async {
        for (final censo in censos) {
          final model = CensoModel.fromEntity(censo);
          final success = await mongoDBService.createRecord('censos', model.toJson());
          if (success) {
            await censosRepository.markCensoAsSynced(censo.id);
            debugPrint('Synced censo to MongoDB: ${censo.nombre}');
          }
        }
      },
    );
  }

  Future<void> _syncCensoRecords() async {
    final result = await censosRepository.getUnsyncedCensoRecords();
    result.fold(
      (failure) => debugPrint('Error fetching unsynced censo records: ${failure.message}'),
      (records) async {
        for (final record in records) {
          final model = CensoRecordModel.fromEntity(record);
          final success = await mongoDBService.createRecord('censo_records', model.toJson());
          if (success) {
            await censosRepository.markCensoRecordAsSynced(record.id);
            debugPrint('Synced censo record to MongoDB: ${record.jefeFamilia}');
          }
        }
      },
    );
  }

  Future<void> _syncAuditLogs() async {
    final result = await auditoriaRepository.getUnsyncedAuditLogs();
    result.fold(
      (failure) => debugPrint('Error fetching unsynced audit logs: ${failure.message}'),
      (logs) async {
        for (final log in logs) {
          final model = AuditLogModel.fromEntity(log);
          final success = await mongoDBService.createRecord('auditoria', model.toJson());
          if (success) {
            await auditoriaRepository.markAuditLogAsSynced(log.id);
            debugPrint('Synced audit log to MongoDB: ${log.action}');
          }
        }
      },
    );
  }

  Future<void> _syncEventos() async {
    final result = await eventosRepository.getUnsyncedEventos();
    result.fold(
      (failure) => debugPrint('Error fetching unsynced eventos: ${failure.message}'),
      (items) async {
        for (final item in items) {
          final model = EventoModel.fromEntity(item);
          final success = await mongoDBService.createRecord('eventos', model.toJson());
          if (success) {
            await eventosRepository.markEventoAsSynced(item.id);
            debugPrint('Synced evento to MongoDB: ${item.name}');
          }
        }
      },
    );
  }

  Future<void> _syncDeletedCensos() async {
    final result = await censosRepository.getDeletedCensoIds();
    result.fold(
      (failure) => debugPrint('Error fetching deleted censo ids: ${failure.message}'),
      (ids) async {
        for (final id in ids) {
          try {
            await mongoDBService.deleteRecord('censos', id);
            await censosRepository.clearDeletedCensoId(id);
            debugPrint('Synced deleted censo to MongoDB: $id');
          } catch (e) {
            debugPrint('Error syncing deleted censo $id: $e');
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }
}
