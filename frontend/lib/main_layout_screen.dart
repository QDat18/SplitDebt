import 'package:flutter/material.dart';
import 'features/groups/dashboard_screen.dart';
import 'features/home/home_screen.dart';
import 'features/home/pdf_overview_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/expenses/create_expense_screen.dart';
import 'features/settlements/live_settlement_screen.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            DashboardScreen(
              onNavigateToCreateExpense: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreateExpenseScreen(),
                  ),
                );
              },
              onNavigateToSettlement: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const GroupSettlementScreen(),
                  ),
                );
              },
            ),
            const HomeScreen(),
            const OverviewScreen(key: ValueKey('history'), history: true),
            const ProfileScreen(),
          ],
        ),
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
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Nhóm',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'Lịch sử',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Cá nhân',
            ),
          ],
        ),
      );
}
