import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/setup_profile_screen.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PhoneRepApp());
}

class PhoneRepApp extends StatefulWidget {
  const PhoneRepApp({super.key});

  @override
  State<PhoneRepApp> createState() => _PhoneRepAppState();
}

class _PhoneRepAppState extends State<PhoneRepApp> {
  final ApiService _apiService = ApiService();
  bool? _isProfileRegistered;

  @override
  void initState() {
    super.initState();
    _checkInitialProfile();
  }

  Future<void> _checkInitialProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('user_my_phone') ?? '';
    if (mounted) {
      setState(() {
        _isProfileRegistered = phone.trim().isNotEmpty;
      });
    }
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _apiService,
      builder: (context, child) {
        return MaterialApp(
          title: 'PhoneRep',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: _isProfileRegistered == null
              ? const _BrandedSplashScreen()
              : (_isProfileRegistered!
                  ? HomeScreen(apiService: _apiService)
                  : SetupProfileScreen(apiService: _apiService)),
        );
      },
    );
  }
}

// ─── Branded Splash Screen ────────────────────────────────────────────────────

class _BrandedSplashScreen extends StatefulWidget {
  const _BrandedSplashScreen();

  @override
  State<_BrandedSplashScreen> createState() => _BrandedSplashScreenState();
}

class _BrandedSplashScreenState extends State<_BrandedSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _scaleAnim = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _progressAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1B3E), Color(0xFF0A0D14), Color(0xFF0A0D14)],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // Logo Icon dengan animasi Scale
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryLight,
                          AppColors.primary,
                          Color(0xFF0D1B3E),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.55),
                          blurRadius: 40,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF0E1525),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.shield_rounded,
                          size: 46,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Nama Aplikasi
                const Text(
                  'PhoneRep',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 8),

                // Tagline
                const Text(
                  'Reputasi Nomor, Dalam Genggaman Anda',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),

                const Spacer(flex: 3),

                // Loading bar bertema (bottom)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 64),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _progressAnim,
                        builder: (context, _) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: SizedBox(
                              height: 3,
                              child: LinearProgressIndicator(
                                value: _progressAnim.value,
                                backgroundColor: const Color(0xFF1E2636),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryLight,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Menyiapkan sesi keamanan...',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
