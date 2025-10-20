import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:imprup/Interface/Auth/auth_gate.dart';
import 'package:imprup/Interface/Talenta%20UI/Profile/edit_profile_screen.dart';
import 'package:imprup/Interface/Talenta%20UI/Profile/profile_screen.dart';
import 'package:imprup/models/profile_model.dart';
import 'package:imprup/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;
  late Future<Profile> _profileFuture;

  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _jobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _profileFuture = AuthService().getMyProfile();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final profileRes =
          await supabase
              .from('profiles')
              .select()
              .eq('id', userId)
              .maybeSingle();

      final jobRes = await supabase
          .from('projects')
          .select(
            'id, title, description, category, deadline, budget_min, budget_max, status, profiles(full_name, company_category, photo_profile)',
          )
          .eq('status', 'Sedang Dibuka')
          .order('created_at', ascending: false);

      setState(() {
        _profile = profileRes;
        _jobs = List<Map<String, dynamic>>.from(jobRes);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatBudget(num? min, num? max) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    if (min != null && max != null) {
      return '${format.format(min)} - ${format.format(max)}';
    }
    if (min != null) return 'Mulai ${format.format(min)}';
    if (max != null) return 'Hingga ${format.format(max)}';
    return '-';
  }

  double _calculateAverageRating() {
    final ratingCount = _profile?['rating_count'] ?? 0;
    final totalRating = _profile?['total_rating'] ?? 0.0;
    if (ratingCount == 0) return 0.0;
    return totalRating / ratingCount;
  }

  void _navigateToEdit(Profile currentProfile) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(initialProfile: currentProfile),
      ),
    );

    if (result == true) {
      setState(() {
        _profileFuture = AuthService().getMyProfile();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1565C0)),
              )
              : RefreshIndicator(
                onRefresh: _fetchData,
                color: const Color(0xFF1565C0),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileCard(),
                          SizedBox(height: 20.h),
                          _buildStatsSection(),
                          SizedBox(height: 24.h),
                          // _buildQuickActions(),
                          // SizedBox(height: 24.h),
                          _buildCategoryFilter(),
                          SizedBox(height: 20.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Lowongan Terbaru',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    // Navigate to all jobs
                                  },
                                  child: Text(
                                    'Lihat Semua',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: const Color(0xFF1565C0),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 12.h),
                          _jobs.isEmpty
                              ? Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 60.h),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.work_off_outlined,
                                        size: 64.sp,
                                        color: Colors.grey.shade400,
                                      ),
                                      SizedBox(height: 16.h),
                                      Text(
                                        'Belum ada lowongan aktif saat ini',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              : Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20.w),
                                child: Column(
                                  children:
                                      _jobs
                                          .map((job) => _buildJobCard(job))
                                          .toList(),
                                ),
                              ),
                          SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildProfileCard() {
    final name = _profile?['full_name'] ?? 'Talenta';
    final photo = _profile?['photo_profile'];
    final domicile = _profile?['domicile'] ?? '-';
    final status = _profile?['status'] ?? 'Beginner';
    final mainSkill = _profile?['main_skill'] ?? 'Belum diatur';

    return Container(
      margin: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        // gradient: const LinearGradient(
        //   colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
        //   begin: Alignment.topLeft,
        //   end: Alignment.bottomRight,
        // ),
        color: Color(0xFF1565C0),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: CircleAvatar(
              radius: 32.r,
              backgroundImage:
                  photo != null && photo.isNotEmpty
                      ? NetworkImage(photo)
                      : const AssetImage('assets/images/default_profile.png')
                          as ImageProvider,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, $name 👋',
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14.sp, color: Colors.white70),
                    SizedBox(width: 4.w),
                    Text(
                      domicile,
                      style: TextStyle(fontSize: 12.sp, color: Colors.white70),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 14.sp, color: Colors.amber),
                      SizedBox(width: 4.w),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.white,
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
    );
  }

  Widget _buildStatsSection() {
    final projectsCompleted = _profile?['projects_completed'] ?? 0;
    final avgRating = _calculateAverageRating();
    final ratingCount = _profile?['rating_count'] ?? 0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            Icons.work_outline,
            projectsCompleted.toString(),
            'Proyek Selesai',
            const Color(0xFF1565C0),
          ),
          Container(height: 40.h, width: 1, color: Colors.grey.shade300),
          _buildStatItem(
            Icons.star_outline,
            avgRating.toStringAsFixed(1),
            'Rating ($ratingCount)',
            Colors.amber.shade700,
          ),
          Container(height: 40.h, width: 1, color: Colors.grey.shade300),
          _buildStatItem(
            Icons.trending_up,
            _profile?['status'] ?? 'Beginner',
            'Status',
            Colors.green.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24.sp),
        SizedBox(height: 6.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aksi Cepat',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionButton(
                Icons.edit_outlined,
                'Edit Profil',
                const Color(0xFF1565C0), () {}
              ),
              _buildActionButton(
                Icons.folder_outlined,
                'Portfolio',
                Colors.purple.shade600,
                () {
                  // Navigate to portfolio
                },
              ),
              _buildActionButton(
                Icons.bookmark_outline,
                'Tersimpan',
                Colors.orange.shade600,
                () {
                  // Navigate to saved jobs
                },
              ),
              _buildActionButton(
                Icons.history,
                'Riwayat',
                Colors.teal.shade600,
                () {
                  // Navigate to history
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: 80.w,
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22.sp),
            ),
            SizedBox(height: 6.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = [
      'Semua',
      'Design',
      'Programming',
      'Marketing',
      'Writing',
      'Video',
    ];

    return Container(
      height: 40.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = index == 0;
          return Container(
            margin: EdgeInsets.only(right: 10.w),
            child: FilterChip(
              label: Text(categories[index]),
              selected: isSelected,
              onSelected: (selected) {
                // Filter logic
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF1565C0),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontSize: 13.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color:
                    isSelected ? const Color(0xFF1565C0) : Colors.grey.shade300,
              ),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            ),
          );
        },
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final company = job['profiles']?['full_name'] ?? 'Perusahaan Tidak Dikenal';
    final category = job['category'] ?? '-';
    final desc = job['description'] ?? '-';
    final budget = _formatBudget(job['budget_min'], job['budget_max']);
    final deadline =
        job['deadline'] != null
            ? DateFormat(
              'dd MMM yyyy',
              'id_ID',
            ).format(DateTime.parse(job['deadline']))
            : '-';
    final companyPhoto = job['profiles']?['photo_profile'];
    final companyCategory =
        job['profiles']?['company_category'] ?? 'Perusahaan';

    return InkWell(
      onTap: () {
        // Navigate to job detail
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20.r,
                  backgroundImage:
                      companyPhoto != null && companyPhoto.isNotEmpty
                          ? NetworkImage(companyPhoto)
                          : const AssetImage(
                                'assets/images/default_profile.png',
                              )
                              as ImageProvider,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        companyCategory,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.bookmark_outline,
                    color: Colors.grey.shade400,
                    size: 22.sp,
                  ),
                  onPressed: () {
                    // Save job
                  },
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              job['title'] ?? 'Tanpa Judul',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              desc.length > 120 ? '${desc.substring(0, 120)}...' : desc,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              children: [
                Chip(
                  label: Text(
                    category,
                    style: TextStyle(color: Colors.white, fontSize: 11.sp),
                  ),
                  backgroundColor: const Color(0xFF42A5F5),
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Budget',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      budget,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1565C0),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Deadline',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14.sp,
                          color: Colors.redAccent,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          deadline,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
