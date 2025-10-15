import 'package:flutter/material.dart';
import 'package:imprup/Interface/Auth/auth_gate.dart';
import 'package:imprup/Interface/Perusahaan%20UI/Home/company_home_screen.dart';
import 'package:imprup/Interface/Talenta%20UI/Home/home_screen.dart';
import 'package:imprup/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'register_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

final supabase = Supabase.instance.client;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _formComplete = false;
  bool isLoading = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Sukses: Langsung navigasi ke AuthGate (Gate akan cek role & arahkan ke Home)
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = 'Gagal Login: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Kesalahan: Gagal mengambil data role.';
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
          _emailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty;
    });
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
                          'Masukkan Email dan\nPassword untuk Masuk',
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
                        Text(
                          'E-mail',
                          style: TextStyle(
                            color: const Color(0xFF121926),
                            fontSize: 14.sp,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                            height: 1.40,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  hintText: 'Masukkan email anda',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 14.sp,
                                  ),
                                  fillColor: Colors.grey.shade100,
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25.r),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 14.h,
                                  ),
                                ),
                                onChanged: (val) {
                                  _validateForm();
                                },
                                validator: (val) {
                                  if (val!.isEmpty) {
                                    return "Email tidak boleh kosong";
                                  }
                                  if (!RegExp(
                                    r'^[^@]+@[^@]+\.[^@]+',
                                  ).hasMatch(val)) {
                                    return "Masukkan format email yang valid";
                                  }
                                  return null;
                                },
                              ),

                              SizedBox(height: 16.h),
                              Text(
                                'Password',
                                style: TextStyle(
                                  color: const Color(0xFF121926),
                                  fontSize: 14.sp,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w500,
                                  height: 1.40,
                                ),
                              ),
                              SizedBox(height: 8.h),

                              // Password Field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                decoration: InputDecoration(
                                  hintText: 'Masukkan password anda',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 14.sp,
                                  ),
                                  fillColor: Colors.grey.shade100,
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25.r),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 14.h,
                                  ),
                                  // Suffix Icon untuk toggle visibility sudah benar
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.grey.shade600,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible =
                                            !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                                onChanged: (val) {
                                  _validateForm();
                                },
                                validator:
                                    (val) =>
                                        val!.length < 6
                                            ? "Minimal 6 karakter"
                                            : null,
                              ),

                              SizedBox(height: 32.h),

                              // Login Button
                              SizedBox(
                                width: double.infinity,
                                height: 50.h,
                                child: ElevatedButton(
                                  // Tombol dinonaktifkan jika _formComplete false
                                  onPressed: _formComplete ? login : null,
                                  child: Text(
                                    "Masuk",
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                    ), // Menggunakan .sp
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        _formComplete
                                            ? const Color(0xFF042341)
                                            : const Color(0xFFD6D1FA),
                                    foregroundColor:
                                        _formComplete
                                            ? Colors.white
                                            : Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25.r),
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: 24.h),

                              // Link ke RegisterScreen
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Belum punya akun ? ',
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
                                          builder:
                                              (_) => const RegisterScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Daftar',
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
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
