import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/menu_item.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

class SideMenu extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const SideMenu({
    super.key,
    this.scaffoldKey,
  });

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  @override
  Widget build(BuildContext context) {
    final hasNotch = MediaQuery.of(context).viewPadding.top > 35;
    final authState = context.watch<AuthBloc>().state;
    final String userRole = authState is AuthAuthenticated ? authState.user.role.toLowerCase().trim() : 'visor';

    final filteredMenuItems = appMenuItems.where((item) {
      if (item.link == '/administracion') {
        return userRole.contains('admin');
      }
      return true;
    }).toList();

    final String currentRoute = GoRouterState.of(context).matchedLocation;
    int selectedIndex = filteredMenuItems.indexWhere((item) => item.link == currentRoute);
    if (selectedIndex == -1) {
      // check if it starts with the link (e.g. details pages)
      selectedIndex = filteredMenuItems.indexWhere((item) => item.link != '/' && currentRoute.startsWith(item.link));
      if (selectedIndex == -1) {
        selectedIndex = 0;
      }
    }

    return NavigationDrawer(
      elevation: 1,
      selectedIndex: selectedIndex,
      onDestinationSelected: (value) {
        final menuItem = filteredMenuItems[value];
        context.push(menuItem.link);
        widget.scaffoldKey?.currentState?.closeDrawer();
      },
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(28, hasNotch ? 10 : 20, 16, 10),
          child: Image.asset(
            'assets/images/comuniApp_removebg.png',
            height: 100,
            fit: BoxFit.contain,
          ),
        ),
        ...filteredMenuItems.map(
          (item) => NavigationDrawerDestination(
            icon: Icon(item.icon),
            label: Text(item.title),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(28, 16, 28, 10),
          child: Divider(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: FilledButton(
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
              context.go('/login');
              widget.scaffoldKey?.currentState?.closeDrawer();
            },
            child: const Text('Cerrar sesión'),
          ),
        ),
      ],
    );
  }
}
