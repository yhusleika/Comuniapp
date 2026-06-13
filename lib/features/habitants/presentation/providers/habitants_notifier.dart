import 'package:flutter/material.dart';
import '../../domain/entities/habitante.dart';

class HabitantsNotifier extends ChangeNotifier {
  final bool isAuditor;
  List<Habitante> _allHabitants = [];
  List<Habitante> _filteredHabitants = [];

  String _searchQuery = '';
  String _selectedZone = 'Todas';
  String _selectedAid = 'Todas';

  HabitantsNotifier(List<Habitante> initialHabitants, {required this.isAuditor}) {
    _allHabitants = initialHabitants;
    _filteredHabitants = initialHabitants;
  }

  List<Habitante> get filteredHabitants => _filteredHabitants;
  String get searchQuery => _searchQuery;
  String get selectedZone => _selectedZone;
  String get selectedAid => _selectedAid;

  void updateSearch(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void updateZone(String? zone) {
    _selectedZone = zone ?? 'Todas';
    _applyFilters();
  }

  void updateAid(String? aid) {
    _selectedAid = aid ?? 'Todas';
    _applyFilters();
  }

  void _applyFilters() {
    _filteredHabitants = _allHabitants.where((h) {
      final matchesSearch =
          h.nombres.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              h.apellidos.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              h.cedula.contains(_searchQuery);
      final matchesZone = _selectedZone == 'Todas' || h.sector == _selectedZone;
      final matchesAid =
          _selectedAid == 'Todas' || h.ayudaRecibida == _selectedAid;

      return matchesSearch && matchesZone && matchesAid;
    }).toList();
    notifyListeners();
  }

  HabitanteDataTableSource get dataSource => HabitanteDataTableSource(
        habitants: _filteredHabitants,
        isAuditor: isAuditor,
      );
}

class HabitanteDataTableSource extends DataTableSource {
  final List<Habitante> habitants;
  final bool isAuditor;
  void Function(Habitante)? onEdit;
  void Function(String)? onDelete;

  HabitanteDataTableSource({
    required this.habitants,
    required this.isAuditor,
    this.onEdit,
    this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= habitants.length) return null;
    final h = habitants[index];

    return DataRow(
      cells: [
        DataCell(Text(h.nombres)),
        DataCell(Text(h.apellidos)),
        DataCell(Text(h.cedula)),
        DataCell(Text(h.sector)),
        DataCell(Text(h.ayudaRecibida.isEmpty ? 'Ninguna' : h.ayudaRecibida)),
        if (!isAuditor)
          DataCell(Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => onEdit?.call(h),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => onDelete?.call(h.id),
              ),
            ],
          )),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => habitants.length;

  @override
  int get selectedRowCount => 0;
}
