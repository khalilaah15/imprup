import 'package:imprup/models/profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class AuthService {
  final SupabaseClient _supabase = supabase;

  // Fungsi Register (Sign Up)
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      // 1. Buat user di Auth
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException('Pendaftaran gagal. User tidak ditemukan.');
      }

      // 2. Insert data ke tabel profiles
      await _supabase.from('profiles').insert({
        'id': user.id,
        'role': role,
        'full_name': fullName,
      });
    } on AuthException {
      rethrow; // Biarkan error Auth Supabase dilempar ke UI
    } catch (e) {
      throw Exception('Gagal mendaftar dan membuat profil: $e');
    }
  }

  // Fungsi Login (Sign In)
  Future<String> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Sign In
      await _supabase.auth.signInWithPassword(email: email, password: password);

      // 2. Fetch Role
      return await getUserRole();
    } on AuthException {
      rethrow;
    } catch (e) {
      throw Exception('Gagal masuk: $e');
    }
  }

  // Fungsi Logout
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Ambil Role user saat ini (digunakan setelah login atau di AuthGate)
  Future<String> getUserRole() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Pengguna tidak terautentikasi.');
    }

    // Ambil role dari tabel profiles
    final response =
        await _supabase
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .single();

    final userRole = response['role'] as String;
    return userRole;
  }

  Future<Profile> getMyProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Pengguna tidak terautentikasi.');
    }

    final response =
        await _supabase.from('profiles').select('*').eq('id', user.id).single();

    // Konversi hasil Supabase menjadi Profile Model
    return Profile.fromJson(response);
  }

  // Menghitung rating rata-rata
  double getAverageRating(Profile profile) {
    if (profile.ratingCount == 0) return 0.0;
    return profile.totalRating / profile.ratingCount;
  }
}
