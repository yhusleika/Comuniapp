import 'package:hive/hive.dart';
import '../../domain/models/management_models.dart';

part 'evento_model.g.dart';

@HiveType(typeId: 8)
class EventoModel extends ManagementItem {
  @HiveField(0)
  @override
  final String id;

  @HiveField(1)
  @override
  final String name;

  @HiveField(2)
  @override
  final DateTime date;

  @HiveField(3)
  @override
  final String description;

  @HiveField(4)
  @override
  final String responsible;

  @HiveField(5)
  @override
  final String category;

  @HiveField(6)
  @override
  final double progress;

  @HiveField(7)
  @override
  final String status;

  @HiveField(8)
  @override
  final List<String> attendeeNames;

  @HiveField(9)
  @override
  final List<String> photos;

  @HiveField(10)
  @override
  final bool isSynced;

  @HiveField(11)
  final List<Map<dynamic, dynamic>> avancesRaw;

  @override
  List<Avance> get avances => avancesRaw
      .map((m) => Avance.fromJson(Map<String, dynamic>.from(m)))
      .toList();

  EventoModel({
    required this.id,
    required this.name,
    required this.date,
    required this.description,
    required this.responsible,
    required this.category,
    required this.progress,
    required this.status,
    required this.attendeeNames,
    required this.photos,
    this.avancesRaw = const [],
    this.isSynced = false,
  }) : super(
          id: id,
          name: name,
          date: date,
          description: description,
          responsible: responsible,
          category: category,
          progress: progress,
          status: status,
          attendeeNames: attendeeNames,
          photos: photos,
          avances: const [],
          isSynced: isSynced,
        );

  factory EventoModel.fromEntity(ManagementItem entity) {
    return EventoModel(
      id: entity.id,
      name: entity.name,
      date: entity.date,
      description: entity.description,
      responsible: entity.responsible,
      category: entity.category,
      progress: entity.progress,
      status: entity.status,
      attendeeNames: entity.attendeeNames,
      photos: entity.photos,
      avancesRaw: entity.avances.map((a) => a.toJson()).toList(),
      isSynced: entity.isSynced,
    );
  }

  ManagementItem toEntity() {
    return ManagementItem(
      id: id,
      name: name,
      date: date,
      description: description,
      responsible: responsible,
      category: category,
      progress: progress,
      status: status,
      attendeeNames: attendeeNames,
      photos: photos,
      avances: avances,
      isSynced: isSynced,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
      'description': description,
      'responsible': responsible,
      'category': category,
      'progress': progress,
      'status': status,
      'attendeeNames': attendeeNames,
      'photos': photos,
      'avances': avancesRaw,
      'isSynced': isSynced,
    };
  }

  factory EventoModel.fromJson(Map<String, dynamic> json) {
    return EventoModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: json['name'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      description: json['description'] ?? '',
      responsible: json['responsible'] ?? '',
      category: json['category'] ?? '',
      progress: (json['progress'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'Pendiente',
      attendeeNames: List<String>.from(json['attendeeNames'] ?? []),
      photos: List<String>.from(json['photos'] ?? []),
      avancesRaw: (json['avances'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ?? [],
      isSynced: true,
    );
  }
}
