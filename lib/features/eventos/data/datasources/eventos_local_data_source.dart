import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/services/hive_config.dart';
import '../models/evento_model.dart';

abstract class EventosLocalDataSource {
  Future<List<EventoModel>> getEventos();
  Future<void> cacheEvento(EventoModel item);
  Future<void> updateEvento(EventoModel item);
  Future<void> deleteEvento(String id);
}

class EventosLocalDataSourceImpl implements EventosLocalDataSource {
  @override
  Future<List<EventoModel>> getEventos() async {
    final box = await Hive.openBox(HiveConfig.eventosBox);
    return box.values.cast<EventoModel>().toList();
  }

  @override
  Future<void> cacheEvento(EventoModel item) async {
    final box = await Hive.openBox(HiveConfig.eventosBox);
    await box.put(item.id, item);
  }

  @override
  Future<void> updateEvento(EventoModel item) async {
    final box = await Hive.openBox(HiveConfig.eventosBox);
    await box.put(item.id, item);
  }

  @override
  Future<void> deleteEvento(String id) async {
    final box = await Hive.openBox(HiveConfig.eventosBox);
    await box.delete(id);
  }
}
