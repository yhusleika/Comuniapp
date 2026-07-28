import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:social_management_pro/core/error/failures.dart';
import 'package:social_management_pro/core/usecases/usecase.dart';
import 'package:social_management_pro/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:social_management_pro/features/dashboard/domain/usecases/get_dashboard_stats.dart';
import 'package:social_management_pro/features/dashboard/presentation/bloc/dashboard_bloc.dart';

class MockGetDashboardStats extends Mock implements GetDashboardStats {}

void main() {
  late DashboardBloc bloc;
  late MockGetDashboardStats mockGetDashboardStats;

  setUpAll(() {
    registerFallbackValue(NoParams());
  });

  setUp(() {
    mockGetDashboardStats = MockGetDashboardStats();
    bloc = DashboardBloc(getDashboardStats: mockGetDashboardStats);
  });

  tearDown(() {
    bloc.close();
  });

  final tStats = DashboardStats(
    counts: {'habitants': 100, 'reports': 20, 'censos': 5, 'ayudas': 10, 'eventos': 3},
    recentActivity: [],
    eventos: [],
  );

  test('initial state is DashboardInitial', () {
    expect(bloc.state, DashboardInitial());
  });

  test('emits [DashboardLoading, DashboardLoaded] when successful', () async {
    when(() => mockGetDashboardStats(any()))
        .thenAnswer((_) async => Right(tStats));

    expectLater(
      bloc.stream,
      emitsInOrder([DashboardLoading(), DashboardLoaded(tStats)]),
    );

    bloc.add(const LoadDashboard());
  });

  test('emits [DashboardLoading, DashboardError] on failure', () async {
    when(() => mockGetDashboardStats(any()))
        .thenAnswer((_) async => Left(ServerFailure('Server error')));

    expectLater(
      bloc.stream,
      emitsInOrder([DashboardLoading(), DashboardError('Server error')]),
    );

    bloc.add(const LoadDashboard());
  });
}
