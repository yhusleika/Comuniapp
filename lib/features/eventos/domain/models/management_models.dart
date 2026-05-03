class ManagementItem {
  final String id;
  final String name;
  final DateTime date;
  final String description;
  final String responsible;
  final String category; // 'Eventos', 'Proyectos', 'Jornadas'
  final double progress; // 0.0 to 1.0
  final String status; // 'Pendiente', 'En Proceso', 'Completado'

  ManagementItem({
    required this.id,
    required this.name,
    required this.date,
    required this.description,
    required this.responsible,
    required this.category,
    this.progress = 0.0,
    this.status = 'Pendiente',
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
