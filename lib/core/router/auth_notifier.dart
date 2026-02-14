import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

class AuthNotifier extends ChangeNotifier {
  final AuthBloc authBloc;

  AuthNotifier(this.authBloc) {
    authBloc.stream.listen((state) {
      print('AuthNotifier: Received state change: $state');
      notifyListeners();
    });
  }

  bool get isAuthenticated => authBloc.state is AuthAuthenticated;
}
