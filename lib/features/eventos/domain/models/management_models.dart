class Avance {
  final String descripcion;
  final DateTime fecha;
  final List<String> fotos;
  final double progress;

  Avance({
    required this.descripcion,
    required this.fecha,
    this.fotos = const [],
    this.progress = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'descripcion': descripcion,
    'fecha': fecha.toIso8601String(),
    'fotos': fotos,
    'progress': progress,
  };

  factory Avance.fromJson(Map<String, dynamic> json) => Avance(
    descripcion: json['descripcion'] ?? '',
    fecha: json['fecha'] != null ? DateTime.parse(json['fecha'].toString()) : DateTime.now(),
    fotos: List<String>.from(json['fotos'] ?? []),
    progress: (json['progress'] ?? 0.0).toDouble(),
  );
}

class ManagementItem {
  final String id;
  final String name;
  final DateTime date;
  final String description;
  final String responsible;
  final String category; // 'Eventos', 'Proyectos', 'Jornadas'
  final double progress; // 0.0 to 1.0
  final String status; // 'Pendiente', 'En Proceso', 'Completado'
  final List<String> attendeeNames;
  final List<String> photos;
  final List<Avance> avances;
  final bool isSynced;

  ManagementItem({
    required this.id,
    required this.name,
    required this.date,
    required this.description,
    required this.responsible,
    required this.category,
    this.progress = 0.0,
    this.status = 'Pendiente',
    this.attendeeNames = const [],
    this.photos = const [],
    this.avances = const [],
    this.isSynced = false,
  });

  ManagementItem copyWith({
    String? id,
    String? name,
    DateTime? date,
    String? description,
    String? responsible,
    String? category,
    double? progress,
    String? status,
    List<String>? attendeeNames,
    List<String>? photos,
    List<Avance>? avances,
    bool? isSynced,
  }) {
    return ManagementItem(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      description: description ?? this.description,
      responsible: responsible ?? this.responsible,
      category: category ?? this.category,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      attendeeNames: attendeeNames ?? this.attendeeNames,
      photos: photos ?? this.photos,
      avances: avances ?? this.avances,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

class ManagementRecord {
  final String id;
  final String itemId;
  final String field1;
  final String field2;
  final String field3;
  final DateTime date;

  ManagementRecord({
    required this.id,
    required this.itemId,
    required this.field1,
    required this.field2,
    required this.field3,
    required this.date,
  });

  ManagementRecord copyWith({
    String? id,
    String? itemId,
    String? field1,
    String? field2,
    String? field3,
    DateTime? date,
  }) {
    return ManagementRecord(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      field1: field1 ?? this.field1,
      field2: field2 ?? this.field2,
      field3: field3 ?? this.field3,
      date: date ?? this.date,
    );
  }
}
