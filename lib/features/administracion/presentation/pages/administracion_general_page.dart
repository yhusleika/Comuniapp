import 'dart:math';
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:hive/hive.dart';
import '../../../../shared/widgets/custom_scaffold.dart';
import '../../../../shared/widgets/side_menu.dart';
import '../../../../core/services/mongodb_service.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/user_roles_helper.dart';
import '../../../../core/services/audit_logger_service.dart';
import '../../../censos/domain/entities/censo_fields_dictionary.dart';
import '../../../../core/services/hive_config.dart';
import '../../../habitantes/data/models/habitante_model.dart';

class SystemUser {
  final String id;
  final String username;
  final String name;
  final String email;
  final String role; // 'Administrador', 'Operador', 'Visor'
  final String status; // 'Activo', 'Bloqueado'
  final String password;
  final String cedula;
  final String telefono;

  SystemUser({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.password,
    this.cedula = '',
    this.telefono = '',
  });

  SystemUser copyWith({
    String? id,
    String? username,
    String? name,
    String? email,
    String? role,
    String? status,
    String? password,
    String? cedula,
    String? telefono,
  }) {
    return SystemUser(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      password: password ?? this.password,
      cedula: cedula ?? this.cedula,
      telefono: telefono ?? this.telefono,
    );
  }
}

class SectorItem {
  final String id;
  final String nombre;
  final String descripcion;
  final int totalHabitantes;

  SectorItem({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.totalHabitantes,
  });
}

class SystemRole {
  final String name;
  final String description;
  final List<String> permissions;

  const SystemRole({
    required this.name,
    required this.description,
    required this.permissions,
  });
}

class AdministracionGeneralPage extends StatefulWidget {
  const AdministracionGeneralPage({super.key});

  @override
  State<AdministracionGeneralPage> createState() => _AdministracionGeneralPageState();
}

