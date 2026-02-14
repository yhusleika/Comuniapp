import 'package:flutter/material.dart';
import '../../../../shared/widgets/custom_scaffold.dart';
import '../../../../shared/widgets/side_menu.dart';

class StreetInfoPage extends StatelessWidget {
  const StreetInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return CustomScaffold(
      drawer: SideMenu(scaffoldKey: scaffoldKey),
      child: const Center(
        child: Text(
          'Información de Calle',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}
