import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class ApplicationsService {
  final SupabaseClient _supabase = supabase;

  // Talenta daftar ke lowongan
  Future<void> applyToJob(String projectId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception("User belum login");

    // Cek apakah sudah pernah daftar
    final existing = await supabase
        .from('applications')
        .select()
        .eq('project_id', projectId)
        .eq('talent_id', userId);

    if (existing.isNotEmpty) {
      throw Exception("Kamu sudah mendaftar di lowongan ini");
    }

    await supabase.from('applications').insert({
      'project_id': projectId,
      'talent_id': userId,
    });
  }

  // Talenta lihat semua lamaran yang ia buat
  Future<List<Map<String, dynamic>>> getMyApplications() async {
    final user = _supabase.auth.currentUser;
    final data = await _supabase
        .from('applications')
        .select('id, status, message, projects(title, category)')
        .eq('talent_id', user!.id);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getAllApplicantsForMyProjects() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Kamu belum login.');

    final data = await _supabase
        .from('applications')
        .select(
          'id, status, message, project_id, profiles(full_name, main_skill), projects!inner(id, company_id)',
        )
        .eq('projects.company_id', user.id);
    return List<Map<String, dynamic>>.from(data);
  }

  // Perusahaan lihat semua pelamar untuk lowongan tertentu
  Future<List<Map<String, dynamic>>> getApplicantsForJob(
    String projectId,
  ) async {
    final data = await _supabase
        .from('applications')
        .select(
          'id, status, message, talent_id, profiles!applications_talent_id_fkey(full_name, photo_profile, main_skill)',
        )
        .eq('project_id', projectId);
    return List<Map<String, dynamic>>.from(data);
  }

  // Perusahaan ubah status lamaran
  Future<void> updateApplicationStatus({
    required String applicationId,
    required String newStatus,
    String? message,
  }) async {
    await _supabase
        .from('applications')
        .update({
          'status': newStatus,
          'message': message,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', applicationId);
  }
}
