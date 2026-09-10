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
    if (AppConstants.configured) await Session.initialize();
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
      themeMode: mode,
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
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
    Future.delayed(const Duration(milliseconds: 1050), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 340),
          pageBuilder: (_, animation, secondaryAnimation) => widget.destination,
          transitionsBuilder: (_, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.primary,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF5843CE), Color(0xFF7659EA)],
                ),
              ),
            ),
            Positioned(
              right: -80,
              bottom: -120,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(.06),
                ),
              ),
            ),
            Center(
              child: FadeTransition(
                opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
                child: ScaleTransition(
                  scale: Tween<double>(begin: .86, end: 1).animate(
                    CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.12),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withOpacity(.18)),
                        ),
                        child: const Icon(Icons.content_cut_rounded, color: Colors.white, size: 46),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'SPLITDEBT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Chia đều hơn, nhẹ đầu hơn',
                        style: TextStyle(color: Color(0xFFE6E1FF), fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: 74,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class SessionGate extends StatelessWidget {
  const SessionGate({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: Session.authenticated,
    builder: (context, signedIn, _) => signedIn ? const HomeScreen() : const LoginScreen(),
  );
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  int page = 0;
  static const pages = [
    ('Ghi chi tiêu nhóm dễ dàng', 'Thêm khoản chi, người trả, danh mục và người tham gia chỉ trong vài bước.', '💸', 'Mọi khoản chi ở cùng một nơi'),
    ('Xén nợ thông minh', 'Tự động tính số dư ròng và đề xuất ít giao dịch hơn để cả nhóm quyết toán nhanh.', '✂️', 'Smart Settlement'),
    ('Theo dõi minh bạch', 'Biết ai đang nợ, ai được nhận và trạng thái thanh toán theo thời gian thực.', '📈', 'Rõ ràng từ đầu đến cuối'),
  ];

  Future<void> finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    onboardingDone = true;
    if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SessionGate()));
  }

  @override void dispose() { controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    body: PremiumBackground(
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
            child: Row(children: [
              const BrandMark(size: 42),
              const Spacer(),
              TextButton(onPressed: finish, child: const Text('Bỏ qua')),
            ]),
          ),
          Expanded(
            child: PageView.builder(
              controller: controller,
              itemCount: pages.length,
              onPageChanged: (value) => setState(() => page = value),
              itemBuilder: (context, index) {
                final item = pages[index];
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: Entrance(
                        child: GlassSurface(
                          padding: const EdgeInsets.all(28),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Container(
                              width: 112,
                              height: 112,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [BoxShadow(
                                  color: AppColors.primary.withOpacity(.10),
                                  blurRadius: 28,
                                  offset: const Offset(0, 14),
                                )],
                              ),
                              alignment: Alignment.center,
                              child: Text(item.$3, style: const TextStyle(fontSize: 52)),
                            ),
                            const SizedBox(height: 30),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(.08),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(item.$4, style: const TextStyle(
                                color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w900)),
                            ),
                            const SizedBox(height: 18),
                            Text(item.$1, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
                            const SizedBox(height: 14),
                            Text(item.$2, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
                            const SizedBox(height: 24),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: const [
                                StatusPill(label: 'Dễ sử dụng', kind: FeedbackKind.success),
                                StatusPill(label: 'Minh bạch', kind: FeedbackKind.info),
                                StatusPill(label: 'Không giữ tiền', kind: FeedbackKind.warning),
                              ],
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(pages.length, (i) => AnimatedContainer(
                  duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == page ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == page ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ))),
                const SizedBox(height: 20),
                BrandButton(
                  label: page == pages.length - 1 ? 'Bắt đầu với SplitDebt' : 'Tiếp tục',
                  icon: page == pages.length - 1 ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                  onPressed: () => page == pages.length - 1
                      ? finish()
                      : controller.nextPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic),
                ),
              ]),
            ),
          ),
        ]),
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
