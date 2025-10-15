import 'package:flutter/material.dart';
import 'package:imprup/Interface/Auth/auth_gate.dart';
import 'package:imprup/Interface/Perusahaan%20UI/Profile/profile_company_screen.dart';
import 'package:imprup/services/auth_service.dart';

class CompanyHomeScreen extends StatelessWidget {
  const CompanyHomeScreen({super.key});

  void _logout(BuildContext context) async {
    await AuthService().signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CompanyProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perusahaan Home'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
          IconButton(
            onPressed: () => _navigateToProfile(context),
            icon: Icon(Icons.person),
          ),
        ],
      ),
      body: const Center(child: Text('Selamat datang, Perusahaan!')),
    );
  }
}
