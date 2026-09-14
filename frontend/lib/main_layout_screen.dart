import 'package:flutter/material.dart';
import 'features/home/home_screen.dart';
import 'features/home/pdf_overview_screen.dart';
import 'features/profile/profile_screen.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});
  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _index = 1;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: switch (_index) {
          0 => const OverviewScreen(),
          1 => const HomeScreen(),
          2 => const OverviewScreen(key: ValueKey('history'), history: true),
          _ => const ProfileScreen()
        },
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF6C5CE7),
          unselectedItemColor: const Color(0xFF87909E),
          selectedFontSize: 10,
          unselectedFontSize: 10,
          iconSize: 22,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined), label: 'Trang chủ'),
            BottomNavigationBarItem(
                icon: Icon(Icons.people_outline), label: 'Nhóm'),
            BottomNavigationBarItem(
                icon: Icon(Icons.history), label: 'Lịch sử'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline), label: 'Cá nhân'),
          ],
        ),
      );
}
