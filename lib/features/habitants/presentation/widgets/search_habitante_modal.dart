import 'package:flutter/material.dart';
import '../../domain/entities/habitante.dart';

/// A reusable modal for searching and selecting habitants across all modules.
/// Supports multi-select mode for selecting multiple habitants (e.g. event attendees)
/// or single-select mode for selecting a single beneficiary (e.g. ayuda assignment).
///
/// Usage:
/// ```dart
/// final selected = await SearchHabitanteModal.show(
///   context: context,
///   allHabitants: habitants,
///   multiSelect: true,
///   alreadySelected: existingSelections,
/// );
/// ```
class SearchHabitanteModal extends StatefulWidget {
  final List<Habitante> allHabitants;
  final bool multiSelect;
  final List<Habitante> alreadySelected;
  final VoidCallback? onRegisterNew;

  const SearchHabitanteModal({
    super.key,
    required this.allHabitants,
    this.multiSelect = true,
    this.alreadySelected = const [],
    this.onRegisterNew,
  });

  /// Shows the modal and returns the selected habitants.
  /// Returns null if dismissed without selection.
  static Future<List<Habitante>?> show({
    required BuildContext context,
    required List<Habitante> allHabitants,
    bool multiSelect = true,
    List<Habitante> alreadySelected = const [],
    VoidCallback? onRegisterNew,
  }) {
    return showModalBottomSheet<List<Habitante>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SearchHabitanteModal(
        allHabitants: allHabitants,
        multiSelect: multiSelect,
        alreadySelected: alreadySelected,
        onRegisterNew: onRegisterNew,
      ),
    );
  }

  @override
  State<SearchHabitanteModal> createState() => _SearchHabitanteModalState();
}

class _SearchHabitanteModalState extends State<SearchHabitanteModal> {
  final _searchController = TextEditingController();
  List<Habitante> _results = [];
  final List<Habitante> _selected = [];

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.alreadySelected);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }
    final q = query.toLowerCase();
    final filtered = widget.allHabitants.where((h) {
      final nameMatch = h.nombres.toLowerCase().contains(q) ||
          h.apellidos.toLowerCase().contains(q);
      final cedulaMatch = h.cedula.toLowerCase().contains(q);
      return nameMatch || cedulaMatch;
    }).toList();
    setState(() => _results = filtered);
  }

  bool _isSelected(Habitante h) => _selected.any((s) => s.id == h.id);

  void _toggle(Habitante h) {
    setState(() {
      if (_isSelected(h)) {
        _selected.removeWhere((s) => s.id == h.id);
      } else {
        if (!widget.multiSelect) {
          // Single-select: replace
          _selected.clear();
        }
        _selected.add(h);
        if (!widget.multiSelect) {
          // Immediately return in single-select mode
          Navigator.pop(context, _selected);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    debugPrint('SearchHabitanteModal: widget.allHabitants count: ${widget.allHabitants.length}');
    return Material(
      color: Colors.transparent,
      child: Container(
        height: size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.multiSelect
                      ? 'Seleccionar Habitantes'
                      : 'Buscar Habitante',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (widget.multiSelect)
                  TextButton(
                    onPressed: () => Navigator.pop(context, _selected),
                    child: Text(
                      'Listo (${_selected.length})',
                      style: const TextStyle(
                        color: Color(0xFF416FDF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              autofocus: true,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, apellido o cédula...',
                hintStyle: const TextStyle(color: Colors.black38),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF416FDF)),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF416FDF)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Selected chips (multiselect mode)
          if (widget.multiSelect && _selected.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _selected.map((h) {
                  return Chip(
                    backgroundColor: const Color(0x1A416FDF),
                    side: const BorderSide(color: Color(0xFF416FDF), width: 0.5),
                    label: Text(
                      '${h.nombres} ${h.apellidos}',
                      style: const TextStyle(color: Color(0xFF416FDF), fontSize: 12),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16, color: Color(0xFF416FDF)),
                    onDeleted: () => _toggle(h),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ),

          const Divider(height: 1, color: Colors.black12),

          // Results
          Expanded(
            child: widget.allHabitants.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text(
                          'No hay habitantes registrados',
                          style: TextStyle(color: Colors.black54, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : (_searchController.text.isNotEmpty && _results.isEmpty)
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text(
                              'No se encontraron resultados',
                              style: TextStyle(color: Colors.black54, fontSize: 14),
                            ),
                            const SizedBox(height: 16),
                            if (widget.onRegisterNew != null)
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  widget.onRegisterNew!();
                                },
                                icon: const Icon(Icons.person_add, color: Color(0xFF416FDF)),
                                label: const Text(
                                  'Registrar Nuevo Habitante',
                                  style: TextStyle(color: Color(0xFF416FDF)),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF416FDF)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _searchController.text.isEmpty ? widget.allHabitants.length : _results.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 72, color: Colors.black12),
                        itemBuilder: (context, index) {
                          final h = _searchController.text.isEmpty ? widget.allHabitants[index] : _results[index];
                          final selected = _isSelected(h);
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: selected
                                  ? const Color(0xFF416FDF)
                                  : Colors.grey.shade200,
                              child: Icon(
                                selected ? Icons.check : Icons.person,
                                color: selected ? Colors.white : Colors.grey.shade600,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              '${h.nombres} ${h.apellidos}',
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              'Cédula: ${h.cedula} • ${h.sector}',
                              style: const TextStyle(color: Colors.black54, fontSize: 12),
                            ),
                            trailing: selected
                                ? const Icon(Icons.check_circle, color: Color(0xFF416FDF))
                                : const Icon(Icons.add_circle_outline, color: Colors.grey),
                            onTap: () => _toggle(h),
                          );
                        },
                      ),
          ),
        ],
      ),
    ));
  }
}
