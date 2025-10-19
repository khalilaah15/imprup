import 'package:flutter/material.dart';
import 'package:imprup/Interface/Auth/login_screen.dart';
import 'package:imprup/Interface/Perusahaan%20UI/navbar_company.dart';
import 'package:imprup/Interface/Talenta%20UI/navbar.dart';
import 'package:imprup/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Perusahaan UI/Home/company_home_screen.dart';
import '../Talenta UI/Home/home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Memantau status Auth Supabase secara real-time
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final Session? session = snapshot.data?.session;

        // Jika tidak ada sesi (Belum Login)
        if (session == null) {
          return const LoginScreen();
        }

        // Jika ada sesi (Sudah Login), cek Role
        return FutureBuilder<String>(
          future: AuthService().getUserRole(),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (roleSnapshot.hasError || !roleSnapshot.hasData) {
              // Jika gagal fetch role, arahkan ke login (mungkin profil belum lengkap)
              return const LoginScreen();
            }

            final userRole = roleSnapshot.data;

            // Navigasi berdasarkan Role
            if (userRole == 'Talenta') {
              return const Navbar();
            } else if (userRole == 'Perusahaan') {
              return const NavbarCompany();
            } else {
              // Default fallback
              return const LoginScreen();
            }
          },
        );
      },
    );
  }
}
