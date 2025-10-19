import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:imprup/Interface/Perusahaan%20UI/Home/company_home_screen.dart';
import 'package:imprup/Interface/Perusahaan%20UI/Profile/profile_company_screen.dart';
import 'package:imprup/Interface/Talenta%20UI/Home/home_screen.dart';
import 'package:imprup/Interface/Talenta%20UI/Profile/profile_screen.dart';

class NavbarCompany extends StatefulWidget {
  const NavbarCompany({super.key});

  @override
  State<NavbarCompany> createState() => _NavbarCompanyState();
}

class _NavbarCompanyState extends State<NavbarCompany> {
  int selectedIndex = 0;
  late List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      const CompanyHomeScreen(),
      const Center(child: Text('Chat Screen')),
      const Center(child: Text('Job/Project List')),
      const CompanyProfileScreen(),
    ];
  }

  final List<IconData> icons = [
    Icons.home,
    Icons.chat_bubble,
    Icons.laptop_chromebook,
    Icons.account_circle,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: Container(
        height: 70.h,
        padding: EdgeInsets.symmetric(horizontal: 20.h),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(icons.length, (index) {
            bool isSelected = selectedIndex == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(
                  horizontal: isSelected ? 25 : 0,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected ? const Color(0xFF042341) : Colors.transparent,
                  borderRadius: BorderRadius.circular(30.r),
                ),
                child: Icon(
                  icons[index],
                  color: isSelected ? Colors.white : Colors.grey,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
