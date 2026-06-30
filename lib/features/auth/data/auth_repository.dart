import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  /// Stream of authentication state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Get the currently logged-in user
  User? get currentUser => _supabase.auth.currentUser;

  /// Sign up a new user with email, password, and full name
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
      },
    );

    final user = response.user;
    if (user != null) {
      debugPrint('[AuthRepository] signUp success, userId: ${user.id}');
      
      // Wait for the Supabase trigger (handle_new_user) to create the profile row.
      // The trigger runs asynchronously on the server side.
      bool profileExists = false;
      for (int attempt = 0; attempt < 5; attempt++) {
        await Future.delayed(const Duration(milliseconds: 500));
        final data = await _supabase
            .from('profiles')
            .select('id')
            .eq('id', user.id)
            .maybeSingle();
        if (data != null) {
          profileExists = true;
          debugPrint('[AuthRepository] Profile row found on attempt ${attempt + 1}');
          break;
        }
        debugPrint('[AuthRepository] Profile row not found yet, attempt ${attempt + 1}');
      }

      if (profileExists) {
        await _supabase.from('profiles').update({
          'full_name': fullName,
        }).eq('id', user.id);
        debugPrint('[AuthRepository] Profile full_name updated');
      } else {
        debugPrint('[AuthRepository] WARNING: Profile row was never created by trigger!');
      }
    }

    return response;
  }

  /// Sign in an existing user with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out the current user
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
