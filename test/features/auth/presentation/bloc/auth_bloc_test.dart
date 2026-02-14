import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:social_management_pro/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:social_management_pro/features/auth/domain/usecases/login_usecase.dart';
import 'package:social_management_pro/features/auth/domain/usecases/logout_usecase.dart';
import 'package:social_management_pro/features/auth/domain/usecases/check_auth_status_usecase.dart';
import 'package:social_management_pro/core/usecases/usecase.dart';
import 'package:dartz/dartz.dart';

class MockLogin extends Mock implements Login {}
class MockLogout extends Mock implements Logout {}
class MockCheckAuthStatus extends Mock implements CheckAuthStatus {}

void main() {
  late AuthBloc authBloc;
  late MockLogin mockLogin;
  late MockLogout mockLogout;
  late MockCheckAuthStatus mockCheckAuthStatus;

  setUp(() {
    mockLogin = MockLogin();
    mockLogout = MockLogout();
    mockCheckAuthStatus = MockCheckAuthStatus();
    authBloc = AuthBloc(
      login: mockLogin,
      logout: mockLogout,
      checkAuthStatus: mockCheckAuthStatus,
    );
  });

  test('initial state is AuthInitial', () {
    expect(authBloc.state, AuthInitial());
  });

  blocTest<AuthBloc, AuthState>(
    'emits [AuthUnauthenticated] when check status returns null',
    build: () {
      when(() => mockCheckAuthStatus(NoParams())).thenAnswer((_) async => const Right(null));
      return authBloc;
    },
    act: (bloc) => bloc.add(AuthCheckRequested()),
    expect: () => [AuthUnauthenticated()],
  );
}
