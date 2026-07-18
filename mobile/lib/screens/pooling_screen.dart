import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class PoolingScreen extends StatefulWidget {
  final ApiService apiService;

  const PoolingScreen({super.key, required this.apiService});

  @override
  State<PoolingScreen> createState() => _PoolingScreenState();
}

class _PoolingScreenState extends State<PoolingScreen> {
  // State kontak dan pooling dihapus (Tugas 5)

  // Toggle states struktur perisai
  bool _isDefaultPhoneApp = true;
  bool _isOverlayAllowed = true;

  @override
  void initState() {
    super.initState();
    widget.apiService.addListener(_onApiServiceChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // _checkPermission() dihapus
      }
    });
  }

  void _onApiServiceChanged() {
    if (mounted) {
      setState(() {
        // ...
      });
    }
  }

  @override
  void dispose() {
    widget.apiService.removeListener(_onApiServiceChanged);
    super.dispose();
  }

  // Fungsi terkait kontak dan pooling dihapus (Tugas 5)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F131D),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar struktur kapsul rapi
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: const Color(0xFF131824),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2637),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF2E384D), width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_outlined, color: AppColors.primaryLight, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Pengaturan Perlindungan & Pooling',
                              style: GoogleFonts.sora(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kartu 1: Selalu ketahui siapa yang menelepon Anda
                    _buildBlueToggleCard(
                      title: 'Selalu ketahui siapa yang menelepon Anda.',
                      subtitle: 'Atur PhoneRep sebagai aplikasi telepon default sehingga sistem dapat mengidentifikasi panggilan masuk untuk melindungi Anda dari panggilan spam.',
                      value: _isDefaultPhoneApp,
                      onChanged: (v) => setState(() => _isDefaultPhoneApp = v),
                    ),
                    const SizedBox(height: 14),

                    // Kartu 2: Izinkan untuk ditampilkan pada layar
                    _buildBlueToggleCard(
                      title: 'Izinkan untuk ditampilkan pada layar',
                      subtitle: 'Saat nomor tidak dikenal menelepon, kartu reputasi penelepon akan muncul di layar Anda secara otomatis.',
                      value: _isOverlayAllowed,
                      onChanged: (v) => setState(() => _isOverlayAllowed = v),
                    ),
                    const SizedBox(height: 28),

                    // Bagian Contact Pooling Sekali Klik dihapus untuk privasi (Tugas 5)
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlueToggleCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2B8CFF),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2B8CFF).withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF0F172A),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFF1E293B),
          ),
        ],
      ),
    );
  }
}
