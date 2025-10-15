import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

  // Fungsi navigasi yang menerima data profil
  void _navigateToEdit(Profile currentProfile) async {
    // <--- Menerima data
    // Menunggu hasil dari EditProfileScreen (true jika berhasil diupdate)
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        // BERIKAN DATA PROFIL KE CONSTRUCTOR
        builder: (context) => EditProfileScreen(initialProfile: currentProfile),
      ),
    );

    if (result == true) {
      // Jika berhasil diupdate, refresh data dengan memanggil ulang Future
      setState(() {
        _profileFuture = AuthService().getMyProfile();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Talenta'),
        backgroundColor: Colors.green.shade700,
        actions: [
          FutureBuilder<Profile>(
            future: _profileFuture,
            builder: (context, snapshot) {
              // Tampilkan tombol edit hanya jika data tersedia dan bukan error
              if (snapshot.hasData && snapshot.data!.role == 'Talenta') {
                return IconButton(
                  icon: const Icon(Icons.edit),
                  // Panggil fungsi navigasi dengan data profil yang tersedia
                  onPressed: () => _navigateToEdit(snapshot.data!),
                );
              }
              return Container(); // Tampilkan widget kosong jika data belum siap
            },
          ),
        ],
      ),
      body: FutureBuilder<Profile>(
        future: AuthService().getMyProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Gagal memuat profil: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.role != 'Talenta') {
            return const Center(
              child: Text('Data profil Talenta tidak ditemukan.'),
            );
          }

          final profile = snapshot.data!;
          // Hitung rata-rata rating untuk ditampilkan
          final averageRating = AuthService().getAverageRating(profile);

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // FOTO DAN NAMA
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50.r,
                        backgroundImage:
                            profile.photoProfile != null
                                ? NetworkImage(profile.photoProfile!)
                                    as ImageProvider
                                : const AssetImage('assets/default_avatar.png'),
                        child:
                            profile.photoProfile == null
                                ? Icon(Icons.person, size: 50.r)
                                : null,
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        profile.fullName,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '(${profile.role})',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 10.h),
                    ],
                  ),
                ),

                // BAR STATUS LEVEL
                StatusLevelBar(
                  status: profile.status ?? 'Beginner',
                  completed: profile.projectsCompleted,
                ),
                SizedBox(height: 20.h),

                // RATING
                _buildInfoRow(
                  'Rating Rata-rata',
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 20.sp),
                      SizedBox(width: 5.w),
                      Text(
                        averageRating.toStringAsFixed(
                          1,
                        ), // Tampilkan satu angka di belakang koma
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        ' (${profile.ratingCount} ulasan)',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 20.h),

                // DESKRIPSI
                _buildSectionTitle('Deskripsi Diri'),
                Text(
                  profile.shortDescription ?? 'Deskripsi belum diisi.',
                  style: TextStyle(fontSize: 14.sp, height: 1.5),
                ),
                Divider(height: 20.h),

                // DETAIL PROFIL
                _buildSectionTitle('Detail Pribadi & Keahlian'),
                _buildInfoRow('Tanggal Lahir', profile.birthDate ?? '-'),
                _buildInfoRow('Domisili', profile.domicile ?? '-'),
                _buildInfoRow(
                  'Pendidikan Terakhir',
                  profile.lastEducation ?? '-',
                ),
                _buildInfoRow('Keahlian Utama', profile.mainSkill ?? '-'),
                _buildInfoRow('Nomor WhatsApp', profile.whatsappNumber ?? '-'),
                SizedBox(height: 20.h),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0A3D31),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    final valueWidget =
        (value is String)
            ? Text(value, style: TextStyle(fontSize: 14.sp))
            : value;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700),
          ),
          valueWidget,
        ],
      ),
    );
  }
}
