import 'package:flutter/material.dart';

class MenuItem {
  final String title;
  final String link;
  final IconData icon;

  const MenuItem({
    required this.title,
    required this.link,
    required this.icon,
  });
}

const appMenuItems = <MenuItem>[
  MenuItem(
    title: 'Inicio',
    link: '/dashboard',
    icon: Icons.home_outlined,
  ),
  MenuItem(
    title: 'Ayudas',
    link: '/ayudas',
    icon: Icons.volunteer_activism_outlined,
  ),
  MenuItem(
    title: 'Censos',
    link: '/censos',
    icon: Icons.analytics_outlined,
  ),
  MenuItem(
    title: 'Habitantes',
    link: '/habitants',
    icon: Icons.people_outline,
  ),
  MenuItem(
    title: 'Gestión de Actividades',
    link: '/eventos',
    icon: Icons.event_note_outlined,
  ),
  MenuItem(
    title: 'Administración',
    link: '/administracion',
    icon: Icons.admin_panel_settings_outlined,
  ),
  MenuItem(
    title: 'Auditoría',
    link: '/auditoria',
    icon: Icons.security_outlined,
  ),
  MenuItem(
    title: 'Estadísticas',
    link: '/estadisticas',
    icon: Icons.bar_chart_outlined,
  ),
  MenuItem(
    title: 'Configuración',
    link: '/configuracion',
    icon: Icons.settings_outlined,
  ),
];
