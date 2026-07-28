import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  final Map<String, int> counts;
  final List<DashboardActivity> recentActivity;
  final List<DashboardEvent> eventos;

  const DashboardStats({
    required this.counts,
    this.recentActivity = const [],
    this.eventos = const [],
  });

  List<DashboardEvent> get proyectos =>
      eventos.where((e) => e.category == 'Proyectos').toList();

  @override
  List<Object?> get props => [counts, recentActivity, eventos];
}

class DashboardActivity extends Equatable {
  final String type;
  final String title;
  final String? subtitle;
  final DateTime date;

  const DashboardActivity({
    required this.type,
    required this.title,
    this.subtitle,
    required this.date,
  });

  @override
  List<Object?> get props => [type, title, subtitle, date];
}

class DashboardEvent extends Equatable {
  final String id;
  final String name;
  final String category;
  final String status;
  final String? responsible;
  final DateTime createdAt;

  const DashboardEvent({
    required this.id,
    required this.name,
    this.category = '',
    this.status = 'Pendiente',
    this.responsible,
    required this.createdAt,
  });

  @override
  List<Object?> get props =>
      [id, name, category, status, responsible, createdAt];
}
