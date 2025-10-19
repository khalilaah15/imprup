import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:imprup/Interface/Auth/auth_gate.dart';
import 'package:imprup/Interface/Talenta%20UI/Profile/edit_profile_screen.dart';
import 'package:imprup/Interface/Talenta%20UI/Profile/status_level_bar.dart';
import 'package:imprup/models/profile_model.dart';
import 'package:imprup/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Profile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = AuthService().getMyProfile();
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

  void _logout(BuildContext context) async {
    await AuthService().signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Profil',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        actions: [
          FutureBuilder<Profile>(
            future: _profileFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.role == 'Talenta') {
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
        future: AuthService().getMyProfile(),
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
          if (!snapshot.hasData || snapshot.data!.role != 'Talenta') {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_off_outlined,
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
          final averageRating = AuthService().getAverageRating(profile);

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header Section dengan gradient
                Container(
                  width: double.infinity,
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
                  child: Column(
                    children: [
                      SizedBox(height: 20.h),
                      // Avatar dengan border
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4.w),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 56.r,
                          backgroundColor: Colors.white,
                          backgroundImage:
                              profile.photoProfile != null
                                  ? NetworkImage(profile.photoProfile!)
                                      as ImageProvider
                                  : null,
                          child:
                              profile.photoProfile == null
                                  ? Icon(
                                    Icons.person,
                                    size: 56.r,
                                    color: const Color(0xFF1565C0),
                                  )
                                  : null,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        profile.fullName,
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          profile.role,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(height: 40.h),
                    ],
                  ),
                ),

                // Status dan Rating Card
                Transform.translate(
                  offset: Offset(0, -20.h),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(16.w),
                            child: StatusLevelBar(
                              status: profile.status ?? 'Beginner',
                              completed: profile.projectsCompleted,
                            ),
                          ),
                          Divider(height: 1.h, thickness: 1),
                          Padding(
                            padding: EdgeInsets.all(20.w),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  color: const Color(0xFFFFB300),
                                  size: 28.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  averageRating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 24.sp,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1565C0),
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '/5.0',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  '(${profile.ratingCount} ulasan)',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Content Cards
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    children: [
                      // Deskripsi Diri Card
                      _buildCard(
                        icon: Icons.description_outlined,
                        title: 'Deskripsi Diri',
                        child: Text(
                          profile.shortDescription ?? 'Deskripsi belum diisi.',
                          style: TextStyle(
                            fontSize: 14.sp,
                            height: 1.6,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // Informasi Pribadi Card
                      _buildCard(
                        icon: Icons.person_outline,
                        title: 'Informasi Pribadi',
                        child: Column(
                          children: [
                            _buildInfoTile(
                              icon: Icons.cake_outlined,
                              label: 'Tanggal Lahir',
                              value: profile.birthDate ?? '-',
                            ),
                            _buildDivider(),
                            _buildInfoTile(
                              icon: Icons.location_on_outlined,
                              label: 'Domisili',
                              value: profile.domicile ?? '-',
                            ),
                            _buildDivider(),
                            _buildInfoTile(
                              icon: Icons.school_outlined,
                              label: 'Pendidikan Terakhir',
                              value: profile.lastEducation ?? '-',
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // Keahlian & Kontak Card
                      _buildCard(
                        icon: Icons.work_outline,
                        title: 'Keahlian & Kontak',
                        child: Column(
                          children: [
                            _buildInfoTile(
                              icon: Icons.emoji_objects_outlined,
                              label: 'Keahlian Utama',
                              value: profile.mainSkill ?? '-',
                            ),
                            _buildDivider(),
                            _buildInfoTile(
                              icon: Icons.phone_outlined,
                              label: 'WhatsApp',
                              value: profile.whatsappNumber ?? '-',
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 30.h),
                      ElevatedButton.icon(
                        onPressed: () => _logout(context),
                        icon: Icon(Icons.logout, size: 20),
                        label: Text('Logout', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          elevation: 2,
                        ),
                      ),
                      SizedBox(height: 32.h),
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

  Widget _buildCard({
    required IconData icon,
    required String title,
    required Widget child,
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
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1565C0),
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
                    color: Colors.grey.shade800,
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
}
