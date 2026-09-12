import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/premium_ui.dart';
import 'data/api.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'widgets/design.dart';

String? startupError;
bool onboardingDone = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Appearance.load();
    final prefs = await SharedPreferences.getInstance();
    onboardingDone = prefs.getBool('onboarding_done') ?? false;
    if (AppConstants.configured) await Session.restoreLocal();
  } catch (error, stackTrace) {
    startupError = 'Không thể khởi động SplitDebt. Hãy kiểm tra cấu hình API rồi mở lại ứng dụng.';
    debugPrint('SplitDebt startup error: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
  runApp(const SplitDebtApp());
}

class SplitDebtApp extends StatelessWidget {
  const SplitDebtApp({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
    valueListenable: Appearance.mode,
    builder: (context, mode, _) => MaterialApp(
      title: 'SplitDebt',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: SplitSplashScreen(
        destination: !AppConstants.configured || startupError != null
            ? SetupRequiredScreen(message: startupError)
            : !onboardingDone
                ? const OnboardingScreen()
                : const SessionGate(),
      ),
    ),
  );
}

class SplitSplashScreen extends StatefulWidget {
  const SplitSplashScreen({super.key, required this.destination});
  final Widget destination;

  @override
  State<SplitSplashScreen> createState() => _SplitSplashScreenState();
}

class _SplitSplashScreenState extends State<SplitSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _float;
  late final AnimationController _progress;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _progress = AnimationController(vsync: this, duration: const Duration(milliseconds: 1150))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finish();
      });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && !_progress.isAnimating && !_progress.isCompleted) _progress.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _float.stop();
      _float.value = .25;
    } else if (!_float.isAnimating) {
      _float.repeat();
    }
  }

  Future<void> _finish() async {
    if (_navigated || !mounted) return;
    _navigated = true;
    await Future<void>.delayed(
      MediaQuery.disableAnimationsOf(context)
          ? const Duration(milliseconds: 80)
          : const Duration(milliseconds: 180),
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 360),
        pageBuilder: (_, animation, secondaryAnimation) => widget.destination,
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: .985, end: 1).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _float.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: PremiumBackground(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;
                final narrow = width < 380;
                final short = height < 640;
                final logoSize = math.min(
                  short ? 142.0 : narrow ? 162.0 : 192.0,
                  width * .50,
                ).toDouble();
                final glowSize = logoSize + (short ? 24 : 34);
                final titleSize = short ? 36.0 : narrow ? 40.0 : 48.0;
                final edge = narrow ? 16.0 : 20.0;
                final bottom = short ? 24.0 : 48.0;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Align(
                      alignment: short ? const Alignment(0, -.16) : const Alignment(0, -.08),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: edge),
                        child: AnimatedBuilder(
                          animation: _float,
                          builder: (context, _) {
                            final t = _float.value * math.pi * 2;
                            final dy = math.sin(t) * (short ? 6 : 10);
                            final scale = 1 + math.sin(t) * .012;
                            return Transform.translate(
                              offset: Offset(0, dy),
                              child: Transform.scale(
                                scale: scale,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          width: glowSize,
                                          height: glowSize,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.primary.withValues(alpha: .22),
                                                blurRadius: short ? 48 : 72,
                                                spreadRadius: short ? 10 : 16,
                                              ),
                                              BoxShadow(
                                                color: AppColors.tertiary.withValues(alpha: .12),
                                                blurRadius: short ? 42 : 60,
                                              ),
                                            ],
                                          ),
                                        ),
                                        SplitDebtBrandMark(size: logoSize, showCoin: false),
                                      ],
                                    ),
                                    SizedBox(height: short ? 18 : 28),
                                    AnimatedBuilder(
                                      animation: _float,
                                      builder: (context, child) => ShaderMask(
                                        blendMode: BlendMode.srcIn,
                                        shaderCallback: (bounds) {
                                          final shift = math.sin(_float.value * math.pi * 2) * .45;
                                          return LinearGradient(
                                            begin: Alignment(-1 + shift, -1),
                                            end: Alignment(1 + shift, 1),
                                            colors: const [
                                              AppColors.tertiary,
                                              AppColors.secondary,
                                              AppColors.primary,
                                              AppColors.tertiary,
                                            ],
                                          ).createShader(bounds);
                                        },
                                        child: child,
                                      ),
                                      child: Text(
                                        'SplitDebt',
                                        style: TextStyle(
                                          fontSize: titleSize,
                                          height: 1.06,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -1,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'CHIA TIỀN RÕ RÀNG · QUYẾT TOÁN GỌN',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: narrow ? 9 : 10,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: narrow ? 1.5 : 2.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      left: edge,
                      right: edge,
                      bottom: bottom,
                      child: Align(
                        alignment: Alignment.center,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: SizedBox(
                            width: double.infinity,
                            child: AnimatedBuilder(
                              animation: _progress,
                              builder: (context, _) {
                                final eased = Curves.easeOutCubic.transform(_progress.value);
                                final percentage = (eased * 100).clamp(0, 100).floor();
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'Đang chuẩn bị trải nghiệm',
                                          style: TextStyle(
                                            fontFamily: 'Geist',
                                            color: AppColors.textSecondary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: .45,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '$percentage%',
                                          style: const TextStyle(
                                            fontFamily: 'Geist',
                                            color: AppColors.primary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      height: 8,
                                      padding: const EdgeInsets.all(1),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceHigh,
                                        borderRadius: BorderRadius.circular(999),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: .48),
                                            blurRadius: 7,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: LayoutBuilder(
                                        builder: (context, barConstraints) => Align(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            width: barConstraints.maxWidth * eased,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(999),
                                              gradient: const LinearGradient(
                                                colors: [AppColors.primary, Color(0xFF6FFBBE)],
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.primary.withValues(alpha: .60),
                                                  blurRadius: _progress.isCompleted ? 18 : 9,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

}

class SessionGate extends StatelessWidget {
  const SessionGate({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: Session.authenticated,
        builder: (context, signedIn, _) => AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 420),
          reverseDuration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final slide = Tween<Offset>(
              begin: const Offset(.025, .015),
              end: Offset.zero,
            ).animate(animation);
            final scale = Tween<double>(begin: .99, end: 1).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: slide,
                child: ScaleTransition(scale: scale, child: child),
              ),
            );
          },
          child: signedIn
              ? const HomeScreen(key: ValueKey('session-home'))
              : const LoginScreen(key: ValueKey('session-login')),
        ),
      );
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  int page = 0;

  static const pages = <_OnboardingPageData>[
    _OnboardingPageData(
      eyebrow: 'CHIA TIỀN THÔNG MINH',
      title: 'Chia tiền nhóm dễ dàng & công bằng',
      description:
          'Ghi rõ nhóm, khoản chi, người trả và phần của từng thành viên. Mọi người đều nhìn thấy mình cần trả bao nhiêu hoặc sẽ nhận bao nhiêu.',
      image: 'assets/reference/financial-3d-icons.png',
      accent: AppColors.primary,
      icon: Icons.account_balance_wallet_outlined,
      highlights: ['5 chế độ chia', 'Rõ người trả', 'Công nợ minh bạch'],
    ),
    _OnboardingPageData(
      eyebrow: 'SMART SETTLEMENT',
      title: 'Thanh toán gọn, không chuyển vòng vèo',
      description:
          'SplitDebt tính số dư ròng và gợi ý luồng thanh toán ngắn hơn. Bạn biết chính xác mình trả cho ai, thu từ ai và trạng thái từng khoản.',
      image: 'assets/reference/debt-ledger-3d.png',
      accent: AppColors.tertiary,
      icon: Icons.route_rounded,
      highlights: ['Ít giao dịch hơn', 'Theo dõi 2 chiều', 'Xác nhận rõ ràng'],
    ),
    _OnboardingPageData(
      eyebrow: 'THEO DÕI TRỰC QUAN',
      title: 'Biết mình đã chi bao nhiêu theo thời gian',
      description:
          'Dashboard và thống kê tập trung vào số tiền của chính bạn. Lọc theo ngày, tháng hoặc năm và xem nhóm nào đang cần xử lý ngay.',
      image: 'assets/reference/analytics-donut-3d.png',
      accent: AppColors.secondary,
      icon: Icons.analytics_outlined,
      highlights: ['Ngày / Tháng / Năm', 'Thông báo 1 chạm', 'Responsive mọi máy'],
    ),
  ];

  Future<void> finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    onboardingDone = true;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SessionGate()),
    );
  }

  Future<void> next() async {
    if (page == pages.length - 1) {
      await finish();
      return;
    }
    await controller.nextPage(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: PremiumBackground(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;
                final phone = width < 700;
                final narrow = width < 380;
                final short = height < 680;
                final edge = narrow ? 14.0 : phone ? 20.0 : 32.0;
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(edge, 8, edge, 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 44,
                                height: 44,
                                child: page == 0
                                    ? const SizedBox.shrink()
                                    : IconButton.filledTonal(
                                        tooltip: 'Quay lại',
                                        onPressed: () => controller.previousPage(
                                          duration: MediaQuery.disableAnimationsOf(context)
                                              ? Duration.zero
                                              : const Duration(milliseconds: 260),
                                          curve: Curves.easeOutCubic,
                                        ),
                                        icon: const Icon(Icons.arrow_back_rounded),
                                      ),
                              ),
                              Expanded(
                                child: Center(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: pages[page].accent.withValues(alpha: .10),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: pages[page].accent.withValues(alpha: .18),
                                      ),
                                    ),
                                    child: Text(
                                      'BƯỚC ${page + 1} / ${pages.length}',
                                      style: TextStyle(
                                        fontFamily: 'Geist',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: .7,
                                        color: pages[page].accent,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: narrow ? 58 : 72,
                                child: TextButton(
                                  onPressed: finish,
                                  child: const Text('Bỏ qua'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: PageView.builder(
                            controller: controller,
                            itemCount: pages.length,
                            onPageChanged: (value) => setState(() => page = value),
                            itemBuilder: (context, index) => _OnboardingPageView(
                              data: pages[index],
                              phone: phone,
                              compact: short,
                              edge: edge,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(edge, 8, edge, narrow ? 10 : 16),
                          child: phone
                              ? Column(
                                  children: [
                                    _OnboardingDots(count: pages.length, selected: page),
                                    const SizedBox(height: 14),
                                    BrandButton(
                                      label: page == pages.length - 1
                                          ? 'Bắt đầu trải nghiệm'
                                          : 'Tiếp tục',
                                      icon: page == pages.length - 1
                                          ? Icons.rocket_launch_rounded
                                          : Icons.arrow_forward_rounded,
                                      onPressed: next,
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    _OnboardingDots(count: pages.length, selected: page),
                                    const Spacer(),
                                    SizedBox(
                                      width: 280,
                                      child: BrandButton(
                                        label: page == pages.length - 1
                                            ? 'Bắt đầu trải nghiệm'
                                            : 'Tiếp tục',
                                        icon: page == pages.length - 1
                                            ? Icons.rocket_launch_rounded
                                            : Icons.arrow_forward_rounded,
                                        onPressed: next,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.image,
    required this.accent,
    required this.icon,
    required this.highlights,
  });

  final String eyebrow;
  final String title;
  final String description;
  final String image;
  final Color accent;
  final IconData icon;
  final List<String> highlights;
}

class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({
    required this.data,
    required this.phone,
    required this.compact,
    required this.edge,
  });

  final _OnboardingPageData data;
  final bool phone;
  final bool compact;
  final double edge;

  @override
  Widget build(BuildContext context) {
    final visual = Container(
      constraints: BoxConstraints(
        minHeight: phone ? (compact ? 190 : 230) : 360,
        maxHeight: phone ? (compact ? 235 : 310) : 520,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(phone ? 24 : 32),
        color: AppColors.surfaceLow.withValues(alpha: .86),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: data.accent.withValues(alpha: .10),
            blurRadius: 42,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: .32),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(.45, -.45),
                radius: .95,
                colors: [
                  data.accent.withValues(alpha: .12),
                  AppColors.surfaceLow.withValues(alpha: .12),
                  AppColors.surfaceLowest,
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(phone ? 12 : 24),
            child: Image.asset(
              data.image,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh.withValues(alpha: .92),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: data.accent.withValues(alpha: .25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(data.icon, size: 16, color: data.accent),
                  const SizedBox(width: 7),
                  Text(
                    data.eyebrow,
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .55,
                      color: data.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    final copy = GlassSurface(
      borderRadius: phone ? 24 : 28,
      padding: EdgeInsets.all(phone ? (compact ? 18 : 22) : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: data.accent.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(data.icon, color: data.accent, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  data.eyebrow,
                  style: TextStyle(
                    fontFamily: 'Geist',
                    color: data.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: .75,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 14 : 20),
          Text(
            data.title,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: phone ? (compact ? 24 : 28) : 38,
                  height: 1.12,
                  letterSpacing: -.6,
                ),
          ),
          SizedBox(height: compact ? 10 : 14),
          Text(
            data.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: phone ? (compact ? 13 : 15) : 17,
                  height: 1.5,
                ),
          ),
          SizedBox(height: compact ? 14 : 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in data.highlights)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighest.withValues(alpha: .72),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 14, color: data.accent),
                      const SizedBox(width: 6),
                      Text(
                        item,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(edge, compact ? 10 : 18, edge, 12),
      child: phone
          ? Column(
              children: [
                visual,
                SizedBox(height: compact ? 12 : 18),
                copy,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 6, child: visual),
                const SizedBox(width: 28),
                Expanded(flex: 5, child: copy),
              ],
            ),
    );
  }
}

class _OnboardingDots extends StatelessWidget {
  const _OnboardingDots({required this.count, required this.selected});
  final int count;
  final int selected;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          count,
          (index) => AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: index == selected ? 34 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: index == selected ? AppColors.primary : AppColors.surfaceHighest,
              borderRadius: BorderRadius.circular(999),
              boxShadow: index == selected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: .26),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      );
}

class SetupRequiredScreen extends StatelessWidget {
  const SetupRequiredScreen({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Surface(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Orb(icon: Icons.settings_suggest_rounded),
                const SizedBox(height: 22),
                Text('Cần cấu hình Backend', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Text(message ?? 'Hãy chạy Backend và truyền API_URL bằng --dart-define nếu cần, sau đó mở lại ứng dụng.', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                SelectableText(AppConstants.apiUrl, textAlign: TextAlign.center),
              ]),
            ),
          ),
        ),
      ),
    ),
  );
}
