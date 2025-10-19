import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:imprup/models/profile_model.dart';
import 'package:imprup/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:imprup/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  final Profile initialProfile;
  const EditProfileScreen({super.key, required this.initialProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Editing Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _domicileController;
  late final TextEditingController _educationController;
  late final TextEditingController _skillController;
  late final TextEditingController _whatsappController;
  late final TextEditingController _descriptionController;

  String? _photoProfileUrl;
  File? _newPhotoProfileFile;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialProfile.fullName,
    );
    _birthDateController = TextEditingController(
      text: widget.initialProfile.birthDate,
    );
    _domicileController = TextEditingController(
      text: widget.initialProfile.domicile,
    );
    _educationController = TextEditingController(
      text: widget.initialProfile.lastEducation,
    );
    _skillController = TextEditingController(
      text: widget.initialProfile.mainSkill,
    );
    _whatsappController = TextEditingController(
      text: widget.initialProfile.whatsappNumber,
    );
    _descriptionController = TextEditingController(
      text: widget.initialProfile.shortDescription,
    );
    _photoProfileUrl = widget.initialProfile.photoProfile;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _domicileController.dispose();
    _educationController.dispose();
    _skillController.dispose();
    _whatsappController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Fungsi untuk memilih tanggal lahir
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // Fungsi untuk memilih gambar
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);

    if (pickedFile != null) {
      setState(() {
        _newPhotoProfileFile = File(pickedFile.path);
        _photoProfileUrl = null; // Hapus URL lama sementara
      });
    }
  }

  Future<String?> _uploadImage(File? imageFile, String bucketName) async {
    if (imageFile == null) return null;

    final String userId = supabase.auth.currentUser!.id;
    final String fileExtension = imageFile.path.split('.').last;
    final String fileName =
        '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    final String path = '$userId/$fileName'; // Path di dalam bucket

    try {
      await supabase.storage
          .from(bucketName)
          .upload(
            path,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );
      // Supabase upload akan mengembalikan public URL
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

      // 2. Update profiles table
      final Map<String, dynamic> updateData = {
        'full_name': _nameController.text.trim(),
        'birth_date':
            _birthDateController.text.trim().isEmpty
                ? null
                : _birthDateController.text.trim(),
        'domicile': _domicileController.text.trim(),
        'last_education': _educationController.text.trim(),
        'main_skill': _skillController.text.trim(),
        'whatsapp_number': _whatsappController.text.trim(),
        'short_description': _descriptionController.text.trim(),
        'photo_profile': newPhotoProfileStorageUrl, // Simpan URL baru
      };

      await supabase
          .from('profiles')
          .update(updateData)
          .eq('id', widget.initialProfile.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui!')),
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
    bool readOnly = false,
    int maxLines = 1,
    VoidCallback? onTap,
    String? Function(String?)? validator,
    IconData? prefixIcon,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8.h),
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
          readOnly: readOnly,
          maxLines: maxLines,
          onTap: onTap,
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
            suffixIcon:
                readOnly
                    ? Icon(
                      Icons.calendar_today,
                      color: Colors.grey.shade400,
                      size: 18.sp,
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
          'Perbarui Informasi Profil',
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
                      'Memuat data profil...',
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
                      child: Column(children: [SizedBox(height: 24.h)]),
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

                              // Foto Profil Card
                              _buildCard(
                                title: 'Foto Profil',
                                icon: Icons.person_outline,
                                child: _buildImageSelectionSection(
                                  title: '',
                                  currentImageUrl: _photoProfileUrl,
                                  newImageFile: _newPhotoProfileFile,
                                  isCircular: true,
                                  onTap: () => _showImageSourceSelection(),
                                ),
                              ),

                              SizedBox(height: 16.h),

                              // Informasi Pribadi Card
                              _buildCard(
                                title: 'Informasi Pribadi',
                                icon: Icons.badge_outlined,
                                child: Column(
                                  children: [
                                    _buildTextField(
                                      controller: _nameController,
                                      labelText: 'Nama Lengkap',
                                      prefixIcon: Icons.person_outline,
                                      hintText: 'Masukkan nama lengkap',
                                      validator:
                                          (val) =>
                                              val!.isEmpty
                                                  ? 'Nama tidak boleh kosong'
                                                  : null,
                                    ),
                                    _buildTextField(
                                      controller: _birthDateController,
                                      labelText: 'Tanggal Lahir',
                                      prefixIcon: Icons.cake_outlined,
                                      hintText: 'Pilih tanggal lahir',
                                      readOnly: true,
                                      onTap: () => _selectDate(context),
                                      validator:
                                          (val) =>
                                              val!.isEmpty
                                                  ? 'Tanggal lahir diperlukan'
                                                  : null,
                                    ),
                                    _buildTextField(
                                      controller: _domicileController,
                                      labelText: 'Kota Domisili',
                                      prefixIcon: Icons.location_on_outlined,
                                      hintText: 'Contoh: Jakarta, Surabaya',
                                      validator:
                                          (val) =>
                                              val!.isEmpty
                                                  ? 'Domisili tidak boleh kosong'
                                                  : null,
                                    ),
                                    _buildTextField(
                                      controller: _educationController,
                                      labelText: 'Pendidikan Terakhir',
                                      prefixIcon: Icons.school_outlined,
                                      hintText: 'Contoh: S1 Teknik Informatika',
                                    ),
                                    SizedBox(height: 8.h),
                                  ],
                                ),
                              ),

                              SizedBox(height: 16.h),

                              // Keahlian & Kontak Card
                              _buildCard(
                                title: 'Keahlian & Kontak',
                                icon: Icons.work_outline,
                                child: Column(
                                  children: [
                                    _buildTextField(
                                      controller: _skillController,
                                      labelText: 'Keahlian Utama',
                                      prefixIcon: Icons.emoji_objects_outlined,
                                      hintText:
                                          'Contoh: UI/UX Design, Web Development',
                                      validator:
                                          (val) =>
                                              val!.isEmpty
                                                  ? 'Keahlian utama tidak boleh kosong'
                                                  : null,
                                    ),
                                    _buildTextField(
                                      controller: _whatsappController,
                                      labelText: 'Nomor WhatsApp',
                                      prefixIcon: Icons.phone_outlined,
                                      hintText: 'Contoh: 08123456789',
                                      keyboardType: TextInputType.phone,
                                    ),
                                    SizedBox(height: 8.h),
                                  ],
                                ),
                              ),

                              SizedBox(height: 16.h),

                              // Deskripsi Card
                              _buildCard(
                                title: 'Deskripsi Diri',
                                icon: Icons.description_outlined,
                                child: Column(
                                  children: [
                                    _buildTextField(
                                      controller: _descriptionController,
                                      labelText: 'Ceritakan tentang diri Anda',
                                      hintText:
                                          'Tulis deskripsi singkat tentang keahlian, pengalaman, dan minat Anda...',
                                      maxLines: 5,
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
          Padding(
            padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 16.w),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildImageSelectionSection({
    required String title,
    String? currentImageUrl,
    File? newImageFile,
    required VoidCallback onTap,
    bool isCircular = false,
  }) {
    ImageProvider? imageProvider;
    if (newImageFile != null) {
      imageProvider = FileImage(newImageFile);
    } else if (currentImageUrl != null && currentImageUrl.isNotEmpty) {
      imageProvider = NetworkImage(currentImageUrl);
    }

    return Center(
      child: Column(
        children: [
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
                  CircleAvatar(
                    radius: 64.r,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: imageProvider,
                    child:
                        imageProvider == null
                            ? Icon(
                              Icons.person,
                              size: 64.r,
                              color: Colors.grey.shade400,
                            )
                            : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(8.w),
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
                        size: 20.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),
          OutlinedButton.icon(
            onPressed: onTap,
            icon: Icon(
              Icons.photo_library_outlined,
              size: 18.sp,
              color: const Color(0xFF1565C0),
            ),
            label: Text(
              newImageFile != null ||
                      (currentImageUrl != null && currentImageUrl.isNotEmpty)
                  ? 'Ganti Foto Profil'
                  : 'Pilih Foto Profil',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1565C0),
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
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

  void _showImageSourceSelection({bool isBanner = false}) {
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
                    'Pilih Sumber Foto',
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
                    _pickImage(ImageSource.gallery);
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
                    _pickImage(ImageSource.camera);
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
