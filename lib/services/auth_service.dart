import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  bool get isSignedIn => _client.auth.currentSession != null;

  Future<bool> hasRecoveredSession() async {
    if (isSignedIn) {
      return true;
    }

    try {
      final state = await _client.auth.onAuthStateChange
          .firstWhere(
            (state) =>
                state.event == AuthChangeEvent.initialSession ||
                state.session != null,
          )
          .timeout(const Duration(seconds: 3));

      return state.session != null || isSignedIn;
    } on TimeoutException {
      return isSignedIn;
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp({required String email, required String password}) async {
    await _client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
