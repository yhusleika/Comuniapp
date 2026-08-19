import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/hive_config.dart';
import '../../../../core/services/mongodb_service.dart';
import '../../../../shared/widgets/custom_scaffold.dart';
import '../../../habitantes/data/models/habitante_model.dart';
import '../bloc/auth_bloc.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginForm();
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthLoginRequested(
          username: _usernameController.text,
          password: _passwordController.text,
        ),
      );
    }
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ForgotPasswordDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScaffold(
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          return Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(25, 40, 25, 30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Bienvenido de nuevo',
                            style: TextStyle(
                              fontSize: 30.0,
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 40.0),
                          TextFormField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Usuario',
                              hintText: 'Ingrese su usuario',
                            ),
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) {
                              FocusScope.of(context).requestFocus(_passwordFocusNode);
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingrese su usuario';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 25.0),
                          TextFormField(
                            controller: _passwordController,
                            focusNode: _passwordFocusNode,
                            decoration: const InputDecoration(
                              labelText: 'Contraseña',
                              hintText: 'Ingrese su contraseña',
                            ),
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submitLogin(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingrese su contraseña';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8.0),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showForgotPasswordDialog,
                              child: const Text(
                                '¿Olvidaste tu contraseña?',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF416FDF),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20.0),
                          if (state is AuthLoading)
                            const CircularProgressIndicator()
                          else
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _submitLogin,
                                child: const Text('Iniciar Sesión'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog({super.key});

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  int _step = 1;
  bool _isLoadingUser = false;
  bool _isSaving = false;

  final _identifierController = TextEditingController();
  final _ans1Controller = TextEditingController();
  final _ans2Controller = TextEditingController();
  final _ans3Controller = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  String _targetUsername = '';
  String _targetCedula = '';
  String _targetEmail = '';
  Map<String, dynamic>? _habitanteData;

  // Preguntas generadas
  String _q1Text = '';
  String _q2Text = '';
  String _q3Text = '';

  @override
  void dispose() {
    _identifierController.dispose();
    _ans1Controller.dispose();
    _ans2Controller.dispose();
    _ans3Controller.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserDataAndQuestions() async {
    if (!_formKey1.currentState!.validate()) return;

    setState(() {
      _isLoadingUser = true;
    });

    final input = _identifierController.text.trim().toLowerCase();
    String foundUsername = '';
    String foundCedula = '';
    String foundEmail = '';
    Map<String, dynamic>? habitanteMatch;

    try {
      final mongo = sl<MongoDBService>();
      final users = await mongo.getUsers();
      for (var u in users) {
        final uname = (u['username'] ?? '').toString().toLowerCase();
        final ced = (u['cedula'] ?? '').toString().trim();
        final email = (u['email'] ?? '').toString().trim();

        if (uname == input || (ced.isNotEmpty && ced == input) || (email.isNotEmpty && email == input)) {
          foundUsername = uname;
          foundCedula = ced;
          foundEmail = email;
          break;
        }
      }
    } catch (_) {}

    if (foundUsername.isEmpty) {
      try {
        final usersBox = await Hive.openBox('system_users_box');
        for (var val in usersBox.values) {
          if (val is Map) {
            final uname = (val['username'] ?? '').toString().toLowerCase();
            final ced = (val['cedula'] ?? '').toString().trim();
            final email = (val['email'] ?? '').toString().trim();

            if (uname == input || (ced.isNotEmpty && ced == input) || (email.isNotEmpty && email == input)) {
              foundUsername = uname;
              foundCedula = ced;
              foundEmail = email;
              break;
            }
          }
        }
      } catch (_) {}
    }

    if (foundUsername.isEmpty) {
      foundUsername = input;
    }

    // Buscar el habitante correspondiente por Cédula o Nombre
    try {
      final mongo = sl<MongoDBService>();
      final remoteHabitants = await mongo.getRecords('habitants', queryParameters: {'limit': 1000});
      for (var h in remoteHabitants) {
        final ced = (h['cedula'] ?? '').toString().trim();
        if ((foundCedula.isNotEmpty && ced == foundCedula) || ced == input) {
          habitanteMatch = Map<String, dynamic>.from(h);
          if (foundCedula.isEmpty) foundCedula = ced;
          break;
        }
      }
    } catch (_) {}

    if (habitanteMatch == null) {
      try {
        final box = Hive.isBoxOpen(HiveConfig.habitantsBox)
            ? Hive.box(HiveConfig.habitantsBox)
            : await Hive.openBox(HiveConfig.habitantsBox);
        for (var h in box.values) {
          if (h is HabitanteModel) {
            if ((foundCedula.isNotEmpty && h.cedula == foundCedula) || h.cedula == input) {
              habitanteMatch = {
                'nombres': h.nombres,
                'apellidos': h.apellidos,
                'cedula': h.cedula,
                'telefono': h.telefono,
                'fechaNacimiento': h.fechaNacimiento,
                'tieneDiscapacidad': h.tieneDiscapacidad,
                'discapacidadDetalle': h.detallesDiscapacidad,
              };
              if (foundCedula.isEmpty) foundCedula = h.cedula;
              break;
            }
          } else if (h is Map) {
            final ced = (h['cedula'] ?? '').toString().trim();
            if ((foundCedula.isNotEmpty && ced == foundCedula) || ced == input) {
              habitanteMatch = Map<String, dynamic>.from(h);
              if (foundCedula.isEmpty) foundCedula = ced;
              break;
            }
          }
        }
      } catch (_) {}
    }

    if (!mounted) return;

    setState(() {
      _isLoadingUser = false;
      _targetUsername = foundUsername;
      _targetCedula = foundCedula;
      _targetEmail = foundEmail;
      _habitanteData = habitanteMatch;

      if (_habitanteData != null) {
        final habitantName = '${_habitanteData!['nombres'] ?? ''} ${_habitanteData!['apellidos'] ?? ''}'.trim();
        _q1Text = '1. ¿Cuál es el número de teléfono registrado del habitante (${habitantName.isEmpty ? _targetUsername : habitantName})?';
        _q2Text = '2. ¿Cuál es la fecha de nacimiento (DD/MM/AAAA) o año de nacimiento registrado del habitante?';
        _q3Text = '3. ¿Posee el habitante alguna discapacidad registrada? (Responda Sí o No)';
      } else {
        _q1Text = '1. ¿Cuál es su Cédula de Identidad registrada?';
        _q2Text = '2. ¿Cuál es su correo electrónico registrado?';
        _q3Text = '';
      }

      _step = 2;
    });
  }

  void _verifySecurityAnswers() {
    if (!_formKey2.currentState!.validate()) return;

    bool isQ1Valid = false;
    bool isQ2Valid = false;
    bool isQ3Valid = true;

    final ans1Clean = _ans1Controller.text.trim().replaceAll(RegExp(r'\D'), '');
    final ans2Clean = _ans2Controller.text.trim().toLowerCase();
    final ans3Clean = _ans3Controller.text.trim().toLowerCase();

    if (_habitanteData != null) {
      // 1. Validar teléfono
      final realTelClean = (_habitanteData!['telefono'] ?? '').toString().replaceAll(RegExp(r'\D'), '');
      if (realTelClean.isNotEmpty) {
        isQ1Valid = (ans1Clean == realTelClean) ||
            (ans1Clean.length >= 7 && realTelClean.endsWith(ans1Clean)) ||
            (realTelClean.length >= 7 && ans1Clean.endsWith(realTelClean));
      } else {
        isQ1Valid = ans1Clean.isNotEmpty;
      }

      // 2. Validar Fecha / Año de Nacimiento (formato DD/MM/AAAA)
      final rawDateObj = _habitanteData!['fechaNacimiento'] ?? _habitanteData!['fecha_nacimiento'];
      String realFormattedDate = '';
      if (rawDateObj is DateTime) {
        realFormattedDate = DateFormat('dd/MM/yyyy').format(rawDateObj);
      } else if (rawDateObj != null) {
        final str = rawDateObj.toString().split('T').first.toLowerCase();
        if (str.contains('-')) {
          final parts = str.split('-');
          if (parts.length == 3 && parts[0].length == 4) {
            realFormattedDate = '${parts[2]}/${parts[1]}/${parts[0]}';
          } else {
            realFormattedDate = str;
          }
        } else {
          realFormattedDate = str;
        }
      }

      if (realFormattedDate.isNotEmpty) {
        final realFechaDigits = realFormattedDate.replaceAll(RegExp(r'\D'), '');
        final ans2Digits = ans2Clean.replaceAll(RegExp(r'\D'), '');

        isQ2Valid = ans2Clean == realFormattedDate ||
            (ans2Digits.isNotEmpty && realFechaDigits == ans2Digits) ||
            (ans2Digits.isNotEmpty && realFechaDigits.contains(ans2Digits)) ||
            (ans2Clean.length == 4 && realFormattedDate.contains(ans2Clean));
      } else {
        isQ2Valid = ans2Clean.isNotEmpty;
      }

      // 3. Validar Discapacidad
      final realDisc = _habitanteData!['tieneDiscapacidad'] ?? _habitanteData!['discapacidad'];
      final bool realHasDisc = realDisc == true || realDisc == 'Sí' || realDisc == 'Si' || (realDisc is String && realDisc.isNotEmpty && realDisc.toLowerCase() != 'no' && realDisc.toLowerCase() != 'ninguna');
      
      final bool userSaysYes = ans3Clean.contains('si') || ans3Clean.contains('sí') || ans3Clean == 'yes' || ans3Clean == 'true';
      final bool userSaysNo = ans3Clean.contains('no') || ans3Clean.contains('ningun') || ans3Clean == 'false';

      if (realHasDisc) {
        isQ3Valid = userSaysYes || (ans3Clean.length >= 3 && !userSaysNo);
      } else {
        isQ3Valid = userSaysNo || ans3Clean.contains('no posee') || ans3Clean.contains('ninguna');
      }
    } else {
      // Fallback para administradores de sistema sin habitante
      final realCedClean = _targetCedula.replaceAll(RegExp(r'\D'), '');
      isQ1Valid = realCedClean.isNotEmpty ? (ans1Clean == realCedClean) : true;
      isQ2Valid = _targetEmail.isNotEmpty ? ans2Clean.contains(_targetEmail.toLowerCase()) : true;
    }

    if (isQ1Valid && isQ2Valid && isQ3Valid) {
      setState(() {
        _step = 3;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las respuestas a las preguntas de seguridad no coinciden con los datos registrados.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey3.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final newPassword = _newPasswordController.text.trim();
      final mongo = sl<MongoDBService>();

      await mongo.resetPassword(_targetUsername, newPassword);

      final recoveredBox = await Hive.openBox(HiveConfig.recoveredCredentialsBox);
      await recoveredBox.put(_targetUsername, newPassword);
      if (_targetCedula.isNotEmpty) {
        await recoveredBox.put(_targetCedula, newPassword);
      }

      final usersBox = await Hive.openBox('system_users_box');
      if (usersBox.containsKey(_targetUsername)) {
        final uData = Map<String, dynamic>.from(usersBox.get(_targetUsername));
        uData['password'] = newPassword;
        await usersBox.put(_targetUsername, uData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contraseña restablecida con éxito. Ya puede iniciar sesión con su nueva clave.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar credenciales: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
      ),
      elevation: 20,
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shield_outlined, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Recuperación de Clave',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),
                _buildStepContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    if (_step == 1) {
      return Form(
        key: _formKey1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingrese su nombre de usuario o Cédula para generar las preguntas de seguridad de su perfil de habitante.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _identifierController,
              decoration: const InputDecoration(
                labelText: 'Usuario o Cédula *',
                prefixIcon: Icon(Icons.person_pin_outlined),
                hintText: 'Ej. jperez o 12345678',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingrese su usuario o cédula';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _isLoadingUser
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _fetchUserDataAndQuestions,
                      child: const Text('Continuar'),
                    ),
                  ),
          ],
        ),
      );
    } else if (_step == 2) {
      return Form(
        key: _formKey2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.help_outline, color: Color(0xFF416FDF)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Responda las siguientes preguntas de seguridad de su registro de habitante para verificar su identidad.',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Pregunta 1 ──
            Text(_q1Text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _ans1Controller,
              decoration: const InputDecoration(
                hintText: 'Ingrese la respuesta',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Respuesta requerida' : null,
            ),
            const SizedBox(height: 16),

            // ── Pregunta 2 ──
            Text(_q2Text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _ans2Controller,
              decoration: const InputDecoration(
                hintText: 'Ej. 15/05/1990 o 1990',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Respuesta requerida' : null,
            ),

            // ── Pregunta 3 (Si existe) ──
            if (_q3Text.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(_q3Text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _ans3Controller,
                decoration: const InputDecoration(
                  hintText: 'Responda Sí o No',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Respuesta requerida' : null,
              ),
            ],

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _step = 1),
                    child: const Text('Atrás'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _verifySecurityAnswers,
                    child: const Text('Verificar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return Form(
        key: _formKey3,
        child: Column(
          children: [
            const Text(
              'Respuestas validadas correctamente. Ingrese su nueva contraseña a continuación.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _newPasswordController,
              obscureText: _obscureNewPassword,
              decoration: InputDecoration(
                labelText: 'Nueva Contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureNewPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese su nueva contraseña';
                }
                if (value.length < 6) {
                  return 'Debe tener al menos 6 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirmar Contraseña',
                prefixIcon: const Icon(Icons.lock_reset),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              validator: (value) {
                if (value != _newPasswordController.text) {
                  return 'Las contraseñas no coinciden';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _isSaving
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _resetPassword,
                      child: const Text('Guardar Contraseña'),
                    ),
                  ),
          ],
        ),
      );
    }
  }
}

