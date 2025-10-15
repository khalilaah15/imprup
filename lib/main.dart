import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:imprup/Interface/Auth/auth_gate.dart';
import 'package:imprup/Interface/Auth/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String supabaseUrl = 'https://ztvzdzjzttvmsoyzgfij.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp0dnpkemp6dHR2bXNveXpnZmlqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAzNTQ3NTksImV4cCI6MjA3NTkzMDc1OX0.CyHYyRu6xsBtakILR2DzVfXZxTaZMwdk_r0NWDQgya0';

final supabase = Supabase.instance.client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Inisialisasi ScreenUtil di sini
    return ScreenUtilInit(
      designSize: const Size(360, 690), // Ukuran desain default Anda
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'ImprUp',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.green,
            fontFamily: 'Poppins',
          ),
          // AuthGate akan menentukan apakah user harus ke Login atau Home
          home: const AuthGate(), 
        );
      },
    );
  }
}