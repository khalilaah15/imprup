import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:imprup/Interface/Auth/login_screen.dart';
import 'package:imprup/Interface/Talenta%20UI/chat/chat_screen.dart';
import 'package:imprup/services/applications_service.dart';
import 'package:imprup/services/chat_service.dart';
import 'package:intl/intl.dart';

class JobDetailPage extends StatefulWidget {
  final Map<String, dynamic> job;
  const JobDetailPage({super.key, required this.job});

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  bool _isApplying = false;
  final ChatService _chatService = ChatService();

  Future<void> _handleChat(BuildContext context) async {
    try {
      final companyId = widget.job['company_id'];
      final projectId = widget.job['id'];
      final talentId = supabase.auth.currentUser!.id;

      if (companyId == null || projectId == null) {
        throw Exception("Data perusahaan atau proyek tidak lengkap");
      }

      // Buat atau ambil conversation yang sudah ada
      final conversationId = await _chatService.createOrGetConversation(
        companyId,
        projectId,
        talentId,
      );

      if (!mounted) return;

      // Pindah ke halaman chat
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(conversationId: conversationId),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal membuka chat: $e")));
    }
  }

  Future<void> _apply() async {
    setState(() => _isApplying = true);
    try {
      await ApplicationsService().applyToJob(widget.job['id']);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Berhasil mendaftar!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final company = job['profiles']?['full_name'] ?? 'Perusahaan';
    final desc = job['description'] ?? '-';
    final category = job['category'] ?? '-';
    final budgetMin = job['budget_min'] ?? 0;
    final budgetMax = job['budget_max'] ?? 0;
    final deadline = job['deadline'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(job['title'] ?? 'Detail Lowongan'),
        backgroundColor: const Color(0xFF1565C0),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              company,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            Text(
              category,
              style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
            ),
            SizedBox(height: 12.h),
            Text(desc, style: TextStyle(fontSize: 14.sp, height: 1.5)),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Budget: Rp${budgetMin.toInt()} - Rp${budgetMax.toInt()}",
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Deadline: ${DateFormat('dd MMM yyyy').format(DateTime.parse(deadline))}",
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isApplying ? null : _apply,
                icon:
                    _isApplying
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Icon(Icons.send),
                label: Text(_isApplying ? 'Mendaftar...' : 'Daftar Sekarang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            ElevatedButton.icon(
              onPressed: () => _handleChat(context),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Chat Perusahaan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
