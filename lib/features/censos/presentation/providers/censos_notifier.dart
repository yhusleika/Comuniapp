import 'package:flutter/material.dart';
import '../bloc/censos_bloc.dart';
import '../bloc/censos_event.dart';
import '../../domain/entities/censo.dart';
import '../../domain/entities/censo_record.dart';

class CensosNotifier extends ChangeNotifier {
  List<Censo> _allCensos = [];
  List<CensoRecord> _allRecords = [];
  List<CensoRecord> _filteredRecords = [];

  Censo? _selectedCenso;
  String _searchQuery = '';
  String _statusFilter =
      'Todos'; // Todos, Censados, Pendientes, Casos Especiales

  List<Censo> get censos => _allCensos;
  List<CensoRecord> get records => _allRecords;
  List<CensoRecord> get filteredRecords => _filteredRecords;
  Censo? get selectedCenso => _selectedCenso;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;

  void updateCensos(List<Censo> censos) {
    _allCensos = censos;
    if (censos.isEmpty) {
      _selectedCenso = null;
    } else if (_selectedCenso == null || !censos.any((c) => c.id == _selectedCenso!.id)) {
      _selectedCenso = censos.first;
    }
    notifyListeners();
  }

  void updateRecords(List<CensoRecord> records) {
    _allRecords = records;
    _applyFilters();
  }

  void selectCenso(Censo? censo) {
    _selectedCenso = censo;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setStatusFilter(String filter) {
    _statusFilter = filter;
    _applyFilters();
  }

  void _applyFilters() {
    _filteredRecords = _allRecords.where((r) {
      final matchesSearch =
          r.jefeFamilia.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              r.cedula.contains(_searchQuery);

      final matchesStatus =
          _statusFilter == 'Todos' || r.estatus == _statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();
    notifyListeners();
  }
}

class FamilyRecordsDataTableSource extends DataTableSource {
  final List<CensoRecord> records;
  final Function(CensoRecord) onEdit;
  final Function(CensoRecord) onDelete;
  final BuildContext context;
  final bool canEdit;
  final bool canDelete;

  FamilyRecordsDataTableSource({
    required this.records,
    required this.onEdit,
    required this.onDelete,
    required this.context,
    this.canEdit = true,
    this.canDelete = true,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= records.length) return null;
    final record = records[index];

    return DataRow(cells: [
      DataCell(Text(record.numEncuesta?.toString() ?? (index + 1).toString())),
      DataCell(Text(record.jefeFamilia)),
      DataCell(Text(record.cedula)),
      DataCell(Text(record.direccion)),
      if (canEdit || canDelete)
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canEdit)
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => onEdit(record),
              ),
            if (canDelete)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => onDelete(record),
              ),
          ],
        )),
    ]);
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Censados':
        color = Colors.green;
        break;
      case 'Pendientes':
        color = Colors.orange;
        break;
      case 'Casos Especiales':
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => records.length;

  @override
  int get selectedRowCount => 0;
}
