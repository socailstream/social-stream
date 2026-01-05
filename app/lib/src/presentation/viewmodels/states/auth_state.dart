import 'package:firebase_auth/firebase_auth.dart';


class AuthState {
  final bool isLoading;
  final String? error;
  final User? user;

  const AuthState({this.isLoading = false, this.error, this.user});

  AuthState copyWith({bool? isLoading, String? error, User? user}) {
  return AuthState(
    isLoading: isLoading?? this.isLoading,
    error: error,
    user: user?? this.user,
  );
  }
}