import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:imprup/Interface/Talenta%20UI/chat/chat_screen.dart';
import 'package:imprup/services/chat_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TalentProfilePage extends StatefulWidget {
  final String applicantId; // id record di tabel applications
  final Map<String, dynamic> profile; // data profile dari pelamar
  final String projectId; // id project yang dilamar

  const TalentProfilePage({
    super.key,
    required this.applicantId,
    required this.profile,
    required this.projectId,
  });

  @override
  State<TalentProfilePage> createState() => _TalentProfilePageState();
}

class _TalentProfilePageState extends State<TalentProfilePage> {
  final supabase = Supabase.instance.client;
  final ChatService _chatService = ChatService();
  bool _isUpdating = false;
  Map<String, dynamic>? _applicationData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApplicationData();
  }

  Future<void> _loadApplicationData() async {
    try {
      final appData =
          await supabase
              .from('applications')
              .select('*, projects(title, category, budget_min, budget_max)')
              .eq('id', widget.applicantId)
              .maybeSingle();

      setState(() {
        _applicationData = appData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String status) async {
    // Konfirmasi dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Text(
              status == 'Diterima' ? 'Terima Talenta?' : 'Tolak Talenta?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
            ),
            content: Text(
              status == 'Diterima'
                  ? 'Anda yakin ingin menerima ${widget.profile['full_name']}?'
                  : 'Anda yakin ingin menolak ${widget.profile['full_name']}?',
              style: TextStyle(fontSize: 14.sp),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      status == 'Diterima' ? Colors.green : Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text('Ya, ${status == 'Diterima' ? 'Terima' : 'Tolak'}'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    setState(() => _isUpdating = true);
    try {
      await supabase
          .from('applications')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.applicantId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                status == 'Diterima' ? Icons.check_circle : Icons.cancel,
                color: Colors.white,
              ),
              SizedBox(width: 12.w),
              Text('Status diperbarui menjadi $status'),
            ],
          ),
          backgroundColor: status == 'Diterima' ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _handleChat() async {
    try {
      final companyId = supabase.auth.currentUser!.id;
      final talentId = widget.profile['id'];
      final projectId = widget.projectId;

      final conversationId = await _chatService.createOrGetConversation(
        companyId,
        projectId,
        talentId,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(conversationId: conversationId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membuka chat: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final status = _applicationData?['status'] ?? 'Proses';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1565C0)),
              )
              : CustomScrollView(
                slivers: [
                  // _buildAppBar(p),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 40.h),
                      child: Column(
                        children: [
                          _buildProfileHeader(p, status),
                          _buildStatsSection(p),
                          _buildInfoSection(p),
                          _buildProjectApplicationSection(),
                          _buildActionButtons(status),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildAppBar(Map<String, dynamic> p) {
    return SliverAppBar(
      expandedHeight: 200.h,
      pinned: true,
      backgroundColor: const Color(0xFF1565C0),
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200.w,
                  height: 200.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: Container(
                  width: 150.w,
                  height: 150.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> p, String status) {
    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;

    switch (status) {
      case 'Diterima':
        statusColor = Colors.green[700]!;
        statusBgColor = Colors.green[50]!;
        statusIcon = Icons.check_circle;
        break;
      case 'Ditolak':
        statusColor = Colors.red[700]!;
        statusBgColor = Colors.red[50]!;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange[700]!;
        statusBgColor = Colors.orange[50]!;
        statusIcon = Icons.hourglass_empty;
    }

    return Column(
      
        children: [
              SizedBox(height: 35.h,),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 60.r,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      (p['photo_profile'] != null &&
                              p['photo_profile'].isNotEmpty)
                          ? NetworkImage(p['photo_profile'])
                          : null,
                  child:
                      (p['photo_profile'] == null || p['photo_profile'].isEmpty)
                          ? Icon(
                            Icons.person,
                            size: 60.sp,
                            color: Colors.grey[300],
                          )
                          : null,
                ),
              ),
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: Icon(statusIcon, color: statusColor, size: 24.sp),
              ),
            
          
          SizedBox(height: 16.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              children: [
                Text(
                  p['full_name'] ?? 'Tidak Diketahui',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: const Color(0xFF1565C0).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.work_outline,
                        size: 18.sp,
                        color: const Color(0xFF1565C0),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        p['main_skill'] ?? 'Tidak Ada Skill',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: const Color(0xFF1565C0),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (p['domicile'] != null) ...[
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16.sp,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        p['domicile'],
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16.sp, color: statusColor),
                      SizedBox(width: 8.w),
                      Text(
                        'Status: $status',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h,)
              ],
            ),
          ),
        ],
      
    );
  }

  Widget _buildStatsSection(Map<String, dynamic> p) {
    final projectsCompleted = p['projects_completed'] ?? 0;
    final rating = p['total_rating'] ?? 0.0;
    final ratingCount = p['rating_count'] ?? 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                Icons.check_circle_outline,
                projectsCompleted.toString(),
                'Proyek Selesai',
                const Color(0xFF1565C0),
              ),
            ),
            Container(width: 1, height: 50.h, color: Colors.grey[300]),
            Expanded(
              child: _buildStatItem(
                Icons.star,
                rating > 0 ? rating.toStringAsFixed(1) : '0.0',
                'Rating',
                Colors.amber[700]!,
                subtitle: ratingCount > 0 ? '($ratingCount ulasan)' : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color, {
    String? subtitle,
  }) {
    return Column(
      children: [
        Icon(icon, size: 32.sp, color: color),
        SizedBox(height: 8.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: TextStyle(fontSize: 10.sp, color: Colors.grey[500]),
          ),
      ],
    );
  }

  Widget _buildInfoSection(Map<String, dynamic> p) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p['short_description'] != null &&
              p['short_description'].toString().isNotEmpty) ...[
            _buildInfoCard(
              'Tentang',
              Icons.person_outline,
              child: Text(
                p['short_description'],
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[700],
                  height: 1.6,
                ),
              ),
            ),
            SizedBox(height: 12.h),
          ],
          _buildInfoCard(
            'Informasi Detail',
            Icons.info_outline,
            child: Column(
              children: [
                if (p['last_education'] != null)
                  _buildInfoRow(
                    Icons.school,
                    'Pendidikan',
                    p['last_education'],
                  ),
                if (p['birth_date'] != null) ...[
                  SizedBox(height: 12.h),
                  _buildInfoRow(Icons.cake, 'Tanggal Lahir', p['birth_date']),
                ],
                if (p['whatsapp_number'] != null) ...[
                  SizedBox(height: 12.h),
                  _buildInfoRow(Icons.phone, 'WhatsApp', p['whatsapp_number']),
                ],
                if (p['status'] != null) ...[
                  SizedBox(height: 12.h),
                  _buildInfoRow(
                    Icons.workspace_premium,
                    'Status Talent',
                    p['status'],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, size: 20.sp, color: const Color(0xFF1565C0)),
              ),
              SizedBox(width: 12.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20.sp, color: Colors.grey[600]),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProjectApplicationSection() {
    if (_applicationData == null) return const SizedBox.shrink();

    final project = _applicationData!['projects'];
    final message = _applicationData!['message'];

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1565C0).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.work, color: Colors.white, size: 24.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Melamar untuk',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              project?['title'] ?? 'Project',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (project?['category'] != null) ...[
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  project['category'],
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (message != null && message.toString().isNotEmpty) ...[
              SizedBox(height: 16.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pesan Lamaran:',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(String status) {
    final canUpdateStatus = status == 'Proses';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          // Chat Button - Always visible
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleChat,
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Chat dengan Talenta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 2,
              ),
            ),
          ),

          if (canUpdateStatus) ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _isUpdating ? null : () => _updateStatus('Diterima'),
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: Text(
                      _isUpdating ? 'Proses...' : 'Terima',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _isUpdating ? null : () => _updateStatus('Ditolak'),
                    icon: const Icon(Icons.cancel_outlined, size: 20),
                    label: Text(
                      _isUpdating ? 'Proses...' : 'Tolak',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: status == 'Diterima' ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color:
                      status == 'Diterima'
                          ? Colors.green[200]!
                          : Colors.red[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    status == 'Diterima' ? Icons.check_circle : Icons.cancel,
                    color:
                        status == 'Diterima'
                            ? Colors.green[700]
                            : Colors.red[700],
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      status == 'Diterima'
                          ? 'Talenta ini telah diterima'
                          : 'Talenta ini telah ditolak',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color:
                            status == 'Diterima'
                                ? Colors.green[700]
                                : Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
