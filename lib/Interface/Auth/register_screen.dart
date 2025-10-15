import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:imprup/Interface/Auth/login_screen.dart';
import 'package:imprup/Interface/Talenta%20UI/Home/home_screen.dart';
import 'package:imprup/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String _selectedRole = 'Talenta';
  bool _formComplete = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool isLoading = false;
  String? _errorMessage;

  final List<String> _roles = ['Talenta', 'Perusahaan'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- Supabase Registration Logic ---
  void register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _nameController.text.trim(),
        role: _selectedRole,
      );

      // Sukses: Arahkan user ke halaman login
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pendaftaran berhasil! Silakan masuk.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _validateForm() {
    setState(() {
      _formComplete =
          _nameController.text.isNotEmpty &&
          _emailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty &&
          _confirmPasswordController.text.isNotEmpty;
    });
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required String? Function(String?) validator,
    bool isPassword = false,
    bool isConfirmPassword = false,
  }) {
    bool isVisible =
        isConfirmPassword ? _isConfirmPasswordVisible : _isPasswordVisible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.h),
        Text(
          labelText,
          style: TextStyle(
            color: const Color(0xFF121926),
            fontSize: 14.sp,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            height: 1.40,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          obscureText: isPassword ? !isVisible : false,
          keyboardType:
              isPassword || isConfirmPassword
                  ? TextInputType.text
                  : labelText == 'E-mail'
                  ? TextInputType.emailAddress
                  : TextInputType.text,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14.sp),
            fillColor: Colors.grey.shade100,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25.r),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 10.h,
            ),
            suffixIcon:
                isPassword || isConfirmPassword
                    ? IconButton(
                      icon: Icon(
                        isVisible ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () {
                        setState(() {
                          if (isConfirmPassword) {
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible;
                          } else {
                            _isPasswordVisible = !_isPasswordVisible;
                          }
                        });
                      },
                    )
                    : null,
          ),
          onChanged: (val) {
            _validateForm();
          },
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildRoleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.h),
        Text(
          'Daftar Sebagai',
          style: TextStyle(
            color: const Color(0xFF121926),
            fontSize: 14.sp,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            height: 1.40,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          height: 45.h,
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(25.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:
                _roles.map((role) {
                  bool isSelected = _selectedRole == role;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRole = role;
                          _validateForm();
                        });
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? const Color(0xFF001E3D)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(25.r),
                        ),
                        child: Text(
                          role,
                          style: TextStyle(
                            color:
                                isSelected
                                    ? Colors.white
                                    : const Color(0xFF121926),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 40.h),
                        Text(
                          'Daftarkan Akunmu Sekarang\ndan Bergabung bersama Kami!',
                          style: TextStyle(
                            color: const Color(0xFF121926),
                            fontSize: 20.sp,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            height: 1.40,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        if (_errorMessage != null)
                          Padding(
                            padding: EdgeInsets.only(bottom: 10.h),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildTextField(
                                controller: _nameController,
                                labelText:
                                    _selectedRole == 'Talenta'
                                        ? 'Nama Lengkap'
                                        : 'Nama Perusahaan',
                                hintText: 'Masukkan nama',
                                validator:
                                    (val) =>
                                        val!.isEmpty
                                            ? "Nama tidak boleh kosong"
                                            : null,
                              ),
                              SizedBox(height: 16.h),
                              _buildTextField(
                                controller: _emailController,
                                labelText: 'E-mail',
                                hintText: 'Masukkan email anda',
                                validator: (val) {
                                  if (val!.isEmpty)
                                    return "Email tidak boleh kosong";
                                  if (!RegExp(
                                    r'^[^@]+@[^@]+\.[^@]+',
                                  ).hasMatch(val))
                                    return "Format email tidak valid";
                                  return null;
                                },
                              ),
                              SizedBox(height: 16.h),
                              _buildRoleSelection(),
                              _buildTextField(
                                controller: _passwordController,
                                labelText: 'Password',
                                hintText: 'Minimal 6 karakter',
                                isPassword: true,
                                validator:
                                    (val) =>
                                        val!.length < 6
                                            ? "Minimal 6 karakter"
                                            : null,
                              ),
                              _buildTextField(
                                controller: _confirmPasswordController,
                                labelText: 'Konfirmasi Password',
                                hintText: 'Masukkan password kembali',
                                isConfirmPassword: true,
                                validator: (val) {
                                  if (val!.isEmpty)
                                    return "Konfirmasi password tidak boleh kosong";
                                  if (val != _passwordController.text)
                                    return "Password tidak cocok";
                                  return null;
                                },
                              ),

                              SizedBox(height: 32.h),
                              SizedBox(
                                width: double.infinity,
                                height: 45.h,
                                child: ElevatedButton(
                                  onPressed: _formComplete ? register : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        _formComplete
                                            ? const Color(0xFF001E3D)
                                            : const Color(0xFFD6D1FA),
                                    foregroundColor:
                                        _formComplete
                                            ? Colors.white
                                            : Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25.r),
                                    ),
                                  ),
                                  child: Text(
                                    "Daftar",
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: 24.h),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Sudah punya akun ? ',
                                    style: TextStyle(
                                      color: const Color(0xFF0F1728),
                                      fontSize: 12.sp,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w400,
                                      height: 1.40,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const LoginScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Masuk',
                                      style: TextStyle(
                                        color: const Color(0xFF0F1728),
                                        fontSize: 12.sp,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                        height: 1.40,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
