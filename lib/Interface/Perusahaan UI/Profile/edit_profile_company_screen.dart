import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:imprup/models/profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:imprup/main.dart';

class EditCompanyProfileScreen extends StatefulWidget {
  final Profile initialProfile;
  const EditCompanyProfileScreen({super.key, required this.initialProfile});

  @override
  State<EditCompanyProfileScreen> createState() => _EditCompanyProfileScreenState();
}

class _EditCompanyProfileScreenState extends State<EditCompanyProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _domicileController;
  late final TextEditingController _categoryController;
  late final TextEditingController _descriptionController;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller dengan data profil awal
    _nameController = TextEditingController(text: widget.initialProfile.fullName);
    _domicileController = TextEditingController(text: widget.initialProfile.domicile);
    _categoryController = TextEditingController(text: widget.initialProfile.companyCategory);
    _descriptionController = TextEditingController(text: widget.initialProfile.companyDescription);
    
    // NOTE: Logika Photo Profile/Banner memerlukan integrasi Supabase Storage (upload file).
    // Untuk saat ini, kita fokus pada field teks.
  }

  @override
  void dispose() {
    _nameController.dispose();
    _domicileController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Fungsi untuk menyimpan perubahan ke Supabase
  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final Map<String, dynamic> updateData = {
      'full_name': _nameController.text.trim(),
      'domicile': _domicileController.text.trim(),
      'company_category': _categoryController.text.trim(),
      'company_description': _descriptionController.text.trim(),
      // 'photo_profile': https://m.yelp.com/biz/baru-cincinnati-2,
      // 'photo_banner': https://m.yelp.com/biz/baru-cincinnati-2,
    };

    try {
      await supabase.from('profiles')
        .update(updateData)
        .eq('id', widget.initialProfile.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil perusahaan berhasil diperbarui!')),
        );
        // Kembali ke CompanyProfileScreen dan beri sinyal untuk refresh
        Navigator.pop(context, true); 
      }
    } on PostgrestException catch (e) {
      setState(() {
        _errorMessage = 'Gagal menyimpan data: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan umum: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper widget untuk input field yang responsif
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.h),
        Text(
          labelText,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            fillColor: Colors.grey.shade100,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          ),
          validator: validator,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil Perusahaan'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error Message
                    if (_errorMessage != null)
                      Padding(
                        padding: EdgeInsets.only(bottom: 15.h),
                        child: Text(_errorMessage!, style: TextStyle(color: Colors.red, fontSize: 14.sp)),
                      ),
                      
                    // Placeholder untuk Photo Banner dan Profile upload
                    SizedBox(height: 10.h),
                    Center(child: Text('Logo dan Banner memerlukan fitur upload (Supabase Storage).', style: TextStyle(fontSize: 12.sp, color: Colors.grey))),
                    SizedBox(height: 10.h),

                    // Field Nama Perusahaan
                    _buildTextField(
                      controller: _nameController,
                      labelText: 'Nama Perusahaan',
                      validator: (val) => val!.isEmpty ? 'Nama tidak boleh kosong' : null,
                    ),

                    // Field Domisili
                    _buildTextField(
                      controller: _domicileController,
                      labelText: 'Domisili Perusahaan',
                      validator: (val) => val!.isEmpty ? 'Domisili tidak boleh kosong' : null,
                    ),

                    // Field Kategori Perusahaan
                    _buildTextField(
                      controller: _categoryController,
                      labelText: 'Kategori Perusahaan',
                    ),

                    // Field Deskripsi Perusahaan
                    _buildTextField(
                      controller: _descriptionController,
                      labelText: 'Deskripsi Perusahaan',
                      maxLines: 6,
                    ),

                    SizedBox(height: 30.h),

                    // Tombol Simpan
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade800,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        ),
                        child: Text('Simpan Perubahan', style: TextStyle(fontSize: 16.sp, color: Colors.white)),
                      ),
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
    );
  }
}