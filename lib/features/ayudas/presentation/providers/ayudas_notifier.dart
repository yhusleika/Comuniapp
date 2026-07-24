import 'package:flutter/material.dart';
import '../../domain/entities/ayuda_type.dart';
import '../../../habitants/domain/entities/habitante.dart';

class AyudasNotifier extends ChangeNotifier {
  bool isAuditor;
  List<Habitante> _allHabitants = [];
  List<AyudaType> _ayudaTypes = [];
  List<Habitante> _filteredBeneficiaries = [];

  String _searchQuery = '';

  AyudasNotifier(List<Habitante> inhabitants, List<AyudaType> types, {required this.isAuditor}) {
    _allHabitants = inhabitants;
    _ayudaTypes = types;
    _applyFilters();
  }

  List<Habitante> get filteredBeneficiaries => _filteredBeneficiaries;
  List<AyudaType> get ayudaTypes => _ayudaTypes;
  String get searchQuery => _searchQuery;

  void updateSearch(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void _applyFilters() {
    _filteredBeneficiaries = _allHabitants.where((h) {
      // Only people with any aid different from 'Ninguna'
      if (h.ayudaRecibida == 'Ninguna' || h.ayudaRecibida.isEmpty) return false;

      final matchesSearch =
          h.nombres.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              h.apellidos.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              h.cedula.contains(_searchQuery);

      return matchesSearch;
    }).toList();
    notifyListeners();
  }

  void updateData(List<Habitante> inhabitants, List<AyudaType> types, {bool? isAuditor}) {
    if (isAuditor != null) {
      this.isAuditor = isAuditor;
    }
    _allHabitants = inhabitants;
    _ayudaTypes = types;
    _applyFilters();
  }

  BeneficiariesDataTableSource get dataSource => BeneficiariesDataTableSource(
        beneficiaries: _filteredBeneficiaries,
        ayudaTypes: _ayudaTypes,
        isAuditor: isAuditor,
      );
}

class BeneficiariesDataTableSource extends DataTableSource {
  final List<Habitante> beneficiaries;
  final List<AyudaType> ayudaTypes;
  final bool isAuditor;
  void Function(Habitante)? onEdit;

  BeneficiariesDataTableSource({
    required this.beneficiaries,
    required this.ayudaTypes,
    required this.isAuditor,
    this.onEdit,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= beneficiaries.length) return null;
    final h = beneficiaries[index];

    return DataRow(
      cells: [
        DataCell(Text(h.nombres)),
        DataCell(Text(h.cedula)),
        DataCell(_buildAidChip(h.ayudaRecibida)),
        DataCell(Text(
            '${h.fechaRegistro.day}/${h.fechaRegistro.month}/${h.fechaRegistro.year}')),
        if (!isAuditor)
          DataCell(IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => onEdit?.call(h),
          )),
      ],
    );
  }

  Widget _buildAidChip(String aid) {
    final List<String> aids = aid.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (aids.isEmpty) {
      return const Text('-');
    }
    
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: aids.map((a) {
        Color color;
        switch (a) {
          case 'Alimentación':
            color = Colors.green;
            break;
          case 'Medicinas':
            color = Colors.blue;
            break;
          case 'Vivienda':
            color = Colors.orange;
            break;
          default:
            color = Colors.indigo;
        }
        return Chip(
          label:
              Text(a, style: const TextStyle(color: Colors.white, fontSize: 11)),
          backgroundColor: color,
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => beneficiaries.length;

  @override
  int get selectedRowCount => 0;
}
