import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_scaffold.dart';
import '../../../../shared/widgets/side_menu.dart';

class ConfiguracionPage extends StatelessWidget {
  const ConfiguracionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return CustomScaffold(
      drawer: SideMenu(scaffoldKey: scaffoldKey),
      child: const Center(
        child: Text(
          'Configuración',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}
