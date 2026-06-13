import 'dart:math';
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../../../shared/widgets/custom_scaffold.dart';
import '../../../../shared/widgets/side_menu.dart';

class SystemUser {
  final String id;
  final String name;
  final String email;
  final String role; // 'Admin', 'Operador', 'Visor'
  final String status; // 'Activo', 'Bloqueado'
  final String password;

  SystemUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.password,
  });

  SystemUser copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? status,
    String? password,
  }) {
    return SystemUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      password: password ?? this.password,
    );
  }
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

  final List<SystemRole> _systemRoles = [
    const SystemRole(
      name: 'Admin',
      description: 'Acceso total y control de seguridad de toda la plataforma.',
      permissions: ['Crear Usuarios', 'Gestionar Censos', 'Configuración de Sistema', 'Auditoría Completa'],
    ),
    const SystemRole(
      name: 'Operador',
      description: 'Gestión diaria de habitantes, censos, jornadas y ayudas.',
      permissions: ['Crear Censos', 'Crear Habitantes', 'Registrar Ayudas', 'Registrar Eventos'],
    ),
    const SystemRole(
      name: 'Visor',
      description: 'Acceso de solo lectura para reportes y visualización.',
      permissions: ['Ver Dashboard', 'Ver Estadísticas', 'Generar Reportes PDF'],
    ),
  ];

  List<String> get _roles => _systemRoles.map((r) => r.name).toList();
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-populate with some beautiful mock users
    _users.addAll([
      SystemUser(
        id: '1',
        name: 'Alejandro Colmenarez',
        email: 'a.colmenarez@comuniapp.org',
        role: 'Admin',
        status: 'Activo',
        password: 'Password123',
      ),
      SystemUser(
        id: '2',
        name: 'Gabriela Mendoza',
        email: 'g.mendoza@comuniapp.org',
        role: 'Operador',
        status: 'Activo',
        password: 'Password456',
      ),
      SystemUser(
        id: '3',
        name: 'Ricardo Espinoza',
        email: 'r.espinoza@comuniapp.org',
        role: 'Visor',
        status: 'Bloqueado',
        password: 'Password789',
      ),
    ]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SystemUser> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((u) {
      return u.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.role.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  String _generateProvisionalPassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#';
    final rand = Random();
    return List.generate(8, (index) => chars[rand.nextInt(chars.length)]).join();
  }

  void _showCreateUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController(text: _generateProvisionalPassword());
    String selectedRole = 'Operador';
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
              maxWidth: 500,
              maxHeight: isMobile ? size.height * 0.9 : size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
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
                      const Text(
                        'Crear Nuevo Usuario',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                // Form content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nombre Completo *',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: nameController,
                            style: const TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              hintText: 'Ej. Juan Pérez',
                              hintStyle: const TextStyle(color: Colors.black38),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'El nombre es obligatorio' : null,
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
                            items: _roles
                                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                                .toList(),
                            onChanged: (val) => setState(() => selectedRole = val!),
                          ),
                          const SizedBox(height: 16),
  
                          const Text(
                            'Contraseña Provisional',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: passwordController,
                            readOnly: true,
                            style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.refresh, color: Color(0xFF416FDF)),
                                onPressed: () {
                                  passwordController.text = _generateProvisionalPassword();
                                },
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Footer
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
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            setState(() {
                              _users.insert(
                                0,
                                SystemUser(
                                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                                  name: nameController.text.trim(),
                                  email: emailController.text.trim(),
                                  role: selectedRole,
                                  status: 'Activo',
                                  password: passwordController.text.trim(),
                                ),
                              );
                            });
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Usuario "${nameController.text}" creado con éxito.'),
                                backgroundColor: Colors.green,
                              ),
                            );
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
  }

  void _showChangePasswordDialog(SystemUser user) {
    final passController = TextEditingController();
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
              maxWidth: 400,
              maxHeight: isMobile ? size.height * 0.9 : size.height * 0.85,
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
                      const Text(
                        'Cambiar Contraseña',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
                          Text(
                            'Nueva contraseña para ${user.name}:',
                            style: const TextStyle(color: Colors.black87),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: passController,
                            style: const TextStyle(color: Colors.black87),
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: 'Ingrese nueva contraseña',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            validator: (v) => v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
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
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            setState(() {
                              final idx = _users.indexWhere((u) => u.id == user.id);
                              if (idx != -1) {
                                _users[idx] = user.copyWith(password: passController.text.trim());
                              }
                            });
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Contraseña cambiada exitosamente.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        child: const Text('Actualizar', style: TextStyle(color: Colors.white)),
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

  void _toggleUserBlock(SystemUser user, bool block) {
    setState(() {
      final idx = _users.indexWhere((u) => u.id == user.id);
      if (idx != -1) {
        _users[idx] = user.copyWith(status: block ? 'Bloqueado' : 'Activo');
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(block ? 'Usuario "${user.name}" bloqueado correctamente.' : 'Usuario "${user.name}" desbloqueado correctamente.'),
        backgroundColor: block ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScaffold(
      drawer: SideMenu(scaffoldKey: scaffoldKey),
      child: DefaultTabController(
        length: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Responsive Header (Clean design)
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
                    'Gestión de usuarios y control de roles del sistema',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            
            // Tab Navigation inside a themed container, identical to ProfilePage
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
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildUsersTab(theme),
                          _buildRolesTab(theme),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search and Action Bar Card
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
                        hintText: 'Buscar por nombre, correo o rol...',
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

          // Table card
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
                    height: 400,
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
                          DataColumn2(
                              label: Text('Usuario/Nombre', style: TextStyle(fontWeight: FontWeight.bold)),
                              size: ColumnSize.L),
                          DataColumn2(
                              label: Text('Correo Electrónico', style: TextStyle(fontWeight: FontWeight.bold)),
                              size: ColumnSize.L),
                          DataColumn2(
                              label: Text('Rol', style: TextStyle(fontWeight: FontWeight.bold)),
                              size: ColumnSize.M),
                          DataColumn2(
                              label: Text('Estatus', style: TextStyle(fontWeight: FontWeight.bold)),
                              size: ColumnSize.M),
                          DataColumn2(
                            label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold)),
                            size: ColumnSize.S,
                            fixedWidth: 100,
                          ),
                        ],
                        rows: _filteredUsers.map((u) {
                          final isBlocked = u.status == 'Bloqueado';
                          return DataRow(
                            cells: [
                              DataCell(Text(u.name, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold))),
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
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, color: Colors.black54),
                                  onSelected: (val) {
                                    if (val == 'password') {
                                      _showChangePasswordDialog(u);
                                    } else if (val == 'block') {
                                      _toggleUserBlock(u, true);
                                    } else if (val == 'unblock') {
                                      _toggleUserBlock(u, false);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'password',
                                      child: Row(
                                        children: [
                                          Icon(Icons.lock_open, size: 20, color: Colors.blue),
                                          SizedBox(width: 8),
                                          Text('Contraseña'),
                                        ],
                                      ),
                                    ),
                                    if (!isBlocked)
                                      const PopupMenuItem(
                                        value: 'block',
                                        child: Row(
                                          children: [
                                            Icon(Icons.block, size: 20, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Bloquear'),
                                          ],
                                        ),
                                      )
                                    else
                                      const PopupMenuItem(
                                        value: 'unblock',
                                        child: Row(
                                          children: [
                                            Icon(Icons.check_circle_outline, size: 20, color: Colors.green),
                                            SizedBox(width: 8),
                                            Text('Desbloquear'),
                                          ],
                                        ),
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
          // Header Card with add button for Roles
          Card(
            color: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.black12),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Listado de Roles Disponibles',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Tooltip(
                    message: 'Agregar Nuevo Rol',
                    child: IconButton(
                      onPressed: _showCreateRoleDialog,
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

          // Grid list of roles
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 900
                  ? 3
                  : (constraints.maxWidth > 600 ? 2 : 1);
              final itemWidth = (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: _systemRoles.map((role) {
                  final int userCount = _users.where((u) => u.role == role.name).length;

                  return Container(
                    width: itemWidth,
                    constraints: const BoxConstraints(minHeight: 220),
                    child: Card(
                      color: Colors.white,
                      surfaceTintColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: const BorderSide(color: Colors.black12),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title and User Count Badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    role.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF416FDF),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.indigo.shade100),
                                  ),
                                  child: Text(
                                    '$userCount ${userCount == 1 ? "usuario" : "usuarios"}',
                                    style: TextStyle(
                                      color: Colors.indigo.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 20, color: Colors.black54),
                                  onSelected: (val) {
                                    if (val == 'edit') {
                                      _showEditRoleDialog(role);
                                    } else if (val == 'delete') {
                                      _confirmDeleteRole(role);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, color: Colors.blue, size: 18),
                                          SizedBox(width: 8),
                                          Text('Editar permisos'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red, size: 18),
                                          SizedBox(width: 8),
                                          Text('Eliminar rol'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Description
                            Text(
                              role.description,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 16),
                            const Divider(color: Colors.black12),
                            const SizedBox(height: 10),
                            // Permissions Header
                            const Text(
                              'Permisos Asignados:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Permissions Chips
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: role.permissions.map((perm) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.black12),
                                  ),
                                  child: Text(
                                    perm,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showCreateRoleDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // List of key permissions
    final List<String> availablePermissions = [
      'Crear Usuarios',
      'Bloquear Usuarios',
      'Gestionar Censos',
      'Registrar Ayudas',
      'Registrar Eventos',
      'Ver Historial',
      'Editar Registros',
      'Acceso a Seguridad',
      'Exportar Reportes'
    ];

    final List<String> selectedPermissions = [];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
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
                  maxWidth: 500,
                  maxHeight: isMobile ? size.height * 0.9 : size.height * 0.85,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
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
                          const Text(
                            'Crear Nuevo Rol',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    // Form content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Nombre del Rol *',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: nameController,
                                style: const TextStyle(color: Colors.black87),
                                decoration: InputDecoration(
                                  hintText: 'Ej. Supervisor de Proyectos',
                                  hintStyle: const TextStyle(color: Colors.black38),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'El nombre es obligatorio';
                                  if (_roles.any((r) => r.trim().toLowerCase() == v.trim().toLowerCase())) {
                                    return 'Este rol ya existe en el sistema';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              const Text(
                                'Descripción *',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: descController,
                                maxLines: 2,
                                style: const TextStyle(color: Colors.black87),
                                decoration: InputDecoration(
                                  hintText: 'Ej. Encargado de fiscalizar censos y ayuda local.',
                                  hintStyle: const TextStyle(color: Colors.black38),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                validator: (v) => v == null || v.isEmpty ? 'La descripción es obligatoria' : null,
                              ),
                              const SizedBox(height: 16),

                              const Text(
                                'Asignar Permisos del Rol',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 15),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: availablePermissions.map((perm) {
                                  final isSelected = selectedPermissions.contains(perm);
                                  return FilterChip(
                                    label: Text(
                                      perm,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.black87,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 12,
                                      ),
                                    ),
                                    selected: isSelected,
                                    selectedColor: const Color(0xFF416FDF),
                                    checkmarkColor: Colors.white,
                                    backgroundColor: Colors.grey.shade100,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(color: isSelected ? Colors.transparent : Colors.black12),
                                    ),
                                    onSelected: (val) {
                                      setStateModal(() {
                                        if (val) {
                                          selectedPermissions.add(perm);
                                        } else {
                                          selectedPermissions.remove(perm);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Footer
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
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                setState(() {
                                  _systemRoles.add(
                                    SystemRole(
                                      name: nameController.text.trim(),
                                      description: descController.text.trim(),
                                      permissions: selectedPermissions.isEmpty
                                          ? ['Acceso Básico']
                                          : List.from(selectedPermissions),
                                    ),
                                  );
                                });
                                Navigator.pop(dialogContext);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Rol "${nameController.text}" creado con éxito.'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
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

  void _showEditRoleDialog(SystemRole role) {
    final nameController = TextEditingController(text: role.name);
    final descController = TextEditingController(text: role.description);
    final formKey = GlobalKey<FormState>();

    final List<String> availablePermissions = [
      'Crear Usuarios',
      'Bloquear Usuarios',
      'Gestionar Censos',
      'Registrar Ayudas',
      'Registrar Eventos',
      'Ver Historial',
      'Editar Registros',
      'Acceso a Seguridad',
      'Exportar Reportes'
    ];

    final List<String> selectedPermissions = List.from(role.permissions);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
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
                  maxWidth: 500,
                  maxHeight: isMobile ? size.height * 0.9 : size.height * 0.85,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
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
                          const Text(
                            'Editar Rol',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    // Form content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Nombre del Rol *',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: nameController,
                                style: const TextStyle(color: Colors.black87),
                                decoration: InputDecoration(
                                  hintText: 'Ej. Supervisor de Proyectos',
                                  hintStyle: const TextStyle(color: Colors.black38),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'El nombre es obligatorio';
                                  if (v.trim().toLowerCase() != role.name.trim().toLowerCase() && 
                                      _roles.any((r) => r.trim().toLowerCase() == v.trim().toLowerCase())) {
                                    return 'Este rol ya existe en el sistema';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              const Text(
                                'Descripción *',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: descController,
                                maxLines: 2,
                                style: const TextStyle(color: Colors.black87),
                                decoration: InputDecoration(
                                  hintText: 'Ej. Encargado de fiscalizar censos y ayuda local.',
                                  hintStyle: const TextStyle(color: Colors.black38),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                validator: (v) => v == null || v.isEmpty ? 'La descripción es obligatoria' : null,
                              ),
                              const SizedBox(height: 16),

                              const Text(
                                'Asignar Permisos del Rol',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 15),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: availablePermissions.map((perm) {
                                  final isSelected = selectedPermissions.contains(perm);
                                  return FilterChip(
                                    label: Text(
                                      perm,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.black87,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 12,
                                      ),
                                    ),
                                    selected: isSelected,
                                    selectedColor: const Color(0xFF416FDF),
                                    checkmarkColor: Colors.white,
                                    backgroundColor: Colors.grey.shade100,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(color: isSelected ? Colors.transparent : Colors.black12),
                                    ),
                                    onSelected: (val) {
                                      setStateModal(() {
                                        if (val) {
                                          selectedPermissions.add(perm);
                                        } else {
                                          selectedPermissions.remove(perm);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Footer
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
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                final oldName = role.name;
                                final newName = nameController.text.trim();
                                setState(() {
                                  final idx = _systemRoles.indexWhere((r) => r.name == role.name);
                                  if (idx != -1) {
                                    _systemRoles[idx] = SystemRole(
                                      name: newName,
                                      description: descController.text.trim(),
                                      permissions: selectedPermissions.isEmpty
                                          ? ['Acceso Básico']
                                          : List.from(selectedPermissions),
                                    );
                                  }
                                  if (newName != oldName) {
                                    for (var i = 0; i < _users.length; i++) {
                                      if (_users[i].role == oldName) {
                                        _users[i] = _users[i].copyWith(role: newName);
                                      }
                                    }
                                  }
                                });
                                Navigator.pop(dialogContext);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Rol "$newName" actualizado con éxito.'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
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

  void _confirmDeleteRole(SystemRole role) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar Rol', style: TextStyle(color: Colors.black87)),
          ],
        ),
        content: Text(
          '¿Está seguro de eliminar el rol "${role.name}"? Los usuarios con este rol serán reasignados al rol "Operador".',
          style: const TextStyle(color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                _systemRoles.removeWhere((r) => r.name == role.name);
                for (var i = 0; i < _users.length; i++) {
                  if (_users[i].role == role.name) {
                    _users[i] = _users[i].copyWith(role: 'Operador');
                  }
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Rol "${role.name}" eliminado correctamente.'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
