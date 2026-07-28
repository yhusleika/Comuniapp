import 'package:flutter/material.dart';
import '../../domain/entities/habitante.dart';

class HabitantsNotifier extends ChangeNotifier {
  bool canEdit;
  bool canDelete;
  List<Habitante> _allHabitants = [];
  List<Habitante> _filteredHabitants = [];

  String _searchQuery = '';
  String _selectedZone = 'Todas';
  String _selectedAid = 'Todas';

  HabitantsNotifier(List<Habitante> initialHabitants, {required this.canEdit, required this.canDelete}) {
    _allHabitants = initialHabitants;
    _applyFilters(notify: false);
  }

  List<Habitante> get filteredHabitants => _filteredHabitants;
  String get searchQuery => _searchQuery;
  String get selectedZone => _selectedZone;
  String get selectedAid => _selectedAid;

  void updateHabitants(List<Habitante> newHabitants, {required bool canEdit, required bool canDelete}) {
    this.canEdit = canEdit;
    this.canDelete = canDelete;
    _allHabitants = newHabitants;
    _applyFilters(notify: false);
  }

  void updateSearch(String query) {
    _searchQuery = query;
    _applyFilters(notify: true);
  }

  void updateZone(String? zone) {
    _selectedZone = zone ?? 'Todas';
    _applyFilters(notify: true);
  }

  void updateAid(String? aid) {
    _selectedAid = aid ?? 'Todas';
    _applyFilters(notify: true);
  }

  void _applyFilters({bool notify = true}) {
    _filteredHabitants = _allHabitants.where((h) {
      final matchesSearch =
          h.nombres.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              h.apellidos.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              h.cedula.contains(_searchQuery);
      final matchesZone = _selectedZone == 'Todas' || h.sector == _selectedZone;
      final List<String> aids = h.ayudaRecibida.split(',').map((e) => e.trim()).toList();
      final matchesAid =
          _selectedAid == 'Todas' || aids.contains(_selectedAid);

      return matchesSearch && matchesZone && matchesAid;
    }).toList();
    if (notify) {
      notifyListeners();
    }
  }

  HabitanteDataTableSource get dataSource => HabitanteDataTableSource(
        habitants: _filteredHabitants,
        canEdit: canEdit,
        canDelete: canDelete,
      );
}

class HabitanteDataTableSource extends DataTableSource {
  final List<Habitante> habitants;
  final bool canEdit;
  final bool canDelete;
  void Function(Habitante)? onEdit;
  void Function(String)? onDelete;

  HabitanteDataTableSource({
    required this.habitants,
    required this.canEdit,
    required this.canDelete,
    this.onEdit,
    this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= habitants.length) return null;
    final h = habitants[index];

    final birthDate = h.fechaNacimiento;
    String ageText = '-';
    if (birthDate != null) {
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      ageText = '$age';
    }

    final hasActions = canEdit || canDelete;

    return DataRow(
      cells: [
        DataCell(Text(h.nombres)),
        DataCell(Text(h.apellidos)),
        DataCell(Text(h.cedula)),
        DataCell(Text(ageText)),
        DataCell(Text(h.sector)),
        DataCell(Text(h.ayudaRecibida.isEmpty ? 'Ninguna' : h.ayudaRecibida)),
        if (hasActions)
          DataCell(Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canEdit)
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => onEdit?.call(h),
                ),
              if (canDelete)
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
