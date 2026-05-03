import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection_container.dart' as di;
import 'core/services/sync_manager.dart';
import 'core/services/hive_config.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/router/auth_notifier.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveConfig.init();
  await di.init();
  di.sl<SyncManager>().init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthBloc _authBloc;
  late final AuthNotifier _authNotifier;

  @override
  void initState() {
    super.initState();
    _authBloc = di.sl<AuthBloc>()..add(AuthCheckRequested());
    _authNotifier = AuthNotifier(_authBloc);
  }

  @override
  void dispose() {
    _authNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
      ],
      child: MaterialApp.router(
        title: 'Comuniapp',
        debugShowCheckedModeBanner: false,
        theme: AppTheme().getTheme(),
        routerConfig: createAppRouter(_authNotifier),
      ),
    );
  }
}