class _AdministracionGeneralPageState extends State<AdministracionGeneralPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final List<SystemUser> _users = [];
  final List<SectorItem> _sectores = [];
  bool _isLoadingUsers = true;

  static const List<SystemRole> _staticRoles = [
    SystemRole(
      name: 'Administrador',
      description: 'Acceso total y control absoluto de la plataforma y administración.',
      permissions: [
        'Crear, Editar y Eliminar en todos los módulos',
        'Gestión de Usuarios y Sectores',
        'Configuración de Sistema',
        'Auditoría y Logs Completos',
        'Descarga de Reportes'
      ],
    ),
    SystemRole(
      name: 'Operador',
      description: 'Permisos operativos para registro y edición de datos comunitarios.',
      permissions: [
        'Crear y Editar Censos',
        'Crear y Editar Habitantes',
        'Crear y Editar Ayudas',
        'Crear y Editar Actividades',
        'Descarga de Reportes'
      ],
    ),
    SystemRole(
      name: 'Visor',
      description: 'Acceso exclusivo de solo lectura y generación de reportes.',
      permissions: [
        'Visualización de Inicio y Módulos',
        'Visualización de Estadísticas',
        'Descarga de Reportes PDF y Excel'
      ],
    ),
  ];

  String _searchQuery = '';
  final _searchController = TextEditingController();
  String _templateSearchQuery = '';
  final _templateSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingUsers = true);
    await CensoDictionary.loadTemplateFromStorage();

    final mongoService = sl<MongoDBService>();
    final sectoresBox = await Hive.openBox('sectores_box');
    final usersBox = await Hive.openBox('system_users_box');

    // 1. Cargar Sectores (API remote + fallback Hive local)
    _sectores.clear();
    final Map<String, SectorItem> sectorMap = {};

    if (sectoresBox.isNotEmpty) {
      for (var val in sectoresBox.values) {
        if (val is Map) {
          final m = Map<String, dynamic>.from(val);
          final nombre = (m['nombre'] ?? '').toString().trim();
          final id = (m['id'] ?? '').toString();
          if (nombre.isNotEmpty) {
            sectorMap[nombre.toLowerCase()] = SectorItem(
              id: id.isNotEmpty ? id : 'sec_${nombre.hashCode}',
              nombre: nombre,
              descripcion: m['descripcion'] ?? '',
              totalHabitantes: m['totalHabitantes'] ?? 0,
            );
          }
        }
      }
    }

    try {
      final remoteSectores = await mongoService.getRecords('sectores');
      if (remoteSectores.isNotEmpty) {
        for (var s in remoteSectores) {
          final nombre = (s['nombre'] ?? '').toString().trim();
          final id = (s['id'] ?? s['_id'] ?? '').toString();
          if (nombre.isNotEmpty) {
            final secItem = SectorItem(
              id: id.isNotEmpty ? id : 'sec_${nombre.hashCode}',
              nombre: nombre,
              descripcion: s['descripcion'] ?? '',
              totalHabitantes: s['totalHabitantes'] ?? 0,
            );
            sectorMap[nombre.toLowerCase()] = secItem;
            await sectoresBox.put(secItem.id, {
              'id': secItem.id,
              'nombre': secItem.nombre,
              'descripcion': secItem.descripcion,
              'totalHabitantes': secItem.totalHabitantes,
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error obteniendo sectores remotos: $e');
    }

    // Si aún no hay sectores (ni remotos ni locales), inicializar sectores por defecto
    if (sectorMap.isEmpty) {
      final defaultSectores = [
        SectorItem(id: 'sec_1', nombre: 'Sector 1 - Centro', descripcion: 'Zona central del municipio', totalHabitantes: 45),
        SectorItem(id: 'sec_2', nombre: 'Sector 2 - Norte', descripcion: 'Comunidad del sector norte', totalHabitantes: 32),
        SectorItem(id: 'sec_3', nombre: 'Sector 3 - Sur', descripcion: 'Comunidad del sector sur', totalHabitantes: 28),
        SectorItem(id: 'sec_4', nombre: 'Sector 4 - Este', descripcion: 'Comunidad del sector este', totalHabitantes: 19),
      ];
      for (var s in defaultSectores) {
        sectorMap[s.nombre.toLowerCase()] = s;
        await sectoresBox.put(s.id, {
          'id': s.id,
          'nombre': s.nombre,
          'descripcion': s.descripcion,
          'totalHabitantes': s.totalHabitantes,
        });
      }
    }

    _sectores.addAll(sectorMap.values);

    // 2. Cargar Usuarios (API remote + local Hive + recovered_credentials)
    _users.clear();
    final Map<String, SystemUser> userMap = {};

    try {
      final usersRes = await mongoService.getUsers();
      if (usersRes.isNotEmpty) {
        UserRolesHelper.updateOperadoresFromList(usersRes);
        for (var u in usersRes) {
          final roleRaw = (u['role'] ?? 'operador').toString().toLowerCase();
          String roleDisplay = 'Operador';
          if (roleRaw.contains('admin')) roleDisplay = 'Administrador';
          if (roleRaw.contains('visor')) roleDisplay = 'Visor';

          final username = (u['username'] ?? '').toString().toLowerCase();
          if (username.isNotEmpty) {
            userMap[username] = SystemUser(
              id: u['_id'] ?? u['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
              username: username,
              name: '${u['nombres'] ?? ''} ${u['apellidos'] ?? ''}'.trim().isEmpty
                  ? username
                  : '${u['nombres'] ?? ''} ${u['apellidos'] ?? ''}'.trim(),
              email: u['email'] ?? '$username@comuniapp.org',
              role: roleDisplay,
              status: u['status'] == 'Bloqueado' ? 'Bloqueado' : 'Activo',
              password: '••••••••',
              cedula: (u['cedula'] ?? '').toString(),
              telefono: (u['telefono'] ?? '').toString(),
            );
          }
        }
      }
    } catch (_) {}

    // Cargar también usuarios locales de Hive system_users_box
    if (usersBox.isNotEmpty) {
      for (var val in usersBox.values) {
        if (val is Map) {
          final u = Map<String, dynamic>.from(val);
          final username = (u['username'] ?? '').toString().toLowerCase();
          if (username.isNotEmpty && !userMap.containsKey(username)) {
            userMap[username] = SystemUser(
              id: (u['id'] ?? '').toString(),
              username: username,
              name: u['name'] ?? username,
              email: u['email'] ?? '$username@comuniapp.org',
              role: u['role'] ?? 'Operador',
              status: u['status'] ?? 'Activo',
              password: '••••••••',
              cedula: (u['cedula'] ?? '').toString(),
              telefono: (u['telefono'] ?? '').toString(),
            );
          }
        }
      }
    }

    // Si está completamente vacío, usar default admins
    if (userMap.isEmpty) {
      final defaultUsers = [
        SystemUser(id: 'usr_1', username: 'admin', name: 'Administrador Principal', email: 'admin@comuniapp.org', role: 'Administrador', status: 'Activo', password: '••••••••'),
        SystemUser(id: 'usr_2', username: 'operador1', name: 'Juan Pérez (Operador)', email: 'juan.perez@comuniapp.org', role: 'Operador', status: 'Activo', password: '••••••••'),
        SystemUser(id: 'usr_3', username: 'visor1', name: 'María López (Visor)', email: 'maria.lopez@comuniapp.org', role: 'Visor', status: 'Activo', password: '••••••••'),
      ];
      for (var u in defaultUsers) {
        userMap[u.username] = u;
      }
    }

    _users.addAll(userMap.values);
    UserRolesHelper.updateOperadoresFromList(
      _users.map((u) => {
        'username': u.username,
        'nombres': u.name,
        'role': u.role,
      }).toList()
    );

    if (mounted) {
      setState(() => _isLoadingUsers = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _templateSearchController.dispose();
    super.dispose();
  }

  List<SystemUser> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((u) {
      return u.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.role.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  String _generateProvisionalPassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#';
    final rand = Random();
    return List.generate(8, (index) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<List<Map<String, dynamic>>> _loadHabitantesForUserCreation() async {
    final List<Map<String, dynamic>> list = [];
    final Set<String> ids = {};

    try {
      final mongo = sl<MongoDBService>();
      final remote = await mongo.getRecords('habitants', queryParameters: {'limit': 1000});
      for (var r in remote) {
        final id = (r['id'] ?? r['_id'] ?? '').toString();
        final nombres = (r['nombres'] ?? '').toString().trim();
        final apellidos = (r['apellidos'] ?? '').toString().trim();
        final cedula = (r['cedula'] ?? '').toString().trim();
        final telefono = (r['telefono'] ?? '').toString().trim();
        final sector = (r['sector'] ?? '').toString().trim();
        final fullName = '$nombres $apellidos'.trim();

        if (fullName.isNotEmpty && !ids.contains(id)) {
          ids.add(id);
          list.add({
            'id': id,
            'nombres': nombres,
            'apellidos': apellidos,
            'fullName': fullName,
            'cedula': cedula,
            'telefono': telefono,
            'sector': sector,
          });
        }
      }
    } catch (_) {}

    try {
      final box = Hive.isBoxOpen(HiveConfig.habitantsBox)
          ? Hive.box(HiveConfig.habitantsBox)
          : await Hive.openBox(HiveConfig.habitantsBox);
      for (var h in box.values) {
        String id = '';
        String nombres = '';
        String apellidos = '';
        String cedula = '';
        String telefono = '';
        String sector = '';

        if (h is HabitanteModel) {
          id = h.id;
          nombres = h.nombres;
          apellidos = h.apellidos;
          cedula = h.cedula;
          telefono = h.telefono;
          sector = h.sector;
        } else if (h is Map) {
          id = (h['id'] ?? '').toString();
          nombres = (h['nombres'] ?? '').toString();
          apellidos = (h['apellidos'] ?? '').toString();
          cedula = (h['cedula'] ?? '').toString();
          telefono = (h['telefono'] ?? '').toString();
          sector = (h['sector'] ?? '').toString();
        }

        final fullName = '$nombres $apellidos'.trim();
        if (fullName.isNotEmpty && !ids.contains(id)) {
          ids.add(id);
          list.add({
            'id': id,
            'nombres': nombres,
            'apellidos': apellidos,
            'fullName': fullName,
            'cedula': cedula,
            'telefono': telefono,
            'sector': sector,
          });
        }
      }
    } catch (_) {}

    list.sort((a, b) => (a['fullName'] as String).compareTo(b['fullName'] as String));
    return list;
  }

  Future<void> _showCreateUserDialog() async {
    final habitanteOptions = await _loadHabitantesForUserCreation();

    final nameController = TextEditingController();
    final usernameController = TextEditingController();
    final emailController = TextEditingController();
    final cedulaController = TextEditingController();
    final telefonoController = TextEditingController();
    final passwordController = TextEditingController(text: _generateProvisionalPassword());
    String selectedRole = 'Operador';
    Map<String, dynamic>? selectedHabitante;
    final formKey = GlobalKey<FormState>();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        final size = MediaQuery.of(dialogContext).size;
        final isMobile = size.width < 600;

        return StatefulBuilder(
          builder: (stContext, setDialogState) {
            return Dialog(
              alignment: isMobile ? Alignment.bottomCenter : Alignment.center,
              insetPadding: isMobile ? const EdgeInsets.only(top: 40) : const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
              shape: RoundedRectangleBorder(
                borderRadius: isMobile 
                  ? const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))
                  : BorderRadius.circular(16),
              ),
              backgroundColor: Colors.white,
              elevation: 8,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 540,
                  maxHeight: isMobile ? size.height * 0.9 : size.height * 0.88,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF416FDF),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: isMobile ? Radius.zero : Radius.zero,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.person_add, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Crear Usuario desde Habitante',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── 1. Seleccionar Habitante Registrado ──
                              const Text(
                                'Habitante Registrado *',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Seleccione un habitante existente para importar automáticamente sus datos',
                                style: TextStyle(color: Colors.black45, fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              if (habitanteOptions.isEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.amber.shade200),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded, color: Colors.amber),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'No hay habitantes registrados. Registre primero a un habitante en la sección de Habitantes.',
                                          style: TextStyle(fontSize: 12, color: Colors.black87),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ] else ...[
                                DropdownButtonFormField<Map<String, dynamic>>(
                                  dropdownColor: Colors.white,
                                  value: selectedHabitante,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    hintText: 'Seleccionar habitante...',
                                    hintStyle: const TextStyle(color: Colors.black38),
                                    prefixIcon: const Icon(Icons.person_search, color: Color(0xFF416FDF)),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                  items: habitanteOptions.map((h) {
                                    final fullName = h['fullName'] ?? '';
                                    final ced = h['cedula'] != null && h['cedula'].toString().isNotEmpty
                                        ? ' • C.I: ${h['cedula']}'
                                        : '';
                                    final sec = h['sector'] != null && h['sector'].toString().isNotEmpty
                                        ? ' (${h['sector']})'
                                        : '';
                                    return DropdownMenuItem<Map<String, dynamic>>(
                                      value: h,
                                      child: Text('$fullName$ced$sec', overflow: TextOverflow.ellipsis),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setDialogState(() {
                                        selectedHabitante = val;
                                        nameController.text = val['fullName'] ?? '';
                                        cedulaController.text = val['cedula'] ?? '';
                                        telefonoController.text = val['telefono'] ?? '';

                                        final rawCed = (val['cedula'] ?? '').toString().trim();
                                        final cleanCed = rawCed.replaceAll(RegExp(r'[^a-zA-Z0-9\-]'), '');
                                        String suggestedUser = cleanCed.isNotEmpty
                                            ? cleanCed.replaceAll('-', '_')
                                            : ((val['nombres'] ?? '') + (val['apellidos'] ?? ''))
                                                .toString()
                                                .toLowerCase()
                                                .replaceAll(RegExp(r'[^a-z0-9]'), '');
                                        if (suggestedUser.isEmpty) suggestedUser = 'user_${DateTime.now().millisecondsSinceEpoch}';

                                        usernameController.text = suggestedUser;
                                        emailController.text = '$suggestedUser@comuniapp.org';
                                      });
                                    }
                                  },
                                  validator: (v) => v == null ? 'Debe seleccionar un habitante' : null,
                                ),
                                const SizedBox(height: 16),
                              ],

                              // ── 2. Datos importados del habitante ──
                              const Text(
                                'Nombre Completo',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: nameController,
                                style: const TextStyle(color: Colors.black87),
                                readOnly: habitanteOptions.isNotEmpty,
                                decoration: InputDecoration(
                                  hintText: 'Nombre del habitante',
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? 'El nombre es obligatorio' : null,
                              ),
                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Cédula', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: cedulaController,
                                          style: const TextStyle(color: Colors.black87),
                                          readOnly: habitanteOptions.isNotEmpty,
                                          decoration: InputDecoration(
                                            hintText: 'Cédula',
                                            filled: true,
                                            fillColor: Colors.grey.shade100,
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Teléfono', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: telefonoController,
                                          style: const TextStyle(color: Colors.black87),
                                          readOnly: habitanteOptions.isNotEmpty,
                                          decoration: InputDecoration(
                                            hintText: 'Teléfono',
                                            filled: true,
                                            fillColor: Colors.grey.shade100,
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // ── 3. Datos de Usuario/Acceso ──
                              const Text(
                                'Nombre de Usuario *',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: usernameController,
                                style: const TextStyle(color: Colors.black87),
                                decoration: InputDecoration(
                                  hintText: 'Ej. jperez o 12345678',
                                  hintStyle: const TextStyle(color: Colors.black38),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? 'El usuario es obligatorio' : null,
                              ),
                              const SizedBox(height: 16),

                              const Text(
                                'Correo Electrónico *',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: emailController,
                                style: const TextStyle(color: Colors.black87),
                                decoration: InputDecoration(
                                  hintText: 'Ej. juan.perez@comuniapp.org',
                                  hintStyle: const TextStyle(color: Colors.black38),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'El correo es obligatorio';
                                  if (!v.contains('@') || !v.contains('.')) return 'Ingrese un correo válido';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              const Text(
                                'Rol Asignado *',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                dropdownColor: Colors.white,
                                value: selectedRole,
                                style: const TextStyle(color: Colors.black87),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                items: _staticRoles
                                    .map((r) => DropdownMenuItem(value: r.name, child: Text(r.name)))
                                    .toList(),
                                onChanged: (val) => setDialogState(() => selectedRole = val!),
                              ),
                              const SizedBox(height: 16),

                              const Text(
                                'Contraseña *',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Escriba una contraseña o genere una automáticamente',
                                style: TextStyle(color: Colors.black45, fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: passwordController,
                                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  hintText: 'Mínimo 6 caracteres',
                                  hintStyle: const TextStyle(color: Colors.black38),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.refresh, color: Color(0xFF416FDF)),
                                    tooltip: 'Generar contraseña aleatoria',
                                    onPressed: () {
                                      setDialogState(() {
                                        passwordController.text = _generateProvisionalPassword();
                                      });
                                    },
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'La contraseña es obligatoria';
                                  if (v.trim().length < 6) return 'Mínimo 6 caracteres';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.grey.shade200)),
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Cancelar', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF416FDF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 2,
                            ),
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                final newUser = SystemUser(
                                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                                  username: usernameController.text.trim().toLowerCase(),
                                  name: nameController.text.trim(),
                                  email: emailController.text.trim(),
                                  role: selectedRole,
                                  status: 'Activo',
                                  password: passwordController.text.trim(),
                                  cedula: cedulaController.text.trim(),
                                  telefono: telefonoController.text.trim(),
                                );

                                final habitantNombres = selectedHabitante?['nombres'] ?? '';
                                final habitantApellidos = selectedHabitante?['apellidos'] ?? '';

                                try {
                                  final mongo = sl<MongoDBService>();
                                  await mongo.createUser({
                                    'username': newUser.username,
                                    'password': newUser.password,
                                    'role': newUser.role.toLowerCase(),
                                    'nombres': habitantNombres.isNotEmpty ? habitantNombres : newUser.name,
                                    'apellidos': habitantApellidos,
                                    'cedula': newUser.cedula,
                                    'telefono': newUser.telefono,
                                    'email': newUser.email,
                                  });
                                  final recoveredBox = await Hive.openBox('recovered_credentials');
                                  await recoveredBox.put(newUser.username, newUser.password);
                                  final usersBox = await Hive.openBox('system_users_box');
                                  await usersBox.put(newUser.username, {
                                    'id': newUser.id,
                                    'username': newUser.username,
                                    'name': newUser.name,
                                    'email': newUser.email,
                                    'role': newUser.role,
                                    'status': newUser.status,
                                    'cedula': newUser.cedula,
                                    'telefono': newUser.telefono,
                                  });
                                } catch (_) {}

                                setState(() {
                                  _users.insert(0, newUser);
                                  UserRolesHelper.updateOperadoresFromList(
                                    _users.map((u) => {
                                      'username': u.username,
                                      'nombres': u.name,
                                      'role': u.role,
                                    }).toList()
                                  );
                                });

                                sl<AuditLoggerService>().log('Creó al usuario "${newUser.name}" (C.I. ${newUser.cedula}) con rol ${newUser.role}');

                                if (mounted) {
                                  Navigator.pop(dialogContext);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Usuario "${newUser.name}" creado con éxito desde el habitante.'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditUserDialog(SystemUser user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    String selectedRole = user.role;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        final size = MediaQuery.of(dialogContext).size;
        final isMobile = size.width < 600;

        return Dialog(
          alignment: isMobile ? Alignment.bottomCenter : Alignment.center,
          insetPadding: isMobile ? const EdgeInsets.only(top: 40) : const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
          shape: RoundedRectangleBorder(
            borderRadius: isMobile 
              ? const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))
              : BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          elevation: 8,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 450,
              maxHeight: isMobile ? size.height * 0.9 : size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF416FDF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Editar Usuario (${user.username})',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Nombre Completo *', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: nameController,
                            style: const TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 16),

                          const Text('Correo Electrónico *', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: emailController,
                            style: const TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            validator: (v) => v == null || !v.contains('@') ? 'Correo inválido' : null,
                          ),
                          const SizedBox(height: 16),

                          const Text('Rol *', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            dropdownColor: Colors.white,
                            value: selectedRole,
                            style: const TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            items: _staticRoles.map((r) => DropdownMenuItem(value: r.name, child: Text(r.name))).toList(),
                            onChanged: (val) => setState(() => selectedRole = val!),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF416FDF)),
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            final updatedUser = user.copyWith(
                              name: nameController.text.trim(),
                              email: emailController.text.trim(),
                              role: selectedRole,
                            );

                            try {
                              final mongo = sl<MongoDBService>();
                              await mongo.updateUser(user.username, {
                                'nombres': updatedUser.name,
                                'email': updatedUser.email,
                                'role': updatedUser.role.toLowerCase(),
                              });
                            } catch (_) {}

                            setState(() {
                              final idx = _users.indexWhere((u) => u.id == user.id);
                              if (idx != -1) _users[idx] = updatedUser;
                            });

                            if (mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Usuario actualizado exitosamente.'), backgroundColor: Colors.green),
                              );
                            }
                          }
                        },
                        child: const Text('Guardar', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteUser(SystemUser user) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar Usuario'),
          ],
        ),
        content: Text('¿Está seguro de eliminar al usuario "${user.name}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                final mongo = sl<MongoDBService>();
                await mongo.deleteUser(user.username);
              } catch (_) {}

              setState(() {
                _users.removeWhere((u) => u.id == user.id);
              });

              sl<AuditLoggerService>().log('Eliminó al usuario "${user.name}"');
              if (mounted) {
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Usuario "${user.name}" eliminado.'), backgroundColor: Colors.redAccent),
                );
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showSectorModal({SectorItem? sector}) {
    final nombreCtrl = TextEditingController(text: sector?.nombre ?? '');
    final descCtrl = TextEditingController(text: sector?.descripcion ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          padding: const EdgeInsets.all(20),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sector != null ? 'Editar Sector' : 'Nuevo Sector',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF416FDF)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre del Sector *', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Descripción del Sector', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancelar')),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF416FDF), foregroundColor: Colors.white),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final mongo = sl<MongoDBService>();
                          final sectoresBox = await Hive.openBox('sectores_box');

                          if (sector != null) {
                            final updatedSector = SectorItem(
                              id: sector.id,
                              nombre: nombreCtrl.text.trim(),
                              descripcion: descCtrl.text.trim(),
                              totalHabitantes: sector.totalHabitantes,
                            );

                            try {
                              await mongo.updateRecord('sectores', sector.id, {
                                'id': updatedSector.id,
                                'nombre': updatedSector.nombre,
                                'descripcion': updatedSector.descripcion,
                                'totalHabitantes': updatedSector.totalHabitantes,
                              });
                            } catch (_) {}

                            await sectoresBox.put(sector.id, {
                              'id': updatedSector.id,
                              'nombre': updatedSector.nombre,
                              'descripcion': updatedSector.descripcion,
                              'totalHabitantes': updatedSector.totalHabitantes,
                            });

                            setState(() {
                              final idx = _sectores.indexWhere((s) => s.id == sector.id);
                              if (idx != -1) _sectores[idx] = updatedSector;
                            });
                          } else {
                            final newId = 'sec_${DateTime.now().millisecondsSinceEpoch}';
                            final newSector = SectorItem(
                              id: newId,
                              nombre: nombreCtrl.text.trim(),
                              descripcion: descCtrl.text.trim(),
                              totalHabitantes: 0,
                            );

                            try {
                              await mongo.createRecord('sectores', {
                                'id': newSector.id,
                                'nombre': newSector.nombre,
                                'descripcion': newSector.descripcion,
                                'totalHabitantes': 0,
                              });
                            } catch (_) {}

                            await sectoresBox.put(newId, {
                              'id': newSector.id,
                              'nombre': newSector.nombre,
                              'descripcion': newSector.descripcion,
                              'totalHabitantes': 0,
                            });

                            setState(() {
                              _sectores.removeWhere((s) => s.id == newSector.id || s.nombre.toLowerCase() == newSector.nombre.toLowerCase());
                              _sectores.add(newSector);
                            });
                            sl<AuditLoggerService>().log('Guardó el sector "${newSector.nombre}"');
                          }

                          if (mounted) {
                            Navigator.pop(dialogCtx);
                          }
                        }
                      },
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScaffold(
      drawer: SideMenu(scaffoldKey: scaffoldKey),
      child: DefaultTabController(
        length: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Administración General',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Gestión de usuarios, perfiles de acceso, sectores comunitarios y plantillas de censo',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  border: Border.all(color: Colors.black12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TabBar(
                      labelColor: theme.colorScheme.primary,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: theme.colorScheme.primary,
                      indicatorSize: TabBarIndicatorSize.tab,
                      tabs: const [
                        Tab(
                          iconMargin: EdgeInsets.only(bottom: 2),
                          icon: Icon(Icons.people_outline, size: 18),
                          text: 'Usuarios',
                        ),
                        Tab(
                          iconMargin: EdgeInsets.only(bottom: 2),
                          icon: Icon(Icons.admin_panel_settings_outlined, size: 18),
                          text: 'Roles y Permisos',
                        ),
                        Tab(
                          iconMargin: EdgeInsets.only(bottom: 2),
                          icon: Icon(Icons.map_outlined, size: 18),
                          text: 'Gestión de Sectores',
                        ),
                        Tab(
                          iconMargin: EdgeInsets.only(bottom: 2),
                          icon: Icon(Icons.assignment_outlined, size: 18),
                          text: 'Plantillas de Censo',
                        ),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildUsersTab(theme),
                          _buildRolesTab(theme),
                          _buildSectoresTab(theme),
                          _buildCensoPlantillaTab(theme),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab(ThemeData theme) {
    if (_isLoadingUsers) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            color: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.black12),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Buscar por usuario, nombre, correo o rol...',
                        hintStyle: const TextStyle(color: Colors.black38),
                        prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Tooltip(
                    message: 'Agregar Usuario',
                    child: IconButton(
                      onPressed: _showCreateUserDialog,
                      icon: const Icon(Icons.add, size: 24),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(12),
                        elevation: 3,
                        shape: const CircleBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Card(
            color: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: const BorderSide(color: Colors.black12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      'Usuarios Registrados',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 420,
                    child: Theme(
                      data: theme.copyWith(
                        cardColor: Colors.white,
                        textTheme: theme.textTheme.apply(
                          bodyColor: Colors.black87,
                          displayColor: Colors.black87,
                        ),
                      ),
                      child: DataTable2(
                        columnSpacing: 12,
                        horizontalMargin: 12,
                        minWidth: 700,
                        columns: const [
                          DataColumn2(label: Text('Usuario/Nombre', style: TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.L),
                          DataColumn2(label: Text('Correo Electrónico', style: TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.L),
                          DataColumn2(label: Text('Rol', style: TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.M),
                          DataColumn2(label: Text('Estatus', style: TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.M),
                          DataColumn2(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.S, fixedWidth: 110),
                        ],
                        rows: _filteredUsers.map((u) {
                          final isBlocked = u.status == 'Bloqueado';
                          return DataRow(
                            cells: [
                              DataCell(Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(u.name, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                                  Text('@${u.username}', style: const TextStyle(color: Colors.black45, fontSize: 12)),
                                ],
                              )),
                              DataCell(Text(u.email, style: const TextStyle(color: Colors.black87))),
                              DataCell(
                                Chip(
                                  backgroundColor: const Color(0xFF416FDF).withOpacity(0.08),
                                  side: BorderSide(color: const Color(0xFF416FDF).withOpacity(0.2)),
                                  label: Text(
                                    u.role,
                                    style: const TextStyle(
                                      color: Color(0xFF416FDF),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                              DataCell(
                                Chip(
                                  backgroundColor: isBlocked ? Colors.red.shade50 : Colors.green.shade50,
                                  side: BorderSide(color: isBlocked ? Colors.red.shade100 : Colors.green.shade100),
                                  label: Text(
                                    u.status,
                                    style: TextStyle(
                                      color: isBlocked ? Colors.red.shade700 : Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                      onPressed: () => _showEditUserDialog(u),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      onPressed: () => _confirmDeleteUser(u),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRolesTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Card(
            color: Colors.white,
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Matriz de Roles y Permisos del Sistema',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF416FDF)),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Los niveles de acceso están estandarizados para garantizar la seguridad operacional.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: _staticRoles.map((role) {
              final int count = _users.where((u) => u.role.toLowerCase() == role.name.toLowerCase()).length;

              return Container(
                width: 340,
                child: Card(
                  color: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: const BorderSide(color: Colors.black12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              role.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF416FDF)),
                            ),
                            Chip(
                              backgroundColor: Colors.indigo.shade50,
                              label: Text('$count usuarios', style: TextStyle(color: Colors.indigo.shade700, fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(role.description, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                        const Divider(height: 24),
                        const Text('Permisos Estáticos:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 8),
                        ...role.permissions.map((p) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(p, style: const TextStyle(fontSize: 12, color: Colors.black87))),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectoresTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              const Text(
                'Sectores Comunitarios',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              IconButton.filled(
                onPressed: () => _showSectorModal(),
                icon: const Icon(Icons.add),
                tooltip: 'Agregar Sector',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF416FDF),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: _sectores.map((sec) {
              return Container(
                width: 320,
                child: Card(
                  color: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.black12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(sec.nombre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF416FDF))),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                              onPressed: () => _showSectorModal(sector: sec),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                              onPressed: () async {
                                final mongo = sl<MongoDBService>();
                                final sectoresBox = await Hive.openBox('sectores_box');
                                try {
                                  await mongo.deleteRecord('sectores', sec.id);
                                } catch (_) {}
                                await sectoresBox.delete(sec.id);

                                setState(() => _sectores.removeWhere((s) => s.id == sec.id));
                                sl<AuditLoggerService>().log('Eliminó el sector "${sec.nombre}"');
                              },
                            ),
                          ],
                        ),
                        Text(sec.descripcion.isEmpty ? 'Sin descripción' : sec.descripcion, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getFieldTypeName(FieldType type) {
    switch (type) {
      case FieldType.text:
        return 'Texto';
      case FieldType.number:
        return 'Número';
      case FieldType.date:
        return 'Fecha';
      case FieldType.dropdown:
        return 'Desplegable (Único)';
      case FieldType.checkboxList:
        return 'Selección Múltiple';
      case FieldType.radio:
        return 'Opción Única (Radio)';
      case FieldType.checkboxListWithQuantity:
        return 'Selección con Cantidad';
    }
  }

  Widget _buildCensoPlantillaTab(ThemeData theme) {
    final categorized = CensoDictionary.getCategorizedFields();
    final categories = CensoDictionary.getCategories();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.black12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: TextField(
                      controller: _templateSearchController,
                      onChanged: (val) => setState(() => _templateSearchQuery = val),
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Buscar campo o categoría...',
                        hintStyle: const TextStyle(color: Colors.black38),
                        prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black12),
                        ),
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _showCategoryModal(),
                        icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                        label: const Text('Nuevo Grupo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF416FDF),
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showFieldModal(),
                        icon: const Icon(Icons.add_task, size: 18),
                        label: const Text('Nuevo Campo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _confirmResetTemplate,
                        icon: const Icon(Icons.restore, size: 18, color: Colors.orange),
                        label: const Text('Restablecer Plantilla', style: TextStyle(color: Colors.orange)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          ...categories.map((category) {
            var fieldsInCategory = categorized[category] ?? [];
            if (_templateSearchQuery.isNotEmpty) {
              fieldsInCategory = fieldsInCategory.where((f) {
                return f.label.toLowerCase().contains(_templateSearchQuery.toLowerCase()) ||
                    f.id.toLowerCase().contains(_templateSearchQuery.toLowerCase()) ||
                    f.category.toLowerCase().contains(_templateSearchQuery.toLowerCase());
              }).toList();
              if (fieldsInCategory.isEmpty && !category.toLowerCase().contains(_templateSearchQuery.toLowerCase())) {
                return const SizedBox.shrink();
              }
            }

            return Card(
              color: Colors.white,
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.black12),
              ),
              child: Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  key: ValueKey<String>('category_tile_$category'),
                  initiallyExpanded: _templateSearchQuery.isNotEmpty,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  title: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.folder_open, color: Color(0xFF416FDF), size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          category,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Chip(
                          backgroundColor: const Color(0xFF416FDF).withOpacity(0.08),
                          side: BorderSide.none,
                          label: Text(
                            '${fieldsInCategory.length} campos',
                            style: const TextStyle(
                              color: Color(0xFF416FDF),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                          tooltip: 'Renombrar grupo',
                          onPressed: () => _showCategoryModal(oldCategoryName: category),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                          tooltip: 'Eliminar grupo completo',
                          onPressed: () => _confirmDeleteCategory(category),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.teal, size: 20),
                          tooltip: 'Agregar campo a este grupo',
                          onPressed: () => _showFieldModal(initialCategory: category),
                        ),
                      ],
                    ),
                  ),
                  children: [
                    const Divider(color: Colors.black12, height: 1),
                    const SizedBox(height: 12),
                    if (fieldsInCategory.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(
                          'No hay campos registrados en este grupo. Presione "+" para agregar uno.',
                          style: TextStyle(color: Colors.black45, fontStyle: FontStyle.italic),
                        ),
                      )
                    else
                      SingleChildScrollView(
                        key: ValueKey<String>('category_scroll_$category'),
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 16,
                          horizontalMargin: 8,
                          columns: const [
                            DataColumn(label: Text('Campo / Etiqueta', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Identificador (ID)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Tipo de Dato', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Requerido', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Opciones Configuradas', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: fieldsInCategory.map((f) {
                            return DataRow(
                              cells: [
                                DataCell(Text(f.label, style: const TextStyle(fontWeight: FontWeight.w600))),
                                DataCell(Text(f.id, style: const TextStyle(color: Colors.black54, fontFamily: 'monospace', fontSize: 12))),
                                DataCell(Chip(
                                  backgroundColor: Colors.grey.shade100,
                                  label: Text(_getFieldTypeName(f.type), style: const TextStyle(fontSize: 11)),
                                )),
                                DataCell(Chip(
                                  backgroundColor: f.isRequired ? Colors.red.shade50 : Colors.green.shade50,
                                  label: Text(
                                    f.isRequired ? 'Sí' : 'No',
                                    style: TextStyle(color: f.isRequired ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                )),
                                DataCell(
                                  f.options != null && f.options!.isNotEmpty
                                      ? SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: <Widget>[
                                              ...f.options!.take(3).map((o) => Padding(
                                                padding: const EdgeInsets.only(right: 4.0),
                                                child: Chip(
                                                  padding: EdgeInsets.zero,
                                                  label: Text(o, style: const TextStyle(fontSize: 10)),
                                                ),
                                              )),
                                              if (f.options!.length > 3)
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 2.0),
                                                  child: Text(' +${f.options!.length - 3}', style: const TextStyle(fontSize: 10, color: Colors.black45)),
                                                ),
                                            ],
                                          ),
                                        )
                                      : const Text('-', style: TextStyle(color: Colors.black38)),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                                        onPressed: () => _showFieldModal(field: f),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                        onPressed: () => _confirmDeleteField(f),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showCategoryModal({String? oldCategoryName}) {
    final catCtrl = TextEditingController(text: oldCategoryName ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(20),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  oldCategoryName != null ? 'Renombrar Grupo de Censo' : 'Nuevo Grupo / Categoría',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF416FDF)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: catCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Grupo / Categoría *',
                    hintText: 'Ej. Servicios de Gas, Mascotas',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'El nombre es obligatorio' : null,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancelar')),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF416FDF), foregroundColor: Colors.white),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final newName = catCtrl.text.trim();
                          if (oldCategoryName != null && oldCategoryName != newName) {
                            final categorized = CensoDictionary.getCategorizedFields();
                            final fields = categorized[oldCategoryName] ?? [];
                            for (var f in fields) {
                              await CensoDictionary.addOrUpdateField(f.copyWith(category: newName));
                            }
                            await CensoDictionary.deleteCategory(oldCategoryName);
                          } else {
                            await CensoDictionary.addCategory(newName);
                          }
                          sl<AuditLoggerService>().log('Guardó el grupo de censo "$newName"');
                          if (mounted) {
                            setState(() {});
                            Navigator.pop(dialogCtx);
                          }
                        }
                      },
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteCategory(String categoryName) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar Grupo'),
          ],
        ),
        content: Text('¿Está seguro de eliminar el grupo "$categoryName" y todos los campos contenidos en él?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await CensoDictionary.deleteCategory(categoryName);
              sl<AuditLoggerService>().log('Eliminó el grupo de censo "$categoryName"');
              if (mounted) {
                setState(() {});
                Navigator.pop(dialogCtx);
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showFieldModal({String? initialCategory, CensoFieldDef? field}) {
    final labelCtrl = TextEditingController(text: field?.label ?? '');
    final idCtrl = TextEditingController(text: field?.id ?? '');
    final optionsCtrl = TextEditingController(text: field?.options?.join(', ') ?? '');
    
    final categories = CensoDictionary.getCategories();
    String selectedCategory = field?.category ?? initialCategory ?? (categories.isNotEmpty ? categories.first : 'General');
    FieldType selectedType = field?.type ?? FieldType.text;
    bool isRequired = field?.isRequired ?? false;

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final showOptions = selectedType == FieldType.dropdown ||
              selectedType == FieldType.checkboxList ||
              selectedType == FieldType.radio ||
              selectedType == FieldType.checkboxListWithQuantity;

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(20),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        field != null ? 'Editar Campo de Censo' : 'Nuevo Campo de Censo',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF416FDF)),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: labelCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre / Etiqueta del Campo *',
                          hintText: 'Ej. Tipo de Bombona, Marca de Vehículo',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                        onChanged: (val) {
                          if (field == null && idCtrl.text.isEmpty) {
                            idCtrl.text = val.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: idCtrl,
                        readOnly: field != null,
                        decoration: InputDecoration(
                          labelText: 'Identificador Interno (ID / Key) *',
                          hintText: 'Ej. tipo_bombona',
                          border: const OutlineInputBorder(),
                          fillColor: field != null ? Colors.grey.shade100 : Colors.white,
                          filled: field != null,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        dropdownColor: Colors.white,
                        value: categories.contains(selectedCategory) ? selectedCategory : (categories.isNotEmpty ? categories.first : 'General'),
                        decoration: const InputDecoration(labelText: 'Grupo / Categoría *', border: OutlineInputBorder()),
                        items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) => setModalState(() => selectedCategory = val!),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<FieldType>(
                        dropdownColor: Colors.white,
                        value: selectedType,
                        decoration: const InputDecoration(labelText: 'Tipo de Campo *', border: OutlineInputBorder()),
                        items: FieldType.values
                            .map((ft) => DropdownMenuItem(value: ft, child: Text(_getFieldTypeName(ft))))
                            .toList(),
                        onChanged: (val) => setModalState(() => selectedType = val!),
                      ),
                      const SizedBox(height: 12),
                      if (showOptions) ...[
                        TextFormField(
                          controller: optionsCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Opciones (Separadas por comas) *',
                            hintText: 'Ej. Opción 1, Opción 2, Opción 3',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (showOptions && (v == null || v.trim().isEmpty)) {
                              return 'Ingrese al menos una opción';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      CheckboxListTile(
                        title: const Text('Campo Obligatorio (Requerido)'),
                        value: isRequired,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setModalState(() => isRequired = val == true),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancelar')),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF416FDF), foregroundColor: Colors.white),
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                final newField = CensoFieldDef(
                                  id: idCtrl.text.trim().replaceAll(' ', '_').toLowerCase(),
                                  label: labelCtrl.text.trim(),
                                  category: selectedCategory,
                                  type: selectedType,
                                  options: showOptions
                                      ? optionsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
                                      : null,
                                  isRequired: isRequired,
                                );

                                await CensoDictionary.addOrUpdateField(newField);
                                sl<AuditLoggerService>().log('Guardó el campo de censo "${newField.label}"');
                                if (mounted) {
                                  setState(() {});
                                  Navigator.pop(dialogCtx);
                                }
                              }
                            },
                            child: const Text('Guardar Campo'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteField(CensoFieldDef field) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar Campo'),
          ],
        ),
        content: Text('¿Está seguro de eliminar el campo "${field.label}" de la plantilla?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await CensoDictionary.deleteField(field.id);
              sl<AuditLoggerService>().log('Eliminó el campo de censo "${field.label}"');
              if (mounted) {
                setState(() {});
                Navigator.pop(dialogCtx);
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _confirmResetTemplate() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.restore, color: Colors.orange),
            SizedBox(width: 8),
            Text('Restablecer Plantilla'),
          ],
        ),
        content: const Text('¿Está seguro de restablecer la plantilla a la versión original de fábrica? Se descartarán las categorías y campos personalizados.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () async {
              await CensoDictionary.resetToDefaults();
              sl<AuditLoggerService>().log('Restableció la plantilla de censo por defecto');
              if (mounted) {
                setState(() {});
                Navigator.pop(dialogCtx);
              }
            },
            child: const Text('Restablecer'),
          ),
        ],
      ),
    );
  }
}
