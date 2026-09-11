import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_dimensions.dart';
import 'core/theme/app_typography.dart';
import 'features/groups/dashboard_screen.dart';
import 'features/expenses/create_expense_screen.dart';
import 'features/settlements/group_settlement_screen.dart';
import 'features/profile/settings_screen.dart';

/// ----------------------------------------------------------------------------
/// MÀN HÌNH KHUNG ĐIỀU HƯỚNG CHÍNH (MAIN LAYOUT SCREEN WITH BOTTOM NAVBAR)
/// Tích hợp Bottom Navigation Bar điều chuyển giữa 4 Module ứng dụng
/// ----------------------------------------------------------------------------
class MainLayoutScreen extends ConsumerStatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  ConsumerState<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends ConsumerState<MainLayoutScreen> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.n50,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Tab 0: Trang chủ Dashboard
          DashboardScreen(
            onNavigateToCreateExpense: () => _onTabTapped(1),
            onNavigateToSettlement: () => _onTabTapped(2),
          ),

          // Tab 1: Tạo khoản chi mới
          const CreateExpenseScreen(),

          // Tab 2: Quyết toán nợ nhóm (Min-Cash-Flow)
          const GroupSettlementScreen(),

          // Tab 3: Cài đặt nhóm & cá nhân
          const SettingsScreen(),
        ],
      ),

      // --- BOTTOM NAVIGATION BAR CHUẨN DESIGN TOKENS ---
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.n0,
          boxShadow: AppDimensions.shadowLg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.r24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Trang chủ'),
                _buildNavItem(1, Icons.add_circle_rounded, Icons.add_circle_outline_rounded, 'Tạo chi tiêu'),
                _buildNavItem(2, Icons.auto_awesome_rounded, Icons.auto_awesome_outlined, 'Quyết toán'),
                _buildNavItem(3, Icons.settings_rounded, Icons.settings_outlined, 'Cài đặt'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => _onTabTapped(index),
      borderRadius: AppDimensions.radius16,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.p50 : Colors.transparent,
          borderRadius: AppDimensions.radius16,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? AppColors.p500 : AppColors.n600,
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.label.copyWith(
                  color: AppColors.p600,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
