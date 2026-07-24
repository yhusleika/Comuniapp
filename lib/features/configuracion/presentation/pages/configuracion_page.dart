import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import '../../../../shared/widgets/custom_scaffold.dart';
import '../../../../shared/widgets/side_menu.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/mongodb_service.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class ConfiguracionPage extends StatefulWidget {
  const ConfiguracionPage({super.key});

  @override
  State<ConfiguracionPage> createState() => _ConfiguracionPageState();
}

class _ConfiguracionPageState extends State<ConfiguracionPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _syncNotifications = true;

  // Real-time DB sync status
  String _syncStatusText = 'Sincronizado con la nube';
  Color _syncStatusColor = Colors.green;
  IconData _syncStatusIcon = Icons.cloud_done_outlined;
  bool _isCheckingSync = false;

  // Controllers for password change inside System Settings
  final _securityKey = GlobalKey<FormState>();
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _showPasswordFields = false;
  bool _isPasswordButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _currentPassController.addListener(_validatePasswordFields);
    _newPassController.addListener(_validatePasswordFields);
    _confirmPassController.addListener(_validatePasswordFields);
    _checkNetworkSyncStatus();
  }

  @override
  void dispose() {
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _checkNetworkSyncStatus() async {
    setState(() {
      _isCheckingSync = true;
      _syncStatusText = 'Sincronizando con la nube...';
      _syncStatusColor = Colors.orange;
      _syncStatusIcon = Icons.sync;
    });

    try {
      final networkInfo = sl<NetworkInfo>();
      final isConnected = await networkInfo.isConnected;
      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        setState(() {
          _isCheckingSync = false;
          if (isConnected) {
            _syncStatusText = 'Sincronizado con la nube';
            _syncStatusColor = Colors.green;
            _syncStatusIcon = Icons.cloud_done_outlined;
          } else {
            _syncStatusText = 'Modo offline';
            _syncStatusColor = Colors.deepOrange;
            _syncStatusIcon = Icons.cloud_off_outlined;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isCheckingSync = false;
          _syncStatusText = 'Modo offline';
          _syncStatusColor = Colors.deepOrange;
          _syncStatusIcon = Icons.cloud_off_outlined;
        });
      }
    }
  }

  void _validatePasswordFields() {
    final current = _currentPassController.text;
    final newPass = _newPassController.text;
    final confirm = _confirmPassController.text;

    setState(() {
      _isPasswordButtonEnabled = current.isNotEmpty &&
          newPass.isNotEmpty &&
          confirm.isNotEmpty &&
          newPass == confirm;
    });
  }

  Future<void> _updatePassword() async {
    if (_securityKey.currentState!.validate()) {
      // Get the current user info
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: no hay sesión activa'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final currentUser = authState.user;
      final currentPass = _currentPassController.text;
      final newPass = _newPassController.text;

      // Verify current password locally first
      final recoveredBox = await Hive.openBox('recovered_credentials');
      final storedPass = recoveredBox.get(currentUser.username);

      if (storedPass != null && storedPass != currentPass) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La contraseña actual es incorrecta'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      try {
        // Update password in the backend
        final mongo = sl<MongoDBService>();
        bool success = false;
        try {
          final response = await mongo.dio.put('/users/profile', data: {
            'username': currentUser.username,
            'password': newPass,
          });
          success = response.statusCode == 200;
        } catch (_) {}

        // Also update locally in Hive
        await recoveredBox.put(currentUser.username, newPass);

        _currentPassController.clear();
        _newPassController.clear();
        _confirmPassController.clear();
        setState(() {
          _showPasswordFields = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success
                  ? 'Contraseña actualizada exitosamente'
                  : 'Contraseña actualizada localmente (sin conexión al servidor)'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al actualizar contraseña: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScaffold(
      scaffoldKey: scaffoldKey,
      drawer: SideMenu(scaffoldKey: scaffoldKey),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configuración de Sistema',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Gestiona el estado de sincronización y la seguridad de tu cuenta',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // DB Sync Card Container
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Notifications Switch
                  SwitchListTile(
                    value: _syncNotifications,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (val) {
                      setState(() {
                        _syncNotifications = val;
                      });
                    },
                    title: const Text(
                      'Notificaciones de Sincronización',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: const Text(
                      'Alertar al completarse la sincronización en segundo plano',
                      style: TextStyle(color: Colors.black54),
                    ),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const Divider(height: 1),

                  // Real-Time DB Sync Status ListTile
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _syncStatusColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _syncStatusIcon,
                        color: _syncStatusColor,
                      ),
                    ),
                    title: const Text(
                      'Estado de la Base de Datos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      _syncStatusText,
                      style: TextStyle(color: _syncStatusColor, fontWeight: FontWeight.w600),
                    ),
                    trailing: _isCheckingSync
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.black54),
                            onPressed: _checkNetworkSyncStatus,
                            tooltip: 'Comprobar sincronización',
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Embedded Password Change Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _securityKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF416FDF).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lock_outline, color: Color(0xFF416FDF)),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Seguridad de la Cuenta',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showPasswordFields = !_showPasswordFields;
                            });
                          },
                          icon: Icon(_showPasswordFields ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                          label: Text(_showPasswordFields ? 'Ocultar' : 'Cambiar Contraseña'),
                        ),
                      ],
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _showPasswordFields
                          ? Column(
                              children: [
                                const SizedBox(height: 16),
                                _buildPasswordField(
                                  label: 'Contraseña Actual',
                                  controller: _currentPassController,
                                  icon: Icons.lock_outline,
                                ),
                                _buildPasswordField(
                                  label: 'Nueva Contraseña',
                                  controller: _newPassController,
                                  icon: Icons.lock_reset_outlined,
                                ),
                                _buildPasswordField(
                                  label: 'Confirmar Contraseña',
                                  controller: _confirmPassController,
                                  icon: Icons.lock_clock_outlined,
                                  validator: (value) {
                                    if (value != _newPassController.text) {
                                      return 'Las contraseñas no coinciden';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  height: 46,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF416FDF),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: _isPasswordButtonEnabled ? _updatePassword : null,
                                    child: const Text('Actualizar Contraseña', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
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

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    FormFieldValidator<String>? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: true,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF416FDF)),
          labelStyle: const TextStyle(color: Colors.black54),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.black12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF416FDF)),
          ),
          fillColor: Colors.grey.shade50,
          filled: true,
        ),
        validator: validator ??
            (value) {
              if (value == null || value.isEmpty) {
                return 'Este campo es obligatorio';
              }
              return null;
            },
      ),
    );
  }
}
