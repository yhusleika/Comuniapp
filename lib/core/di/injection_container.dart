import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/check_auth_status_usecase.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';

import '../../features/habitants/domain/repositories/habitants_repository.dart';
import '../../features/habitants/data/repositories/habitants_repository_impl.dart';
import '../../features/habitants/data/datasources/habitants_local_data_source.dart';
import '../../features/habitants/presentation/bloc/habitants_bloc.dart';
import '../../features/habitants/domain/usecases/get_habitants.dart';
import '../../features/habitants/domain/usecases/add_habitante.dart';
import '../../features/habitants/domain/usecases/update_habitante.dart';
import '../../features/habitants/domain/usecases/delete_habitante.dart';

import '../../features/reports/domain/usecases/get_reports.dart';
import '../../features/reports/domain/usecases/create_report.dart';
import '../../features/reports/domain/repositories/reports_repository.dart';
import '../../features/reports/data/repositories/reports_repository_impl.dart';
import '../../features/reports/data/datasources/reports_local_data_source.dart';
import '../../features/reports/presentation/bloc/reports_bloc.dart';

import '../../features/ayudas/domain/repositories/ayudas_repository.dart';
import '../../features/ayudas/data/repositories/ayudas_repository_impl.dart';
import '../../features/ayudas/data/datasources/ayudas_local_data_source.dart';
import '../../features/ayudas/presentation/bloc/ayudas_bloc.dart';
import '../../features/ayudas/domain/usecases/get_ayuda_types.dart';
import '../../features/ayudas/domain/usecases/add_ayuda_type.dart';
import '../../features/ayudas/domain/usecases/update_ayuda_type.dart';
import '../../features/ayudas/domain/usecases/delete_ayuda_type.dart';

import '../../features/censos/domain/repositories/censos_repository.dart';
import '../../features/censos/data/repositories/censos_repository_impl.dart';
import '../../features/censos/data/datasources/censos_local_data_source.dart';
import '../../features/censos/presentation/bloc/censos_bloc.dart';
import '../../features/censos/domain/usecases/censos_usecases.dart';

import '../../core/services/image_compression_service.dart';
import '../../core/services/sync_manager.dart';
import '../../core/services/mongodb_service.dart';
import '../../core/theme/theme_cubit.dart';
import '../../core/network/network_info.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ! Features - Auth
  // Bloc
  sl.registerFactory(() => AuthBloc(
        login: sl(),
        logout: sl(),
        checkAuthStatus: sl(),
      ));
// ... (omitting intermediate code matching precisely)

  // Use cases
  sl.registerLazySingleton(() => Login(sl()));
  sl.registerLazySingleton(() => Logout(sl()));
  sl.registerLazySingleton(() => CheckAuthStatus(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
        localDataSource: sl(),
      ));

  // Data sources
  sl.registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl());

  // ! Features - Habitants
  // Bloc
  sl.registerFactory(() => HabitantsBloc(
        getHabitants: sl(),
        addHabitante: sl(),
        updateHabitante: sl(),
        deleteHabitante: sl(),
      ));

  // Use cases
  sl.registerLazySingleton(() => GetHabitants(sl()));
  sl.registerLazySingleton(() => AddHabitante(sl()));
  sl.registerLazySingleton(() => UpdateHabitante(sl()));
  sl.registerLazySingleton(() => DeleteHabitante(sl()));

  // Repository
  sl.registerLazySingleton<HabitantsRepository>(() => HabitantsRepositoryImpl(
        localDataSource: sl(),
        networkInfo: sl(),
        mongoDBService: sl(),
      ));

  // Data sources
  sl.registerLazySingleton<HabitantsLocalDataSource>(
      () => HabitantsLocalDataSourceImpl());

  // ! Features - Reports
  // Bloc
  sl.registerFactory(() => ReportsBloc(
        getReports: sl(),
        createReport: sl(),
      ));

  // Use cases
  sl.registerLazySingleton(() => GetReports(sl()));
  sl.registerLazySingleton(() => CreateReport(sl()));

  // Repository
  sl.registerLazySingleton<ReportsRepository>(() => ReportsRepositoryImpl(
        localDataSource: sl(),
        networkInfo: sl(),
        mongoDBService: sl(),
      ));

  // Data sources
  sl.registerLazySingleton<ReportsLocalDataSource>(
      () => ReportsLocalDataSourceImpl());

  // ! Features - Ayudas
  // Bloc
  sl.registerFactory(() => AyudasBloc(
        getAyudaTypes: sl(),
        addAyudaType: sl(),
        updateAyudaType: sl(),
        deleteAyudaType: sl(),
      ));

  // Use cases
  sl.registerLazySingleton(() => GetAyudaTypes(sl()));
  sl.registerLazySingleton(() => AddAyudaType(sl()));
  sl.registerLazySingleton(() => UpdateAyudaType(sl()));
  sl.registerLazySingleton(() => DeleteAyudaType(sl()));

  // Repository
  sl.registerLazySingleton<AyudasRepository>(() => AyudasRepositoryImpl(
        localDataSource: sl(),
      ));

  // Data sources
  sl.registerLazySingleton<AyudasLocalDataSource>(
      () => AyudasLocalDataSourceImpl());

  // ! Features - Censos
  // Bloc
  sl.registerFactory(() => CensosBloc(
        getCensos: sl(),
        addCenso: sl(),
        getCensoRecords: sl(),
        addCensoRecord: sl(),
        updateCensoRecord: sl(),
        deleteCensoRecord: sl(),
      ));

  // Use cases
  sl.registerLazySingleton(() => GetCensos(sl()));
  sl.registerLazySingleton(() => AddCenso(sl()));
  sl.registerLazySingleton(() => GetCensoRecords(sl()));
  sl.registerLazySingleton(() => AddCensoRecord(sl()));
  sl.registerLazySingleton(() => UpdateCensoRecord(sl()));
  sl.registerLazySingleton(() => DeleteCensoRecord(sl()));

  // Repository
  sl.registerLazySingleton<CensosRepository>(() => CensosRepositoryImpl(
        localDataSource: sl(),
      ));

  // Data sources
  sl.registerLazySingleton<CensosLocalDataSource>(
      () => CensosLocalDataSourceImpl());

  // ! Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // Core services
  sl.registerLazySingleton(() => Connectivity());
  sl.registerLazySingleton(() => ImageCompressionService());
  sl.registerLazySingleton(() => MongoDBService());
  sl.registerLazySingleton(() => ThemeCubit());

  // Sync
  sl.registerLazySingleton(() => SyncManager(
        connectivity: sl(),
        habitantsRepository: sl(),
        reportsRepository: sl(),
        mongoDBService: sl(),
      ));
}
