import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'pooling_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  final ApiService apiService;
  final bool showSuccessBanner;

  const HomeScreen({
    super.key,
    required this.apiService,
    this.showSuccessBanner = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final Set<int> _loadedTabs = {0};
  DateTime? _lastBackPress;
  bool _isBannerVisible = false;

  Widget _getScreen(int index) {
    if (!_loadedTabs.contains(index)) {
      return const SizedBox.shrink();
    }
    switch (index) {
      case 0:
        return SearchScreen(apiService: widget.apiService);
      case 1:
        return PoolingScreen(apiService: widget.apiService);
      case 2:
        return ProfileScreen(apiService: widget.apiService);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.showSuccessBanner) {
      _isBannerVisible = true;
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _isBannerVisible) {
          setState(() {
            _isBannerVisible = false;
          });
        }
      });
    }
  }

  Future<void> _onWillPop() async {
    // Jika bukan di tab Beranda → pindah ke tab Beranda terlebih dahulu
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
        _loadedTabs.add(0);
      });
      return;
    }

    // Jika sudah di Beranda → butuh tekan 2x dalam 2 detik untuk keluar aplikasi
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Tekan sekali lagi untuk keluar',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF1E2536),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          ),
        );
      }
      return;
    }

    // Tekan ke-2 dalam 2 detik → keluar aplikasi
    await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onWillPop();
      },
      child: Scaffold(
        body: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: [
                _getScreen(0),
                _getScreen(1),
                _getScreen(2),
              ],
            ),
            if (_isBannerVisible)
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                right: 16,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, -60 * (1 - value)),
                      child: Opacity(
                        opacity: value.clamp(0.0, 1.0),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131C32),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.8), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentGreen.withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accentGreen.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle_rounded, color: AppColors.accentGreen, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Verifikasi Berhasil!',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Nomor telepon Anda telah terverifikasi resmi.',
                                style: GoogleFonts.outfit(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.5,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isBannerVisible = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, color: Colors.white70, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF10141D),
            border: const Border(
                top: BorderSide(color: Color(0xFF1E2536), width: 1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (idx) {
              setState(() {
                _currentIndex = idx;
                _loadedTabs.add(idx);
              });
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            height: 68,
            indicatorColor: AppColors.primary.withValues(alpha: 0.25),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.phone_rounded,
                    color: AppColors.textSecondary, size: 24),
                selectedIcon: Icon(Icons.phone_rounded,
                    color: AppColors.primaryLight, size: 24),
                label: 'Beranda',
              ),
              NavigationDestination(
                icon: Icon(Icons.shield_outlined,
                    color: AppColors.textSecondary, size: 24),
                selectedIcon: Icon(Icons.shield_rounded,
                    color: AppColors.accentGreen, size: 24),
                label: 'Perlindungan',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded,
                    color: AppColors.textSecondary, size: 24),
                selectedIcon: Icon(Icons.person_rounded,
                    color: AppColors.primaryLight, size: 24),
                label: 'Profil Saya',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
