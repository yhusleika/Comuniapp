import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:social_management_pro/core/error/failures.dart';
import 'package:social_management_pro/core/usecases/usecase.dart';
import 'package:social_management_pro/features/dashboard/domain/entities/dashboard_stats.dart';
import 'package:social_management_pro/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:social_management_pro/features/dashboard/domain/usecases/get_dashboard_stats.dart';

class MockDashboardRepository extends Mock implements DashboardRepository {}

void main() {
  late GetDashboardStats usecase;
  late MockDashboardRepository mockRepository;

  setUp(() {
    mockRepository = MockDashboardRepository();
    usecase = GetDashboardStats(mockRepository);
  });

  final tStats = DashboardStats(
    counts: {'habitants': 100, 'reports': 20, 'censos': 5, 'ayudas': 10, 'eventos': 3},
    recentActivity: [],
    eventos: [],
  );

  test('should return DashboardStats from repository', () async {
    when(() => mockRepository.getStats())
        .thenAnswer((_) async => Right(tStats));

    final result = await usecase(NoParams());

    expect(result, Right(tStats));
    verify(() => mockRepository.getStats()).called(1);
  });

  test('should return Failure when repository fails', () async {
    when(() => mockRepository.getStats())
        .thenAnswer((_) async => Left(ServerFailure('Error')));

    final result = await usecase(NoParams());

    expect(result, Left(ServerFailure('Error')));
  });
}
