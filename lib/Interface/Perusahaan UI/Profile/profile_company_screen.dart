import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:imprup/Interface/Auth/auth_gate.dart';
import 'package:imprup/Interface/Perusahaan%20UI/Create%20Job/company_job_detail.dart';
import 'package:imprup/Interface/Perusahaan%20UI/Create%20Job/create_job_screen.dart';
import 'package:imprup/Interface/Perusahaan%20UI/Profile/edit_profile_company_screen.dart';
import 'package:imprup/main.dart';
import 'package:imprup/models/profile_model.dart';
import 'package:imprup/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  late Future<Profile> _profileFuture;

  List<Map<String, dynamic>> _jobs = [];
  bool _isLoadingJobs = true;

  @override
  void initState() {
    super.initState();
    _profileFuture = AuthService().getMyProfile();
    _fetchJobs();
  }

  void _logout(BuildContext context) async {
    await AuthService().signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  void _navigateToEdit(Profile currentProfile) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                EditCompanyProfileScreen(initialProfile: currentProfile),
      ),
    );
    if (result == true) {
      setState(() {
        _profileFuture = AuthService().getMyProfile();
      });
    }
  }

  Future<void> _fetchJobs() async {
    setState(() => _isLoadingJobs = true);
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    try {
      final response = await supabase
          .from('projects')
          .select()
          .eq('company_id', user!.id)
          .order('created_at', ascending: false);

      final jobs = List<Map<String, dynamic>>.from(response);

      // Filter status open
      final openJobs =
          jobs.where((job) {
            final status = (job['status'] ?? '').toString().toLowerCase();
            return status == 'open' || status == 'sedang dibuka';
          }).toList();

      setState(() {
        _jobs = openJobs;
      });

      debugPrint('Fetched ${_jobs.length} jobs');
    } catch (e) {
      debugPrint('Error fetching jobs: $e');
    } finally {
      setState(() => _isLoadingJobs = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Profil Perusahaan',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        actions: [
          FutureBuilder<Profile>(
            future: _profileFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.role == 'Perusahaan') {
                return IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () => _navigateToEdit(snapshot.data!),
                );
              }
              return Container();
            },
          ),
        ],
      ),
      body: FutureBuilder<Profile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1565C0)),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64.sp,
                      color: Colors.red.shade300,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Gagal memuat profil',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.role != 'Perusahaan') {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.business_outlined,
                      size: 64.sp,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Data profil tidak ditemukan',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final profile = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(profile),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    children: [
                      SizedBox(height: 16.h),

                      // Informasi Dasar Card
                      _buildCard(
                        icon: Icons.info_outline,
                        title: 'Informasi Dasar',
                        child: Column(
                          children: [
                            _buildInfoTile(
                              icon: Icons.category_outlined,
                              label: 'Kategori Perusahaan',
                              value: profile.companyCategory ?? '-',
                            ),
                            _buildDivider(),
                            _buildInfoTile(
                              icon: Icons.location_on_outlined,
                              label: 'Lokasi',
                              value: profile.domicile ?? '-',
                            ),
                            _buildDivider(),
                            _buildInfoTile(
                              icon: Icons.verified_user_outlined,
                              label: 'Status',
                              value: profile.role,
                              valueColor: const Color(0xFF1565C0),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // Tentang Perusahaan Card
                      _buildCard(
                        icon: Icons.business_outlined,
                        title: 'Tentang Perusahaan',
                        child: Text(
                          profile.companyDescription ??
                              'Deskripsi perusahaan belum diisi.',
                          style: TextStyle(
                            fontSize: 14.sp,
                            height: 1.6,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),

                      SizedBox(height: 16.h),
                      _buildCard(
                        icon: Icons.work_outline,
                        title: 'Lowongan Pekerjaan Aktif',
                        badge: '${_jobs.length}',
                        child: _buildJobsContent(),
                      ),
                      Container(
                        margin: EdgeInsets.all(20.h),
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _logout(context),
                          icon: Icon(Icons.logout, color: Colors.red, size: 20),
                          label: Text(
                            "Keluar",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.red, width: 2),
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection(Profile profile) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: EdgeInsets.only(bottom: 50.h),
          height: 180.h,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [const Color(0xFF1565C0), const Color(0xFF1976D2)],
            ),
          ),
          child:
              profile.photoBanner != null
                  ? Stack(
                    children: [
                      Image.network(
                        profile.photoBanner!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    const Color(0xFF1565C0),
                                    const Color(0xFF1976D2),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.business,
                                  size: 64.sp,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.3),
                              Colors.black.withOpacity(0.6),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                  : Center(
                    child: Icon(
                      Icons.business,
                      size: 64.sp,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
        ),

        // Company Info Card (Floating)
        Positioned(
          top: 120.h,
          left: 16.w,
          right: 16.w,
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Company Logo
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF1565C0).withOpacity(0.2),
                      width: 3.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 36.r,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        profile.photoProfile != null
                            ? NetworkImage(profile.photoProfile!)
                                as ImageProvider
                            : null,
                    child:
                        profile.photoProfile == null
                            ? Icon(
                              Icons.apartment,
                              size: 36.r,
                              color: const Color(0xFF1565C0),
                            )
                            : null,
                  ),
                ),
                SizedBox(width: 16.w),
                // Company Name & Badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.fullName,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              size: 14.sp,
                              color: const Color(0xFF1565C0),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Verified Company',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: const Color(0xFF1565C0),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required Widget child,
    String? badge,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF1565C0),
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1565C0),
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1.h, thickness: 1),
          Padding(padding: EdgeInsets.all(16.w), child: child),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20.sp, color: Colors.grey.shade500),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: valueColor ?? Colors.grey.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Divider(height: 1.h, thickness: 1, color: Colors.grey.shade200),
    );
  }

  Widget _buildEmptyJobsState() {
    return Container(
      padding: EdgeInsets.all(32.w),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.work_off_outlined,
              size: 48.sp,
              color: Colors.grey.shade400,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Belum ada lowongan aktif',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Anda belum memiliki lowongan pekerjaan yang aktif saat ini',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade500,
              height: 1.4,
            ),
          ),
          SizedBox(height: 20.h),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateJobPage()),
              );
            },
            icon: Icon(
              Icons.add_circle_outline,
              size: 18.sp,
              color: const Color(0xFF1565C0),
            ),
            label: Text(
              'Buat Lowongan Baru',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1565C0),
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              side: const BorderSide(color: Color(0xFF1565C0), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobsContent() {
    if (_isLoadingJobs) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_jobs.isEmpty) {
      return _buildEmptyJobsState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._jobs.map((job) {
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _buildJobCard(job),
          );
        }).toList(),

        SizedBox(height: 20.h),

        // 🔽 Tombol tambah tetap muncul meskipun sudah ada lowongan
        Center(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateJobPage()),
              ).then((_) => _fetchJobs()); // refresh list setelah buat baru
            },
            icon: Icon(
              Icons.add_circle_outline,
              size: 18.sp,
              color: const Color(0xFF1565C0),
            ),
            label: Text(
              'Buat Lowongan Baru',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1565C0),
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              side: const BorderSide(color: Color(0xFF1565C0), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
        ),
        SizedBox(height: 10.h),
      ],
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final status = job['status'] ?? 'unknown';
    final isOpen =
        status.toString().toLowerCase() == 'sedang dibuka' ||
        status.toString().toLowerCase() == 'open';

    final budgetMin = job['budget_min'];
    final budgetMax = job['budget_max'];

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color:
              isOpen
                  ? const Color(0xFF1565C0).withOpacity(0.3)
                  : Colors.grey.shade300,
          width: 1.5,
        ),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  job['title'] ?? '-',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color:
                      isOpen
                          ? const Color(0xFF4CAF50).withOpacity(0.1)
                          : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color:
                        isOpen ? const Color(0xFF4CAF50) : Colors.grey.shade400,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6.w,
                      height: 6.w,
                      decoration: BoxDecoration(
                        color: isOpen ? const Color(0xFF4CAF50) : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      isOpen ? 'Dibuka' : 'Ditutup',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color:
                            isOpen
                                ? const Color(0xFF2E7D32)
                                : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Description
          Text(
            job['job_description'] ?? job['description'] ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),

          SizedBox(height: 16.h),

          // Budget Section
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 18.sp,
                  color: const Color(0xFF1565C0),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gaji',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        _formatBudget(budgetMin, budgetMax),
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1565C0),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 12.h),

          // Footer with deadline and button
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14.sp,
                    color: Colors.grey.shade600,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'Deadline: ${_formatDeadline(job['deadline'])}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CompanyJobDetailPage(job: job),
                    ),
                  ).then((_) => _fetchJobs());
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Lihat Detail',
                      style: TextStyle(
                        color: const Color(0xFF1565C0),
                        fontWeight: FontWeight.w600,
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12.sp,
                      color: const Color(0xFF1565C0),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method untuk format budget
  String _formatBudget(dynamic budgetMin, dynamic budgetMax) {
    if (budgetMin == null && budgetMax == null) {
      return 'Tidak ditentukan';
    }

    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');

    if (budgetMin != null && budgetMax != null) {
      return '${formatter.format(budgetMin)} - ${formatter.format(budgetMax)}';
    } else if (budgetMin != null) {
      return 'Mulai dari ${formatter.format(budgetMin)}';
    } else {
      return 'Hingga ${formatter.format(budgetMax)}';
    }
  }

  // Helper method untuk format deadline
  String _formatDeadline(dynamic deadline) {
    if (deadline == null) return '-';

    try {
      final date =
          deadline is DateTime ? deadline : DateTime.parse(deadline.toString());

      final now = DateTime.now();
      final difference = date.difference(now).inDays;

      final formatter = DateFormat('dd MMM yyyy', 'id_ID');
      final formattedDate = formatter.format(date);

      if (difference < 0) {
        return '$formattedDate (Lewat)';
      } else if (difference == 0) {
        return '$formattedDate (Hari ini)';
      } else if (difference <= 7) {
        return '$formattedDate ($difference hari lagi)';
      }

      return formattedDate;
    } catch (e) {
      return deadline.toString().split('T')[0];
    }
  }
}
