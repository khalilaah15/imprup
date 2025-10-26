import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class ChatService {
  final SupabaseClient _supabase = supabase;

  // --- BUAT / CEK CONVERSATION ---
  Future<String> createOrGetConversation(
    String companyId,
    String projectId,
    String talentId,
  ) async {
    final userId = _supabase.auth.currentUser!.id;

    final existing = await supabase
        .from('conversations')
        .select('id')
        .eq('company_id', companyId)
        .eq('talent_id', talentId)
        .eq('project_id', projectId)
        .maybeSingle();

    if (existing != null) {
      return existing['id'];
    }

    final insert = await supabase
        .from('conversations')
        .insert({
          'company_id': companyId,
          'talent_id': talentId,
          'project_id': projectId,
        })
        .select()
        .single();

    return insert['id'];
  }

  // --- AMBIL INFO CONVERSATION (untuk AppBar) ---
  Future<Map<String, dynamic>> getConversationInfo(String conversationId) async {
    final userId = _supabase.auth.currentUser!.id;

    // Ambil conversation dengan info talent dan company
    final conversation = await _supabase
        .from('conversations')
        .select('''
          id,
          talent_id,
          company_id,
          talent:talent_id(id, full_name, photo_profile, role),
          company:company_id(id, full_name, photo_profile, role)
        ''')
        .eq('id', conversationId)
        .single();

    // Tentukan siapa lawan bicara berdasarkan user saat ini
    Map<String, dynamic> otherUser;
    
    if (conversation['talent_id'] == userId) {
      // User adalah talent, maka lawan bicaranya company
      otherUser = conversation['company'];
    } else {
      // User adalah company, maka lawan bicaranya talent
      otherUser = conversation['talent'];
    }

    return {
      'id': otherUser['id'],
      'full_name': otherUser['full_name'] ?? 'User',
      'photo_profile': otherUser['photo_profile'],
      'role': otherUser['role'],
      'is_online': false, // Bisa ditambahkan logic online status jika ada
    };
  }

  // --- AMBIL SEMUA PESAN DALAM CHAT ---
  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    final res = await _supabase
        .from('messages')
        .select('id, sender_id, content, created_at')
        .eq('conversation_id', conversationId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(res);
  }

  // --- KIRIM PESAN ---
  Future<void> sendMessage(String conversationId, String content) async {
    final senderId = _supabase.auth.currentUser!.id;

    // Insert pesan baru
    await _supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
    });

    // Update last message di conversations
    await _supabase.from('conversations').update({
      'last_message': content,
      'last_message_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', conversationId);
  }

  // --- STREAM PESAN REALTIME ---
  Stream<List<Map<String, dynamic>>> subscribeMessages(String conversationId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((event) => List<Map<String, dynamic>>.from(event));
  }

  // --- DAFTAR CHAT UNTUK TALENTA ---
  Future<List<Map<String, dynamic>>> getTalentChats() async {
    final userId = _supabase.auth.currentUser!.id;

    final res = await _supabase
        .from('conversations')
        .select(
          'id, last_message, last_message_at, updated_at, company_id, profiles:company_id(full_name, photo_profile)',
        )
        .eq('talent_id', userId)
        .order('last_message_at', ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }

  // --- DAFTAR CHAT UNTUK PERUSAHAAN ---
  Future<List<Map<String, dynamic>>> getCompanyChats() async {
    final userId = _supabase.auth.currentUser!.id;

    final res = await _supabase
        .from('conversations')
        .select(
          'id, last_message, last_message_at, updated_at, talent_id, profiles:talent_id(full_name, photo_profile)',
        )
        .eq('company_id', userId)
        .order('last_message_at', ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }

  // --- MARK MESSAGES AS READ (Optional - untuk read receipts) ---
  Future<void> markAsRead(String conversationId) async {
    final userId = _supabase.auth.currentUser!.id;
    
    // Jika Anda ingin implement read receipts, 
    // perlu menambahkan field 'is_read' di table messages
    // atau membuat table terpisah untuk tracking read status
    
    // Contoh jika ada field is_read:
    // await _supabase
    //     .from('messages')
    //     .update({'is_read': true})
    //     .eq('conversation_id', conversationId)
    //     .neq('sender_id', userId)
    //     .eq('is_read', false);
  }

  // --- COUNT UNREAD MESSAGES (Optional) ---
  Future<int> getUnreadCount(String conversationId) async {
    final userId = _supabase.auth.currentUser!.id;
    
    // Jika ada field is_read di messages table:
    // final result = await _supabase
    //     .from('messages')
    //     .select('id', const FetchOptions(count: CountOption.exact))
    //     .eq('conversation_id', conversationId)
    //     .neq('sender_id', userId)
    //     .eq('is_read', false);
    
    // return result.count ?? 0;
    
    return 0; // Default jika belum implement
  }
}