import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:imprup/models/profile_model.dart';
import 'package:imprup/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:imprup/main.dart';

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

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller dengan data profil awal
    _nameController = TextEditingController(text: widget.initialProfile.fullName);
    _birthDateController = TextEditingController(text: widget.initialProfile.birthDate);
    _domicileController = TextEditingController(text: widget.initialProfile.domicile);
    _educationController = TextEditingController(text: widget.initialProfile.lastEducation);
    _skillController = TextEditingController(text: widget.initialProfile.mainSkill);
    _whatsappController = TextEditingController(text: widget.initialProfile.whatsappNumber);
    _descriptionController = TextEditingController(text: widget.initialProfile.shortDescription);
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

  // Fungsi untuk menyimpan perubahan ke Supabase
  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Membuat Map data yang akan diupdate
    final Map<String, dynamic> updateData = {
      'full_name': _nameController.text.trim(),
      'birth_date': _birthDateController.text.trim().isEmpty ? null : _birthDateController.text.trim(),
      'domicile': _domicileController.text.trim(),
      'last_education': _educationController.text.trim(),
      'main_skill': _skillController.text.trim(),
      'whatsapp_number': _whatsappController.text.trim(),
      'short_description': _descriptionController.text.trim(),
      // Catatan: Role, Status, dan Project Selesai tidak diubah di sini
    };

    try {
      await supabase.from('profiles') 
        .update(updateData)
        .eq('id', widget.initialProfile.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui!')),
        );
        // Kembali ke ProfileScreen dan beri sinyal untuk refresh
        Navigator.pop(context, true); 
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal menyimpan: $e';
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
    bool readOnly = false,
    int maxLines = 1,
    VoidCallback? onTap,
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
          readOnly: readOnly,
          maxLines: maxLines,
          onTap: onTap,
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
    // Memeriksa role, jika bukan Talenta, tampilkan pesan
    if (widget.initialProfile.role != 'Talenta') {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profil')),
        body: const Center(child: Text('Halaman edit ini hanya untuk Talenta.')),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil Talenta'),
        backgroundColor: Colors.green.shade700,
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

                    // Field Nama Lengkap
                    _buildTextField(
                      controller: _nameController,
                      labelText: 'Nama Lengkap',
                      validator: (val) => val!.isEmpty ? 'Nama tidak boleh kosong' : null,
                    ),

                    // Field Tanggal Lahir (dengan Date Picker)
                    _buildTextField(
                      controller: _birthDateController,
                      labelText: 'Tanggal Lahir (YYYY-MM-DD)',
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      validator: (val) => val!.isEmpty ? 'Tanggal lahir diperlukan' : null,
                    ),

                    // Field Domisili
                    _buildTextField(
                      controller: _domicileController,
                      labelText: 'Kota Domisili',
                      validator: (val) => val!.isEmpty ? 'Domisili tidak boleh kosong' : null,
                    ),

                    // Field Pendidikan Terakhir
                    _buildTextField(
                      controller: _educationController,
                      labelText: 'Pendidikan Terakhir',
                    ),

                    // Field Keahlian Utama
                    _buildTextField(
                      controller: _skillController,
                      labelText: 'Keahlian Utama',
                      validator: (val) => val!.isEmpty ? 'Keahlian utama tidak boleh kosong' : null,
                    ),

                    // Field Nomor WhatsApp
                    _buildTextField(
                      controller: _whatsappController,
                      labelText: 'Nomor WhatsApp',
                      keyboardType: TextInputType.phone,
                    ),

                    // Field Deskripsi Singkat
                    _buildTextField(
                      controller: _descriptionController,
                      labelText: 'Deskripsi Singkat',
                      maxLines: 4,
                    ),

                    SizedBox(height: 30.h),

                    // Tombol Simpan
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A3D31),
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