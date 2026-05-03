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
    title: 'Dashboard',
    link: '/dashboard',
    icon: Icons.dashboard,
  ),
  MenuItem(
    title: 'Perfil',
    link: '/profile',
    icon: Icons.person_outline,
  ),
  MenuItem(
    title: 'Información de calle',
    link: '/street-info',
    icon: Icons.add_road,
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
    title: 'Eventos/Jornadas/Proyectos',
    link: '/eventos',
    icon: Icons.event_note_outlined,
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
