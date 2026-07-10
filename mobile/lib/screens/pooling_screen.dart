import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/phone_record.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class PoolingScreen extends StatefulWidget {
  final ApiService apiService;

  const PoolingScreen({super.key, required this.apiService});

  @override
  State<PoolingScreen> createState() => _PoolingScreenState();
}

class _PoolingScreenState extends State<PoolingScreen> {
  bool _isLoading = false;
  bool _hasPermission = false;
  List<Contact> _contacts = [];
  SyncContactResult? _lastSyncResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.contacts.status;
    setState(() {
      _hasPermission = status.isGranted;
    });
    if (_hasPermission) {
      _loadContacts();
    }
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final status = await Permission.contacts.request();
    setState(() {
      _hasPermission = status.isGranted;
      _isLoading = false;
    });

    if (_hasPermission) {
      await _loadContacts();
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.cardBgElevated,
            title: Text('Izin Kontak Dibutuhkan', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            content: Text('Anda telah menolak izin kontak secara permanen. Buka Pengaturan Android untuk mengaktifkan izin kontak demi keamanan komunitas.', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Batal', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  openAppSettings();
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: Text('Buka Pengaturan', style: GoogleFonts.outfit(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (await FlutterContacts.requestPermission(readonly: true)) {
        final contacts = await FlutterContacts.getContacts(
          withProperties: true,
          withPhoto: false,
        );
        setState(() {
          _contacts = contacts.where((c) => c.phones.isNotEmpty && _getContactName(c) != 'Kontak Komunitas').toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasPermission = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal membaca kontak: $e';
        _isLoading = false;
      });
    }
  }

  String _getContactName(Contact c) {
    if (c.displayName.trim().isNotEmpty) {
      return c.displayName.trim();
    }
    final fullName = '${c.name.first} ${c.name.middle} ${c.name.last}'.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (fullName.isNotEmpty) {
      return fullName;
    }
    return 'Kontak Komunitas';
  }

  Future<void> _performSync() async {
    if (_contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada kontak dengan nomor telepon untuk disinkronkan.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _lastSyncResult = null;
    });

    final payload = <Map<String, String>>[];
    for (final c in _contacts) {
      final rawNum = c.phones.first.number;
      payload.add({
        'name': _getContactName(c),
        'phoneNumber': rawNum,
      });
    }

    try {
      final res = await widget.apiService.syncContacts(
        payload,
        userId: 'android_user_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (mounted) {
        setState(() {
          _lastSyncResult = res;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message),
            backgroundColor: AppColors.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header Sleek ala GetContact
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: AppColors.primaryLight, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PhoneRep Komunitas ID',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Kontribusi Buku Alamat & Caller ID Bersama',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppColors.accentCyan,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _hasPermission ? _loadContacts : _requestPermission,
                    icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                    tooltip: 'Muat Ulang Kontak',
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading && _contacts.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status Card Hero ala GetContact
                          GlassCard(
                            padding: const EdgeInsets.all(22),
                            borderColor: _lastSyncResult != null
                                ? AppColors.accentGreen.withValues(alpha: 0.6)
                                : AppColors.primaryLight.withValues(alpha: 0.4),
                            backgroundColor: _lastSyncResult != null
                                ? AppColors.accentGreen.withValues(alpha: 0.1)
                                : AppColors.primary.withValues(alpha: 0.12),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: (_lastSyncResult != null ? AppColors.accentGreen : AppColors.primaryLight)
                                            .withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _lastSyncResult != null ? Icons.cloud_done_rounded : Icons.shield_rounded,
                                        color: _lastSyncResult != null ? AppColors.accentGreen : AppColors.primaryLight,
                                        size: 36,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: (_lastSyncResult != null ? AppColors.accentGreen : AppColors.primaryLight)
                                                  .withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              _lastSyncResult != null ? '✔ TERSINKRONISASI' : '⚡ SIAP BERKONTRIBUSI',
                                              style: GoogleFonts.outfit(
                                                color: _lastSyncResult != null ? AppColors.accentGreen : AppColors.primaryLight,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _lastSyncResult != null
                                                ? 'Buku Alamat Aktif'
                                                : '${_contacts.length} Kontak Terdeteksi',
                                            style: GoogleFonts.outfit(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Buku alamat Anda secara otomatis diubah menjadi referensi pengenalan nomor (Caller ID) bagi jutaan anggota komunitas PhoneRep untuk mengidentifikasi kurir, rekan, dan memblokir penipuan.',
                                  style: GoogleFonts.outfit(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                                if (_lastSyncResult != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentGreen.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.4)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.check_circle_rounded, color: AppColors.accentGreen, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          '+${_lastSyncResult!.syncedCount} Nomor Berhasil Diperbarui di Server',
                                          style: GoogleFonts.outfit(
                                            color: AppColors.accentGreen,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            GlassCard(
                              borderColor: AppColors.accentRed.withValues(alpha: 0.5),
                              backgroundColor: AppColors.accentRed.withValues(alpha: 0.1),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: AppColors.accentRed, size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: GoogleFonts.outfit(color: AppColors.accentRed, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),

                          // Tombol Utama One-Click Ala GetContact
                          if (!_hasPermission && _contacts.isEmpty)
                            GlassCard(
                              padding: const EdgeInsets.all(28),
                              child: Column(
                                children: [
                                  const Icon(Icons.lock_person_rounded, size: 56, color: AppColors.primaryLight),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Akses Buku Alamat Dibutuhkan',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Berikan izin untuk menghubungkan buku alamat Anda dengan sistem perlindungan anti-spam PhoneRep.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: _requestPermission,
                                    icon: const Icon(Icons.check_circle_outline, size: 20),
                                    label: const Text('BERI IZIN & AKTIFKAN PERLINDUNGAN'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (_contacts.isNotEmpty)
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.accentGreen,
                                    AppColors.accentCyan.withValues(alpha: 0.8),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accentGreen.withValues(alpha: 0.3),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _performSync,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                                      )
                                    : const Icon(Icons.sync_rounded, color: Colors.black, size: 24),
                                label: Text(
                                  _isLoading
                                      ? 'MENGHUBUNGKAN KE SERVER PhoneRep...'
                                      : 'AKTIFKAN SINKRONISASI BUKU ALAMAT (${_contacts.length} KONTAK)',
                                  style: GoogleFonts.outfit(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                ),
                              ),
                            ),

                          const SizedBox(height: 28),

                          // Fitur & Jaminan Ala GetContact
                          Text(
                            'Mengapa Sinkronisasi PhoneRep Aman?',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildFeatureCard(
                            icon: Icons.security_rounded,
                            color: AppColors.accentCyan,
                            title: 'Enkripsi & Normalisasi E.164',
                            description: 'Nomor telepon dinormalisasi ke format E.164 (+628...). Kami hanya mencatat label nama untuk identifikasi, tanpa mengoleksi data pribadi atau riwayat pesan.',
                          ),
                          const SizedBox(height: 12),
                          _buildFeatureCard(
                            icon: Icons.groups_rounded,
                            color: AppColors.primaryLight,
                            title: 'Kekuatan Crowdsourcing Komunitas',
                            description: 'Setiap nama kontak yang Anda kontribusikan membantu pengguna lain mengenali telepon penting atau memblokir penipuan secara langsung.',
                          ),
                          const SizedBox(height: 12),
                          _buildFeatureCard(
                            icon: Icons.bolt_rounded,
                            color: AppColors.accentGreen,
                            title: 'Ringan & Otomatis di Latar Belakang',
                            description: 'Sinkronisasi berlangsung cepat sekali klik tanpa membebani memori, kuota data, ataupun baterai HP Anda.',
                          ),

                          // Cuplikan Ringkas Kontak (Tanpa Checkbox yang Bikin Jelek!)
                          if (_contacts.isNotEmpty) ...[
                            const SizedBox(height: 28),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Pratinjau Buku Alamat Anda (${_contacts.length} Nomor)',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Icon(Icons.visibility_outlined, color: AppColors.textSecondary, size: 18),
                              ],
                            ),
                            const SizedBox(height: 12),
                            GlassCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _contacts.take(6).map((c) {
                                      final name = _getContactName(c);
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: AppColors.cardBgElevated,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: AppColors.border),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircleAvatar(
                                              radius: 10,
                                              backgroundColor: AppColors.primary,
                                              child: Text(
                                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                                style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              name.length > 18 ? '${name.substring(0, 16)}...' : name,
                                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  if (_contacts.length > 6) ...[
                                    const SizedBox(height: 14),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '+ ${_contacts.length - 6} kontak lainnya siap memperkaya perlindungan PhoneRep',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.outfit(color: AppColors.primaryLight, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({required IconData icon, required Color color, required String title, required String description}) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.outfit(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
