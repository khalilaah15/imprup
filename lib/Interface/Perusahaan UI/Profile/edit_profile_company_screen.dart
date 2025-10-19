import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:imprup/models/profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:imprup/main.dart';

class EditCompanyProfileScreen extends StatefulWidget {
  final Profile initialProfile;
  const EditCompanyProfileScreen({super.key, required this.initialProfile});

  @override
  State<EditCompanyProfileScreen> createState() =>
      _EditCompanyProfileScreenState();
}

class _EditCompanyProfileScreenState extends State<EditCompanyProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _domicileController;
  late final TextEditingController _categoryController;
  late final TextEditingController _descriptionController;

  String? _photoProfileUrl;
  String? _photoBannerUrl;
  File? _newPhotoProfileFile;
  File? _newPhotoBannerFile;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialProfile.fullName,
    );
    _domicileController = TextEditingController(
      text: widget.initialProfile.domicile,
    );
    _categoryController = TextEditingController(
      text: widget.initialProfile.companyCategory,
    );
    _descriptionController = TextEditingController(
      text: widget.initialProfile.companyDescription,
    );

    _photoProfileUrl = widget.initialProfile.photoProfile;
    _photoBannerUrl = widget.initialProfile.photoBanner;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _domicileController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, {required bool isBanner}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);

    if (pickedFile != null) {
      setState(() {
        if (isBanner) {
          _newPhotoBannerFile = File(pickedFile.path);
          _photoBannerUrl = null;
        } else {
          _newPhotoProfileFile = File(pickedFile.path);
          _photoProfileUrl = null;
        }
      });
    }
  }

  Future<String?> _uploadImage(File? imageFile, String bucketName) async {
    if (imageFile == null) return null;

    final String userId = supabase.auth.currentUser!.id;
    final String fileExtension = imageFile.path.split('.').last;
    final String fileName =
        '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    final String path = '$userId/$fileName';

    try {
      final String publicUrl = await supabase.storage
          .from(bucketName)
          .upload(
            path,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );
      return supabase.storage.from(bucketName).getPublicUrl(path);
    } catch (e) {
      _errorMessage = 'Gagal mengupload gambar ke $bucketName: $e';
      return null;
    }
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String? newPhotoProfileStorageUrl = _photoProfileUrl;
    String? newPhotoBannerStorageUrl = _photoBannerUrl;

    try {
      // 1. Upload new photo profile if selected
      if (_newPhotoProfileFile != null) {
        newPhotoProfileStorageUrl = await _uploadImage(
          _newPhotoProfileFile,
          'profile_pics',
        );
        if (newPhotoProfileStorageUrl == null) {
          throw Exception('Gagal mengupload foto profil.');
        }
      }

      // 2. Upload new photo banner if selected
      if (_newPhotoBannerFile != null) {
        newPhotoBannerStorageUrl = await _uploadImage(
          _newPhotoBannerFile,
          'company_banners',
        );
        if (newPhotoBannerStorageUrl == null) {
          throw Exception('Gagal mengupload foto banner.');
        }
      }

      // 3. Update profiles table
      final Map<String, dynamic> updateData = {
        'full_name': _nameController.text.trim(),
        'domicile': _domicileController.text.trim(),
        'company_category': _categoryController.text.trim(),
        'company_description': _descriptionController.text.trim(),
        'photo_profile': newPhotoProfileStorageUrl, // Simpan URL baru
        'photo_banner': newPhotoBannerStorageUrl, // Simpan URL baru
      };

      await supabase
          .from('profiles')
          .update(updateData)
          .eq('id', widget.initialProfile.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil perusahaan berhasil diperbarui!'),
          ),
        );
        Navigator.pop(context, true);
      }
    } on PostgrestException catch (e) {
      setState(() {
        _errorMessage = 'Gagal menyimpan data: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    IconData? prefixIcon,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.h),
        Text(
          labelText,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1565C0),
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade800),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14.sp),
            prefixIcon:
                prefixIcon != null
                    ? Icon(
                      prefixIcon,
                      color: const Color(0xFF1565C0),
                      size: 20.sp,
                    )
                    : null,
            fillColor: Colors.white,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.red.shade400, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.red.shade400, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: prefixIcon != null ? 12.w : 16.w,
              vertical: maxLines > 1 ? 16.h : 14.h,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Edit Profil Perusahaan',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF1565C0)),
                    SizedBox(height: 16.h),
                    Text(
                      'Memuat data perusahaan...',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  children: [
                    // Header dengan gradient
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                        ),
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: 24.h),
                          Icon(
                            Icons.business_outlined,
                            size: 48.sp,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'Perbarui Informasi Perusahaan',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 30.h),
                        ],
                      ),
                    ),

                    // Form Content
                    Transform.translate(
                      offset: Offset(0, -16.h),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Error Message
                              if (_errorMessage != null)
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(16.w),
                                  margin: EdgeInsets.only(bottom: 16.h),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.red.shade700,
                                        size: 20.sp,
                                      ),
                                      SizedBox(width: 12.w),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontSize: 14.sp,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Banner & Logo Card
                              _buildCard(
                                title: 'Media Perusahaan',
                                icon: Icons.photo_library_outlined,
                                child: Column(
                                  children: [
                                    _buildBannerSection(
                                      title: 'Banner Perusahaan',
                                      subtitle: 'Rekomendasi: 1200x400px',
                                      currentImageUrl: _photoBannerUrl,
                                      newImageFile: _newPhotoBannerFile,
                                      onTap:
                                          () => _showImageSourceSelection(
                                            isBanner: true,
                                          ),
                                    ),
                                    SizedBox(height: 24.h),
                                    Divider(
                                      height: 1.h,
                                      color: Colors.grey.shade200,
                                    ),
                                    SizedBox(height: 24.h),
                                    _buildLogoSection(
                                      title: 'Logo Perusahaan',
                                      subtitle: 'Rekomendasi: 400x400px',
                                      currentImageUrl: _photoProfileUrl,
                                      newImageFile: _newPhotoProfileFile,
                                      onTap:
                                          () => _showImageSourceSelection(
                                            isBanner: false,
                                          ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 16.h),

                              // Informasi Perusahaan Card
                              _buildCard(
                                title: 'Informasi Perusahaan',
                                icon: Icons.business_center_outlined,
                                child: Column(
                                  children: [
                                    _buildTextField(
                                      controller: _nameController,
                                      labelText: 'Nama Perusahaan',
                                      prefixIcon: Icons.business_outlined,
                                      hintText: 'Masukkan nama perusahaan',
                                      validator:
                                          (val) =>
                                              val!.isEmpty
                                                  ? 'Nama tidak boleh kosong'
                                                  : null,
                                    ),
                                    _buildTextField(
                                      controller: _domicileController,
                                      labelText: 'Lokasi Perusahaan',
                                      prefixIcon: Icons.location_on_outlined,
                                      hintText: 'Contoh: Jakarta, Indonesia',
                                      validator:
                                          (val) =>
                                              val!.isEmpty
                                                  ? 'Domisili tidak boleh kosong'
                                                  : null,
                                    ),
                                    _buildTextField(
                                      controller: _categoryController,
                                      labelText: 'Kategori/Industri',
                                      prefixIcon: Icons.category_outlined,
                                      hintText:
                                          'Contoh: Teknologi, Manufaktur, Retail',
                                    ),
                                    SizedBox(height: 8.h),
                                  ],
                                ),
                              ),

                              SizedBox(height: 16.h),

                              // Deskripsi Card
                              _buildCard(
                                title: 'Tentang Perusahaan',
                                icon: Icons.description_outlined,
                                child: Column(
                                  children: [
                                    _buildTextField(
                                      controller: _descriptionController,
                                      labelText: 'Deskripsi Lengkap',
                                      hintText:
                                          'Ceritakan tentang perusahaan Anda, visi, misi, produk/layanan, dan keunggulan...',
                                      maxLines: 6,
                                    ),
                                    SizedBox(height: 8.h),
                                  ],
                                ),
                              ),

                              SizedBox(height: 24.h),

                              // Save Button
                              Container(
                                width: double.infinity,
                                height: 54.h,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12.r),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF1565C0),
                                      Color(0xFF1976D2),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF1565C0,
                                      ).withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.save_outlined,
                                        size: 20.sp,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'Simpan Perubahan',
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              SizedBox(height: 32.h),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
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
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF1565C0),
                    size: 22.sp,
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
          Divider(height: 1.h, thickness: 1, color: Colors.grey.shade200),
          Padding(padding: EdgeInsets.all(16.w), child: child),
        ],
      ),
    );
  }

  Widget _buildBannerSection({
    required String title,
    required String subtitle,
    String? currentImageUrl,
    File? newImageFile,
    required VoidCallback onTap,
  }) {
    ImageProvider? imageProvider;
    if (newImageFile != null) {
      imageProvider = FileImage(newImageFile);
    } else if (currentImageUrl != null && currentImageUrl.isNotEmpty) {
      imageProvider = NetworkImage(currentImageUrl);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 140.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.shade300, width: 2),
              image:
                  imageProvider != null
                      ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                      : null,
            ),
            child:
                imageProvider == null
                    ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 48.sp,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Tap untuk memilih banner',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    )
                    : Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: EdgeInsets.all(8.w),
                          child: Container(
                            padding: EdgeInsets.all(6.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Icon(
                              Icons.edit,
                              size: 16.sp,
                              color: const Color(0xFF1565C0),
                            ),
                          ),
                        ),
                      ),
                    ),
          ),
        ),
        SizedBox(height: 8.h),
        Center(
          child: TextButton.icon(
            onPressed: onTap,
            icon: Icon(
              Icons.photo_library_outlined,
              size: 16.sp,
              color: const Color(0xFF1565C0),
            ),
            label: Text(
              newImageFile != null ||
                      (currentImageUrl != null && currentImageUrl.isNotEmpty)
                  ? 'Ganti Banner'
                  : 'Pilih Banner',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1565C0),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoSection({
    required String title,
    required String subtitle,
    String? currentImageUrl,
    File? newImageFile,
    required VoidCallback onTap,
  }) {
    ImageProvider? imageProvider;
    if (newImageFile != null) {
      imageProvider = FileImage(newImageFile);
    } else if (currentImageUrl != null && currentImageUrl.isNotEmpty) {
      imageProvider = NetworkImage(currentImageUrl);
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 3),
                  ),
                  child: CircleAvatar(
                    radius: 64.r,
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage: imageProvider,
                    child:
                        imageProvider == null
                            ? Icon(
                              Icons.business_center,
                              size: 48.r,
                              color: Colors.grey.shade400,
                            )
                            : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3.w),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 12.h),
        TextButton.icon(
          onPressed: onTap,
          icon: Icon(
            Icons.photo_library_outlined,
            size: 16.sp,
            color: const Color(0xFF1565C0),
          ),
          label: Text(
            newImageFile != null ||
                    (currentImageUrl != null && currentImageUrl.isNotEmpty)
                ? 'Ganti Logo'
                : 'Pilih Logo',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1565C0),
            ),
          ),
        ),
      ],
    );
  }

  void _showImageSourceSelection({required bool isBanner}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.r),
              topRight: Radius.circular(24.r),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(height: 12.h),
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 20.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Text(
                    'Pilih Sumber ${isBanner ? 'Banner' : 'Logo'}',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1565C0),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.photo_library,
                      color: const Color(0xFF1565C0),
                      size: 24.sp,
                    ),
                  ),
                  title: Text(
                    'Pilih dari Galeri',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Pilih foto dari galeri perangkat',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery, isBanner: isBanner);
                  },
                ),
                Divider(height: 1.h, indent: 20.w, endIndent: 20.w),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: const Color(0xFF1565C0),
                      size: 24.sp,
                    ),
                  ),
                  title: Text(
                    'Ambil Foto',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Ambil foto menggunakan kamera',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera, isBanner: isBanner);
                  },
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        );
      },
    );
  }
}
