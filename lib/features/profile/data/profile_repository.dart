import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/user_profile.dart';

class ProfileRepository {
  final SupabaseClient _supabase;

  ProfileRepository(this._supabase);

  /// Fetch user profile from Supabase
  Future<UserProfile?> getProfile(String userId) async {
    debugPrint('[ProfileRepository] getProfile called for userId: $userId');
    
    final profileData = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (profileData == null) {
      debugPrint('[ProfileRepository] No profile row found for userId: $userId');
      return null;
    }

    debugPrint('[ProfileRepository] Profile data: $profileData');

    final profile = UserProfile(
      id: profileData['id'] as String,
      fullName: profileData['full_name'] as String? ?? '',
      major: profileData['major'] as String? ?? '',
      semester: profileData['semester'] as int? ?? 0,
      createdAt: DateTime.parse(profileData['created_at'] as String),
    );

    debugPrint('[ProfileRepository] Parsed profile - major: "${profile.major}", semester: ${profile.semester}');
    debugPrint('[ProfileRepository] isIncomplete: ${profile.major.isEmpty || profile.semester == 0}');
    
    return profile;
  }

  /// Update profile
  Future<void> completeProfile({
    required String userId,
    required String major,
    required int semester,
  }) async {
    debugPrint('[ProfileRepository] completeProfile called for userId: $userId');
    
    // 1. Update profiles table
    await _supabase.from('profiles').update({
      'major': major,
      'semester': semester,
    }).eq('id', userId);
    
    
    debugPrint('[ProfileRepository] completeProfile done');
  }

  /// Update profile details (full name, major, semester)
  Future<void> updateProfile({
    required String userId,
    required String fullName,
    required String major,
    required int semester,
  }) async {
    debugPrint('[ProfileRepository] updateProfile called for userId: $userId');
    
    await _supabase.from('profiles').update({
      'full_name': fullName,
      'major': major,
      'semester': semester,
    }).eq('id', userId);
    
    debugPrint('[ProfileRepository] updateProfile done');
  }
}
