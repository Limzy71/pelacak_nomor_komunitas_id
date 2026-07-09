import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'analytics_screen.dart';
import 'pooling_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  final ApiService apiService;

  const HomeScreen({super.key, required this.apiService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      SearchScreen(apiService: widget.apiService),
      PoolingScreen(apiService: widget.apiService),
      AnalyticsScreen(apiService: widget.apiService),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
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
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          indicatorColor: AppColors.primary.withValues(alpha: 0.2),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.manage_search_outlined, color: AppColors.textSecondary),
              selectedIcon: const Icon(Icons.manage_search_rounded, color: AppColors.primaryLight),
              label: 'Pencarian & Tag',
            ),
            NavigationDestination(
              icon: const Icon(Icons.sync_outlined, color: AppColors.textSecondary),
              selectedIcon: const Icon(Icons.sync_rounded, color: AppColors.accentGreen),
              label: 'Contact Pooling',
            ),
            NavigationDestination(
              icon: const Icon(Icons.analytics_outlined, color: AppColors.textSecondary),
              selectedIcon: const Icon(Icons.analytics_rounded, color: AppColors.accentOrange),
              label: 'Statistik',
            ),
          ],
        ),
      ),
    );
  }
}
