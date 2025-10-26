import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompanyHomeScreen extends StatefulWidget {
  const CompanyHomeScreen({super.key});

  @override
  State<CompanyHomeScreen> createState() => _CompanyHomeScreenState();
}

class _CompanyHomeScreenState extends State<CompanyHomeScreen> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _companyProfile;
  List<Map<String, dynamic>> _activeProjects = [];
  Map<String, int> _stats = {
    'total_projects': 0,
    'active_projects': 0,
    'total_applicants': 0,
    'pending_applicants': 0,
  };
  List<Map<String, dynamic>> _recentApplicants = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final profileRes =
          await supabase.from('profiles').select('*').eq('id', userId).single();

      final projectsRes = await supabase
          .from('projects')
          .select(
            'id, title, status, deadline, category, created_at, applications(count)',
          )
          .eq('company_id', userId)
          .eq('status', 'Sedang Dibuka')
          .order('created_at', ascending: false)
          .limit(3);

      final allProjectsRes = await supabase
          .from('projects')
          .select('id, status')
          .eq('company_id', userId);

      final projectIds = allProjectsRes.map((p) => p['id']).toList();

      List<Map<String, dynamic>> applicantsRes = [];
      List<Map<String, dynamic>> allApplicantsRes = [];

      if (projectIds.isNotEmpty) {
        applicantsRes = await supabase
            .from('applications')
            .select('''
            id, status, created_at,
            profiles(id, full_name, photo_profile, main_skill),
            projects(id, title)
          ''')
            .eq('project_id', projectIds)
            .order('created_at', ascending: false)
            .limit(5);

        allApplicantsRes = await supabase
            .from('applications')
            .select('id, status')
            .eq('project_id', projectIds);
      }

      final totalProjects = allProjectsRes.length;
      final activeProjects =
          allProjectsRes.where((p) => p['status'] == 'Sedang Dibuka').length;

      final totalApplicants = allApplicantsRes.length;
      final pendingApplicants =
          allApplicantsRes.where((a) => a['status'] == 'Proses').length;

      setState(() {
        _companyProfile = profileRes;
        _activeProjects = List<Map<String, dynamic>>.from(projectsRes);
        _recentApplicants = List<Map<String, dynamic>>.from(applicantsRes);
        _stats = {
          'total_projects': totalProjects,
          'active_projects': activeProjects,
          'total_applicants': totalApplicants,
          'pending_applicants': pendingApplicants,
        };
        _isLoading = false;
      });
    } catch (e, stack) {
      print('Error loading data: $e');
      print(stack);
      setState(() => _isLoading = false);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  String _formatDate(String date) {
    final parsed = DateTime.parse(date);
    final now = DateTime.now();
    final diff = now.difference(parsed);

    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return DateFormat('dd MMM yyyy', 'id_ID').format(parsed);
  }

  String _formatDeadline(String deadline) {
    final date = DateTime.parse(deadline);
    final now = DateTime.now();
    final diff = date.difference(now);

    if (diff.isNegative) return 'Terlewat';
    if (diff.inDays == 0) return 'Hari ini';
    if (diff.inDays == 1) return 'Besok';
    if (diff.inDays < 7) return '${diff.inDays} hari lagi';
    return DateFormat('dd MMM yyyy', 'id_ID').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1565C0),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1565C0)),
              )
              : RefreshIndicator(
                onRefresh: _loadData,
                color: const Color(0xFF1565C0),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildHeader(),
                      _buildStatsCards(),
                      _buildQuickActions(),
                      _buildActiveProjects(),
                      _buildRecentApplicants(),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30.r),
          bottomRight: Radius.circular(30.r),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 30.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 28.r,
                      backgroundColor: Colors.white,
                      backgroundImage:
                          _companyProfile?['photo_profile'] != null
                              ? NetworkImage(_companyProfile!['photo_profile'])
                              : null,
                      child:
                          _companyProfile?['photo_profile'] == null
                              ? Icon(
                                Icons.business,
                                size: 32.sp,
                                color: const Color(0xFF1565C0),
                              )
                              : null,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          _companyProfile?['full_name'] ?? 'Company',
                          style: TextStyle(
                            fontSize: 20.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 28.sp,
                    ),
                    onPressed: () {
                      // Navigate to notifications
                    },
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.white, size: 24.sp),
                    SizedBox(width: 12.w),
                    Text(
                      'Cari talenta atau proyek...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Proyek',
              _stats['total_projects'].toString(),
              Icons.folder_outlined,
              const Color(0xFF1565C0),
              Colors.blue[50]!,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildStatCard(
              'Proyek Aktif',
              _stats['active_projects'].toString(),
              Icons.trending_up,
              Colors.green[700]!,
              Colors.green[50]!,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aksi Cepat',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: Colors.grey[900],
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Buat Proyek',
                    Icons.add_circle_outline,
                    const Color(0xFF1565C0),
                    () {
                      // Navigate to create project
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildActionButton(
                    'Pelamar',
                    Icons.people_outline,
                    Colors.orange[700]!,
                    () {
                      // Navigate to applicants
                    },
                    badge:
                        _stats['pending_applicants']! > 0
                            ? _stats['pending_applicants'].toString()
                            : null,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Chat',
                    Icons.chat_bubble_outline,
                    Colors.green[700]!,
                    () {
                      // Navigate to chat
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildActionButton(
                    'Riwayat',
                    Icons.history,
                    Colors.purple[700]!,
                    () {
                      // Navigate to history
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    String? badge,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: color, size: 28.sp),
                  if (badge != null)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(
                          minWidth: 18.w,
                          minHeight: 18.h,
                        ),
                        child: Center(
                          child: Text(
                            badge,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveProjects() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Proyek Aktif',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to all projects
                },
                child: Text(
                  'Lihat Semua',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: const Color(0xFF1565C0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _activeProjects.isEmpty
              ? Container(
                padding: EdgeInsets.all(40.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.work_outline,
                        size: 48.sp,
                        color: Colors.grey[300],
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Belum ada proyek aktif',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : Column(
                children:
                    _activeProjects
                        .map((project) => _buildProjectCard(project))
                        .toList(),
              ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    final applicantCount = project['applications']?[0]?['count'] ?? 0;
    final deadline = _formatDeadline(project['deadline']);
    final isUrgent =
        DateTime.parse(project['deadline']).difference(DateTime.now()).inDays <
        7;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () {
            // Navigate to project detail
          },
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        project['title'],
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[900],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: isUrgent ? Colors.red[50] : Colors.green[50],
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14.sp,
                            color:
                                isUrgent ? Colors.red[700] : Colors.green[700],
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            deadline,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color:
                                  isUrgent
                                      ? Colors.red[700]
                                      : Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (project['category'] != null) ...[
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      project['category'],
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: const Color(0xFF1565C0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 20.sp,
                        color: const Color(0xFF1565C0),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '$applicantCount Pelamar',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14.sp,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentApplicants() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pelamar Terbaru',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to applicants
                },
                child: Text(
                  'Lihat Semua',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: const Color(0xFF1565C0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _recentApplicants.isEmpty
              ? Container(
                padding: EdgeInsets.all(40.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 48.sp,
                        color: Colors.grey[300],
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Belum ada pelamar',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children:
                      _recentApplicants
                          .map((applicant) => _buildApplicantItem(applicant))
                          .toList(),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildApplicantItem(Map<String, dynamic> applicant) {
    final profile = applicant['profiles'];
    final project = applicant['projects'];
    final status = applicant['status'] ?? 'Proses';

    Color statusColor;
    switch (status) {
      case 'Diterima':
        statusColor = Colors.green[700]!;
        break;
      case 'Ditolak':
        statusColor = Colors.red[700]!;
        break;
      default:
        statusColor = Colors.orange[700]!;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Navigate to applicant detail
        },
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF1565C0).withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 24.r,
                  backgroundColor: Colors.grey[100],
                  backgroundImage:
                      profile?['photo_profile'] != null
                          ? NetworkImage(profile['photo_profile'])
                          : null,
                  child:
                      profile?['photo_profile'] == null
                          ? Icon(
                            Icons.person,
                            size: 24.sp,
                            color: Colors.grey[400],
                          )
                          : null,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?['full_name'] ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[900],
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      project?['title'] ?? '-',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _formatDate(applicant['created_at']),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
