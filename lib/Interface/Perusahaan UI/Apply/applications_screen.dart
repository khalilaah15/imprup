import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:imprup/Interface/Perusahaan%20UI/Apply/talent_profile_screen.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApplicantsPage extends StatefulWidget {
  const ApplicantsPage({super.key});

  @override
  State<ApplicantsPage> createState() => _ApplicantsPageState();
}

class _ApplicantsPageState extends State<ApplicantsPage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _jobs = [];
  List<Map<String, dynamic>> _applicants = [];
  String? _selectedJobId;
  Map<String, dynamic>? _selectedJob;
  late TabController _tabController;
  String _selectedFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchCompanyJobs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Ambil daftar job milik perusahaan
  Future<void> _fetchCompanyJobs() async {
    setState(() => _isLoading = true);

    try {
      final companyId = supabase.auth.currentUser?.id;
      if (companyId == null) return;

      final jobRes = await supabase
          .from('projects')
          .select(
            'id, title, status, deadline, budget_min, budget_max, category, created_at, applications(count)',
          )
          .eq('company_id', companyId)
          .order('created_at', ascending: false);

      setState(() {
        _jobs = List<Map<String, dynamic>>.from(jobRes);
        if (_jobs.isNotEmpty) {
          _selectedJobId = _jobs.first['id'];
          _selectedJob = _jobs.first;
          _fetchApplicants(_selectedJobId!);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Ambil daftar pelamar berdasarkan job_id
  Future<void> _fetchApplicants(String jobId) async {
    setState(() => _isLoading = true);

    try {
      final res = await supabase
          .from('applications')
          .select(
            'id, status, created_at, message, profiles(id, full_name, main_skill, photo_profile, domicile, projects_completed, total_rating)',
          )
          .eq('project_id', jobId)
          .order('created_at', ascending: false);

      setState(() {
        _applicants = List<Map<String, dynamic>>.from(res);
        _selectedJobId = jobId;
        _selectedJob = _jobs.firstWhere((job) => job['id'] == jobId);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat pelamar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredApplicants {
    if (_selectedFilter == 'Semua') return _applicants;
    return _applicants
        .where((app) => app['status'] == _selectedFilter)
        .toList();
  }

  int _getApplicantCountByStatus(String status) {
    if (status == 'Semua') return _applicants.length;
    return _applicants.where((app) => app['status'] == status).length;
  }

  String _formatDate(String date) {
    final parsed = DateTime.parse(date);
    final now = DateTime.now();
    final diff = now.difference(parsed);

    if (diff.inDays == 0) {
      return 'Hari ini, ${DateFormat('HH:mm').format(parsed)}';
    } else if (diff.inDays == 1) {
      return 'Kemarin, ${DateFormat('HH:mm').format(parsed)}';
    } else if (diff.inDays < 7) {
      return DateFormat('EEEE, HH:mm', 'id_ID').format(parsed);
    } else {
      return DateFormat('dd MMM yyyy', 'id_ID').format(parsed);
    }
  }

  String _formatBudget(num? min, num? max) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    if (min != null && max != null) {
      return '${formatter.format(min)} - ${formatter.format(max)}';
    }
    return 'Negosiasi';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1565C0),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manajemen Pelamar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_jobs.isNotEmpty)
              Text(
                '${_jobs.length} Lowongan Aktif',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {
              // Filter dialog
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1565C0)),
              )
              : _jobs.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                onRefresh: _fetchCompanyJobs,
                color: const Color(0xFF1565C0),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildJobSelector(),
                      if (_selectedJob != null) _buildJobInfoCard(),
                      _buildFilterTabs(),
                      _buildApplicantsList(),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_outline, size: 100, color: Colors.grey[300]),
          SizedBox(height: 24.h),
          Text(
            'Belum Ada Lowongan',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Buat lowongan pertama Anda untuk\nmulai menerima pelamar',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildJobSelector() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.business_center,
                size: 20.sp,
                color: const Color(0xFF1565C0),
              ),
              SizedBox(width: 8.w),
              Text(
                'Pilih Lowongan',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12.r),
              color: Colors.grey[50],
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedJobId,
              items:
                  _jobs.map<DropdownMenuItem<String>>((job) {
                    final count = job['applications']?[0]?['count'] ?? 0;
                    final status = job['status'] ?? 'Sedang Dibuka';

                    return DropdownMenuItem<String>(
                      value: job['id'] as String,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  job['title'],
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[900],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 2.h),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.people,
                                      size: 12.sp,
                                      color: Colors.grey[600],
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      '$count pelamar',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6.w,
                                        vertical: 2.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            status == 'Sedang Dibuka'
                                                ? Colors.green.withOpacity(0.1)
                                                : Colors.grey.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(
                                          4.r,
                                        ),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          color:
                                              status == 'Sedang Dibuka'
                                                  ? Colors.green[700]
                                                  : Colors.grey[700],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  _fetchApplicants(value);
                }
              },
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
                suffixIcon: const Icon(
                  Icons.arrow_drop_down,
                  color: Color(0xFF1565C0),
                ),
              ),
              icon: const SizedBox.shrink(),
              dropdownColor: Colors.white,
              isExpanded: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobInfoCard() {
    final job = _selectedJob!;
    final deadline =
        job['deadline'] != null
            ? DateFormat(
              'dd MMM yyyy',
              'id_ID',
            ).format(DateTime.parse(job['deadline']))
            : '-';

    return Container(
      margin: EdgeInsets.all(16.w),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job['title'],
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    if (job['category'] != null)
                      Text(
                        job['category'],
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  '${job['applications']?[0]?['count'] ?? 0} Pelamar',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF1565C0),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.account_balance_wallet,
                  'Budget',
                  _formatBudget(job['budget_min'], job['budget_max']),
                ),
              ),
              Container(
                width: 1,
                height: 30.h,
                color: Colors.white.withOpacity(0.3),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildInfoItem(Icons.event, 'Deadline', deadline),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: Colors.white),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // ⬅️ arah scroll horizontal
        child: Row(
          children: [
            _buildFilterChip('Semua', _getApplicantCountByStatus('Semua')),
            SizedBox(width: 8.w),
            _buildFilterChip('Proses', _getApplicantCountByStatus('Proses')),
            SizedBox(width: 8.w),
            _buildFilterChip(
              'Diterima',
              _getApplicantCountByStatus('Diterima'),
            ),
            SizedBox(width: 8.w),
            _buildFilterChip('Ditolak', _getApplicantCountByStatus('Ditolak')),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1565C0) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? const Color(0xFF1565C0) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            SizedBox(width: 6.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? Colors.white.withOpacity(0.3)
                        : Colors.grey[300],
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicantsList() {
    final filtered = _filteredApplicants;

    if (filtered.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 60.h),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 80.sp, color: Colors.grey[300]),
              SizedBox(height: 16.h),
              Text(
                _selectedFilter == 'Semua'
                    ? 'Belum ada pelamar'
                    : 'Tidak ada pelamar dengan status "$_selectedFilter"',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${filtered.length} Pelamar',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 12.h),
          ...filtered.map((app) => _buildApplicantCard(app)).toList(),
        ],
      ),
    );
  }

  Widget _buildApplicantCard(Map<String, dynamic> app) {
    final profile = app['profiles'];
    final name = profile?['full_name'] ?? 'Tidak diketahui';
    final skill = profile?['main_skill'] ?? '-';
    final domicile = profile?['domicile'] ?? '-';
    final photo = profile?['photo_profile'];
    final status = app['status'] ?? 'Proses';
    final date = _formatDate(app['created_at']);
    final projectsCompleted = profile?['projects_completed'] ?? 0;
    final rating = profile?['total_rating'] ?? 0.0;

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

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => TalentProfilePage(
                      applicantId: app['id'],
                      profile: app['profiles'],
                      projectId: _selectedJobId!,
                    ),
              ),
            ).then((_) => _fetchApplicants(_selectedJobId!));
          },
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
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
                            radius: 32.r,
                            backgroundColor: Colors.grey[100],
                            backgroundImage:
                                (photo != null && photo.isNotEmpty)
                                    ? NetworkImage(photo)
                                    : null,
                            child:
                                (photo == null || photo.isEmpty)
                                    ? Icon(
                                      Icons.person,
                                      size: 32.sp,
                                      color: Colors.grey[400],
                                    )
                                    : null,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              statusIcon,
                              size: 12.sp,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey[900],
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: statusBgColor,
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: statusColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Icon(
                                Icons.work_outline,
                                size: 14.sp,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 4.w),
                              Expanded(
                                child: Text(
                                  skill,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14.sp,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                domicile,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 16.sp,
                              color: const Color(0xFF1565C0),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              '$projectsCompleted Proyek',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 16.h,
                        color: Colors.grey[300],
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 16.sp,
                              color: Colors.amber[700],
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              rating > 0
                                  ? rating.toStringAsFixed(1)
                                  : 'Belum ada',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12.sp,
                      color: Colors.grey[500],
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Melamar: $date',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[500],
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12.sp,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
