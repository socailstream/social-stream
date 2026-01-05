import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import 'states/auth_state.dart';

final authViewmodelProvider = StateNotifierProvider<AuthViewmodel, AuthState>((ref) {
    return AuthViewmodel(AuthRepository());
  });


class AuthViewmodel extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthViewmodel(this._repo) : super(const AuthState());


  Future<void> signUp(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, error: null );

    try {
      final user = await _repo.signUp(email, password, name);
      state = state.copyWith(user:user);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } 
    finally {
      state = state.copyWith(isLoading: false);
    }

  }

   
}

