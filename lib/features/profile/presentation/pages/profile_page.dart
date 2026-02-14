import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../shared/widgets/custom_scaffold.dart';
import '../../../../shared/widgets/side_menu.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _personalDataKey = GlobalKey<FormState>();
  bool _isEditable = false;
  File? _image;
  final _picker = ImagePicker();

  // Controllers for personal data
  final _nombreController = TextEditingController(text: 'Admin');
  final _apellidoController = TextEditingController(text: 'User');
  final _cedulaController = TextEditingController(text: '12345678');
  final _correoController = TextEditingController(text: 'admin@example.com');
  final _telefonoController = TextEditingController(text: '04121234567');

  // Controllers for security
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _isPasswordButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _currentPassController.addListener(_validatePasswordFields);
    _newPassController.addListener(_validatePasswordFields);
    _confirmPassController.addListener(_validatePasswordFields);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _cedulaController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _validatePasswordFields() {
    final current = _currentPassController.text;
    final newPass = _newPassController.text;
    final confirm = _confirmPassController.text;

    setState(() {
      _isPasswordButtonEnabled = current.isNotEmpty &&
          newPass.isNotEmpty &&
          confirm.isNotEmpty &&
          newPass.length >= 8 &&
          newPass == confirm;
    });
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _savePersonalData() {
    if (_personalDataKey.currentState!.validate()) {
      setState(() {
        _isEditable = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos guardados exitosamente')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    final theme = Theme.of(context);

    return CustomScaffold(
      drawer: SideMenu(scaffoldKey: scaffoldKey),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // Header & Identity
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        backgroundImage:
                            _image != null ? FileImage(_image!) : null,
                        child: _image == null
                            ? Icon(Icons.person,
                                size: 80,
                                color: theme.colorScheme.onPrimaryContainer)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: theme.colorScheme.primary,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, size: 18),
                            color: theme.colorScheme.onPrimary,
                            onPressed: _pickImage,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Admin User',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Administrador del Sistema',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Tab Navigation inside a themed container
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
                        Tab(text: 'Datos Personales'),
                        Tab(text: 'Seguridad'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Tab 1: Datos Personales
                          _buildPersonalDataTab(theme),
                          // Tab 2: Seguridad
                          _buildSecurityTab(theme),
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

  Widget _buildPersonalDataTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _personalDataKey,
        child: Column(
          children: [
            _buildTextField(
              label: 'Nombre',
              controller: _nombreController,
              readOnly: !_isEditable,
              icon: Icons.person_outline,
              theme: theme,
            ),
            _buildTextField(
              label: 'Apellido',
              controller: _apellidoController,
              readOnly: !_isEditable,
              icon: Icons.person_outline,
              theme: theme,
            ),
            _buildTextField(
              label: 'Cédula',
              controller: _cedulaController,
              readOnly: !_isEditable,
              icon: Icons.badge_outlined,
              keyboardType: TextInputType.number,
              theme: theme,
            ),
            _buildTextField(
              label: 'Correo Electrónico',
              controller: _correoController,
              readOnly: !_isEditable,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              theme: theme,
            ),
            _buildTextField(
              label: 'Teléfono',
              controller: _telefonoController,
              readOnly: !_isEditable,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              theme: theme,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _isEditable
                    ? _savePersonalData
                    : () => setState(() => _isEditable = true),
                child: Text(_isEditable ? 'Guardar Cambios' : 'Editar Perfil'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildTextField(
            label: 'Contraseña Actual',
            controller: _currentPassController,
            icon: Icons.lock_outline,
            obscureText: true,
            theme: theme,
          ),
          _buildTextField(
            label: 'Nueva Contraseña',
            controller: _newPassController,
            icon: Icons.lock_reset_outlined,
            obscureText: true,
            hint: 'Escribe al menos 8 caracteres',
            theme: theme,
          ),
          _buildTextField(
            label: 'Confirmar Contraseña',
            controller: _confirmPassController,
            icon: Icons.lock_clock_outlined,
            obscureText: true,
            theme: theme,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _isPasswordButtonEnabled
                  ? () {
                      // Acción de actualización
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Contraseña actualizada')),
                      );
                    }
                  : null,
              child: const Text('Actualizar Contraseña'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required ThemeData theme,
    bool readOnly = false,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        obscureText: obscureText,
        keyboardType: keyboardType,
        enableSuggestions: !obscureText,
        autocorrect: !obscureText,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: theme.colorScheme.primary),
          labelStyle: const TextStyle(color: Colors.black54),
          hintStyle: const TextStyle(color: Colors.black38),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: theme.colorScheme.primary),
          ),
          fillColor: Colors.grey.shade50,
          filled: true,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Este campo es obligatorio';
          }
          return null;
        },
      ),
    );
  }
}
