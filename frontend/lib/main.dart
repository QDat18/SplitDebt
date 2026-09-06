import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'features/auth/login_screen.dart';
import 'features/expenses/create_expense_screen.dart';
import 'features/settlements/group_settlement_screen.dart';

import 'main_layout_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(
    const ProviderScope(child: SplitDebtApp()),
  );
}

class SplitDebtApp extends StatelessWidget {
  const SplitDebtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SplitDebt',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const MainLayoutScreen(),
    );
  }
}

// =========================================================================
// MÀN HÌNH SPLASH SCREEN CHÀO MỪNG SANG TRỌNG & TINH TẾ (CLEAN & ELEGANT)
// =========================================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;

  late Animation<double> _heroFloatAnimation;
  late Animation<double> _glowPulseAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Controller di chuyển floating mượt mà
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    )..repeat(reverse: true);

    // 2. Controller tạo vầng sáng nhịp thở
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    // Quỹ đạo di chuyển cho Logo trung tâm
    _heroFloatAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeInOutSine),
    );

    _glowPulseAnimation = Tween<double>(begin: 0.35, end: 0.75).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _checkAuthAndNavigate() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder:
            (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 1. NỀN GRADIENT SÂU CÙNG CÁC ĐỐM SÁNG AMBIENT GLOW
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF14151A), // Dark N900
                    Color(0xFF241B60), // Purple P900
                    Color(0xFF4433B0), // Purple P800
                    Color(0xFF1E1E24), // Dark N800
                  ],
                  stops: [0.0, 0.45, 0.8, 1.0],
                ),
              ),
            ),
          ),

          // 2. ĐỐM SÁNG TÍM AMBIENT LIGHT BLOBS CENTERED
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Positioned(
                top: size.height * 0.22,
                left: size.width * 0.5 - 140,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.p500.withOpacity(_glowPulseAnimation.value),
                        AppColors.p300.withOpacity(_glowPulseAnimation.value * 0.4),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),

          // 3. NỘI DUNG CHÍNH (HERO ICON + BRANDING + ACTION BUTTONS)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.s24),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // -------------------------------------------------------------
                  // LOGO TRUNG TÂM SANG TRỌNG VỚI HỆ THỐNG VẦNG SÁNG & BO GÓC
                  // -------------------------------------------------------------
                  AnimatedBuilder(
                    animation: _mainController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _heroFloatAnimation.value),
                        child: child,
                      );
                    },
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.p400, AppColors.p600],
                        ),
                        borderRadius: BorderRadius.circular(36),
                        border: Border.all(
                          color: AppColors.n0.withOpacity(0.4),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.p500.withOpacity(0.55),
                            blurRadius: 40,
                            spreadRadius: 10,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.call_split_rounded,
                          size: 64,
                          color: AppColors.n0,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppDimensions.s32),

                  // -------------------------------------------------------------
                  // TÊN THƯƠNG HIỆU SPLITDEBT & CHỦ ĐỀ SÓNG PHẲNG
                  // -------------------------------------------------------------
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [AppColors.n0, AppColors.p100, AppColors.p200],
                    ).createShader(bounds),
                    child: Text(
                      'SPLITDEBT',
                      style: AppTypography.display.copyWith(
                        color: AppColors.n0,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6.0,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppDimensions.s12),

                  // FROSTED GLASS BADGE TAGLINE
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.s20,
                      vertical: AppDimensions.s8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.n0.withOpacity(0.12),
                      borderRadius: AppDimensions.radius24,
                      border: Border.all(color: AppColors.n0.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Chia tiền nhóm • Sòng phẳng cuộc vui',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.n0.withOpacity(0.95),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 3),

                  // -------------------------------------------------------------
                  // ACTION BUTTONS (NÚT BẮT ĐẦU VÀ NÚT TEST BACKEND SERVER)
                  // -------------------------------------------------------------
                  // NÚT KHÁM PHÁ NGAY (PRIMARY GRADIENT BUTTON)
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.n0, Color(0xFFF1EFFE)],
                      ),
                      borderRadius: AppDimensions.radius16,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.p500.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const CreateExpenseScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: AppColors.p900,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppDimensions.radius16,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Tạo Khoản Chi Mới',
                            style: AppTypography.title.copyWith(
                              color: AppColors.p900,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.s8),
                          const Icon(
                            Icons.add_circle_outline_rounded,
                            size: 22,
                            color: AppColors.p900,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppDimensions.s12),

                  // NÚT MỞ MÀN HÌNH QUYẾT TOÁN NỢ NHÓM (MIN-CASH-FLOW BE2-SET-01)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const GroupSettlementScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.p200,
                        size: 20,
                      ),
                      label: Text(
                        'Quyết Toán Nợ Nhóm (Min-Flow)',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.n0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.n0.withOpacity(0.12),
                        side: BorderSide(
                          color: AppColors.p300.withOpacity(0.4),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppDimensions.radius16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppDimensions.s12),

                  // NÚT TEST API BACKEND (FROSTED GLASS BUTTON)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          final url = Uri.parse('http://localhost:8080/api/health');
                          final response = await http
                              .get(url)
                              .timeout(const Duration(seconds: 4));

                          if (context.mounted) {
                            if (response.statusCode == 200) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '✅ Backend Kết nối thành công: ${response.body}',
                                  ),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppDimensions.radius12,
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '⚠️ Lỗi phản hồi Server: Status ${response.statusCode}',
                                  ),
                                  backgroundColor: AppColors.warning,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppDimensions.radius12,
                                  ),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '❌ Mất kết nối Server (kiểm tra 8080/10.0.2.2): $e',
                                ),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: AppDimensions.radius12,
                                ),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(
                        Icons.bolt_rounded,
                        color: AppColors.p200,
                        size: 20,
                      ),
                      label: Text(
                        'Test API Backend Server (8080)',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.n0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.n0.withOpacity(0.08),
                        side: BorderSide(
                          color: AppColors.n0.withOpacity(0.25),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppDimensions.radius16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppDimensions.s28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
