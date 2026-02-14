import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../features/auth/presentation/pages/login_page.dart';
import '../../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../../features/habitants/presentation/pages/habitants_page.dart';
import '../../../features/reports/presentation/pages/reports_page.dart';
import '../../../features/profile/presentation/pages/profile_page.dart';
import '../../../features/street_info/presentation/pages/street_info_page.dart';
import '../../../features/ayudas/presentation/pages/ayudas_page.dart';
import '../../../features/censos/presentation/pages/censos_page.dart';
import '../../../features/eventos/presentation/pages/eventos_page.dart';
import '../../../features/eventos/presentation/pages/eventos_details_page.dart';
import '../../../features/eventos/domain/models/management_models.dart';
import '../../../features/estadisticas/presentation/pages/estadisticas_page.dart';
import '../../../features/configuracion/presentation/pages/configuracion_page.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import 'auth_notifier.dart';

GoRouter createAppRouter(AuthNotifier authNotifier) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authNotifier,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const RootPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/habitants',
        builder: (context, state) => const HabitantsPage(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsPage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/street-info',
        builder: (context, state) => const StreetInfoPage(),
      ),
      GoRoute(
        path: '/ayudas',
        builder: (context, state) => const AyudasPage(),
      ),
      GoRoute(
        path: '/censos',
        builder: (context, state) => const CensosPage(),
      ),
      GoRoute(
        path: '/eventos',
        builder: (context, state) => const EventosPage(),
      ),
      GoRoute(
        path: '/estadisticas',
        builder: (context, state) => const EstadisticasPage(),
      ),
      GoRoute(
        path: '/configuracion',
        builder: (context, state) => const ConfiguracionPage(),
      ),
      GoRoute(
        path: '/eventos/details',
        builder: (context, state) {
          final item = state.extra as ManagementItem;
          return EventosDetailsPage(item: item);
        },
      ),
    ],
    redirect: (context, state) {
      final authState = authNotifier.authBloc.state; // Use direct reference
      final isLoggingIn = state.matchedLocation == '/login';

      print('Router Redirect Check:');
      print(' - Location: ${state.matchedLocation}');
      print(' - AuthState: $authState');

      if (authState is AuthInitial || authState is AuthLoading) {
        print(' - Result: null (loading/initial)');
        return null;
      }

      if (authState is! AuthAuthenticated) {
        final result = isLoggingIn ? null : '/login';
        print(' - Result: $result (not authenticated)');
        return result;
      }

      if (isLoggingIn) {
        print(' - Result: /dashboard (authenticated, redirecting from login)');
        return '/dashboard';
      }

      print(' - Result: null (authenticated, allowed)');
      return null;
    },
  );
}

class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return const DashboardPage();
        }
        return const LoginPage();
      },
    );
  }
}
