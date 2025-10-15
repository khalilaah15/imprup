import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:imprup/Interface/Perusahaan%20UI/Profile/edit_profile_company_screen.dart';
import 'package:imprup/main.dart';
import 'package:imprup/models/profile_model.dart';
import 'package:imprup/services/auth_service.dart';

class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  // Gunakan Future untuk memuat data
  late Future<Profile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = AuthService().getMyProfile();
  }

  // Fungsi navigasi dan refresh setelah edit
  void _navigateToEdit(Profile currentProfile) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCompanyProfileScreen(initialProfile: currentProfile),
      ),
    );

    // Jika berhasil diupdate, refresh data
    if (result == true) {
      setState(() {
        _profileFuture = AuthService().getMyProfile();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Perusahaan'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          FutureBuilder<Profile>(
            future: _profileFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.role == 'Perusahaan') {
                return IconButton(
                  icon: const Icon(Icons.edit),
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
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat profil: ${snapshot.error}', textAlign: TextAlign.center));
          }
          if (!snapshot.hasData || snapshot.data!.role != 'Perusahaan') {
            return const Center(child: Text('Data profil Perusahaan tidak ditemukan.'));
          }

          final profile = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. BANNER & LOGO SECTION
                _buildHeaderSection(profile),
                
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20.h),
                      
                      // 2. KATEGORI & LOKASI
                      _buildInfoSection(
                        'Informasi Dasar',
                        [
                          _buildInfoRow('Kategori', profile.companyCategory ?? '-'),
                          _buildInfoRow('Domisili', profile.domicile ?? '-'),
                          _buildInfoRow('Daftar Sebagai', profile.role),
                        ],
                      ),
                      
                      Divider(height: 30.h),
                      
                      // 3. DESKRIPSI PERUSAHAAN
                      _buildSectionTitle('Tentang Perusahaan'),
                      Text(
                        profile.companyDescription ?? 'Deskripsi perusahaan belum diisi.',
                        style: TextStyle(fontSize: 14.sp, height: 1.5),
                      ),

                      Divider(height: 30.h),

                      // 4. DAFTAR LOWONGAN PEKERJAAN (Placeholder)
                      _buildSectionTitle('Lowongan Pekerjaan Aktif (0)'),
                      SizedBox(height: 10.h),
                      Center(
                        child: Text(
                          'Anda belum memiliki lowongan aktif.',
                          style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                        ),
                      ),
                      // TODO: Di sini akan menampilkan list Lowongan Pekerjaan dari tabel 'jobs'
                      
                      SizedBox(height: 40.h),
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

  // --- Helper Widgets ---

  Widget _buildHeaderSection(Profile profile) {
    return Stack(
      children: [
        // Background Banner
        Container(
          height: 120.h,
          width: double.infinity,
          color: Colors.blue.shade100, // Warna default jika banner null
          child: profile.photoBanner != null
              ? Image.network(
                  profile.photoBanner!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(color: Colors.blue.shade100, child: Center(child: Icon(Icons.business, size: 40.sp, color: Colors.blue.shade600))),
                )
              : Center(child: Icon(Icons.business, size: 40.sp, color: Colors.blue.shade600)),
        ),
        
        // Logo Perusahaan dan Nama
        Padding(
          padding: EdgeInsets.only(top: 80.h, left: 16.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CircleAvatar(
                radius: 40.r,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 38.r,
                  backgroundImage: profile.photoProfile != null
                      ? NetworkImage(profile.photoProfile!) as ImageProvider
                      : null,
                  child: profile.photoProfile == null ? Icon(Icons.apartment, size: 38.r, color: Colors.blue.shade600) : null,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 5.h),
                  child: Text(
                    profile.fullName,
                    style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: Colors.black),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Padding untuk mencegah konten di bawah logo bertabrakan
        Container(height: 40.h), 
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Text(
        title,
        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.blue.shade800),
      ),
    );
  }
  
  Widget _buildInfoSection(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        ...rows,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}