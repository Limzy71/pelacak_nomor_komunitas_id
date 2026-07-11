import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'analytics_screen.dart';
import 'pooling_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  final ApiService apiService;

  const HomeScreen({super.key, required this.apiService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final Set<int> _loadedTabs = {0}; // Hanya muat tab 0 (Beranda) saat startup agar tidak stuck loading

  Widget _getScreen(int index) {
    if (!_loadedTabs.contains(index)) {
      return const SizedBox.shrink();
    }
    switch (index) {
      case 0:
        return SearchScreen(apiService: widget.apiService);
      case 1:
        return ProfileScreen(apiService: widget.apiService);
      case 2:
        return PoolingScreen(apiService: widget.apiService);
      case 3:
        return AnalyticsScreen(apiService: widget.apiService);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _getScreen(0),
          _getScreen(1),
          _getScreen(2),
          _getScreen(3),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF10141D),
          border: const Border(top: BorderSide(color: Color(0xFF1E2536), width: 1)),
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
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.phone_rounded, color: AppColors.textSecondary, size: 24),
              selectedIcon: const Icon(Icons.phone_rounded, color: AppColors.primaryLight, size: 24),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline_rounded, color: AppColors.textSecondary, size: 24),
              selectedIcon: const Icon(Icons.person_rounded, color: AppColors.primaryLight, size: 24),
              label: 'Profil Saya',
            ),
            NavigationDestination(
              icon: const Icon(Icons.shield_outlined, color: AppColors.textSecondary, size: 24),
              selectedIcon: const Icon(Icons.shield_rounded, color: AppColors.accentGreen, size: 24),
              label: 'Perlindungan',
            ),
            NavigationDestination(
              icon: const Icon(Icons.menu_rounded, color: AppColors.textSecondary, size: 24),
              selectedIcon: const Icon(Icons.menu_open_rounded, color: AppColors.accentOrange, size: 24),
              label: 'Menu',
            ),
          ],
        ),
      ),
    );
  }
}
