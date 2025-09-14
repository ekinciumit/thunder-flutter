import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthState {
  final User? user;
  final String? error;
  final bool loading;

  AuthState({this.user, this.error, this.loading = false});

  AuthState copyWith({User? user, String? error, bool? loading}) {
    return AuthState(
      user: user ?? this.user,
      error: error,
      loading: loading ?? this.loading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState(user: FirebaseAuth.instance.currentUser));

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      state = AuthState(user: credential.user, loading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), loading: false);
    }
  }

  Future<void> signUp(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      state = AuthState(user: credential.user, loading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), loading: false);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    state = AuthState(user: null, loading: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());