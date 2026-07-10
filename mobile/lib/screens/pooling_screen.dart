import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/phone_record.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

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

  // Toggle states ala GetContact
  bool _isDefaultPhoneApp = true;
  bool _isOverlayAllowed = true;

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
      backgroundColor: const Color(0xFF0F131D),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar Pencarian ala GetContact
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: const Color(0xFF131824),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2637),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: Colors.white60, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Pencarian berdasarkan nomor',
                              style: GoogleFonts.outfit(color: Colors.white60, fontSize: 14),
                            ),
                          ),
                          const Icon(Icons.account_circle_outlined, color: Colors.white70, size: 24),
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
                      subtitle: 'Atur PhoneRep sebagai aplikasi telepon default sehingga PhoneRep dapat mengidentifikasi panggilan masuk untuk melindungi Anda dari panggilan spam.',
                      value: _isDefaultPhoneApp,
                      onChanged: (v) => setState(() => _isDefaultPhoneApp = v),
                    ),
                    const SizedBox(height: 14),

                    // Kartu 2: Izinkan untuk ditampilkan pada layar
                    _buildBlueToggleCard(
                      title: 'Izinkan untuk ditampilkan pada layar',
                      subtitle: 'Saat nomor tidak dikenal menelepon, kartu ID penelepon akan muncul di layar Anda secara otomatis.',
                      value: _isOverlayAllowed,
                      onChanged: (v) => setState(() => _isOverlayAllowed = v),
                    ),
                    const SizedBox(height: 24),

                    // ID Penelepon untuk Panggilan Internet ala GetContact
                    Text(
                      'ID Penelepon untuk Panggilan Internet',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF0096C7),
                            Color(0xFF10B981),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_rounded, color: Colors.white, size: 34),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Budi Suhardi',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '+62-898-555-775',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Panggilan...',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0088CC),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF25D366),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.call_rounded, color: Colors.white, size: 18),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Lihat ID penelepon untuk “panggilan tak dikenal” panggilan internet WhatsApp dan Telegram.',
                      style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 28),

                    // Bagian Contact Pooling Sekali Klik Ala GetContact
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF182030),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _lastSyncResult != null
                              ? AppColors.accentGreen.withValues(alpha: 0.6)
                              : AppColors.primaryLight.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: (_lastSyncResult != null ? AppColors.accentGreen : AppColors.primaryLight)
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  _lastSyncResult != null ? Icons.cloud_done_rounded : Icons.sync_rounded,
                                  color: _lastSyncResult != null ? AppColors.accentGreen : AppColors.primaryLight,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Kontribusi Buku Alamat (Pooling)',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _lastSyncResult != null
                                          ? '✔ Tersinkronisasi (+${_lastSyncResult!.syncedCount} nomor)'
                                          : '${_contacts.length} Nomor siap memperkaya proteksi',
                                      style: GoogleFonts.outfit(
                                        color: _lastSyncResult != null ? AppColors.accentGreen : AppColors.accentCyan,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: _hasPermission ? _loadContacts : _requestPermission,
                                icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Dengan menyinkronkan buku alamat secara otomatis, Anda membantu seluruh pengguna mengenali nomor kurir, penipu, dan nomor penting tanpa menampilkan riwayat pribadi.',
                            style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(_errorMessage!, style: GoogleFonts.outfit(color: AppColors.accentRed, fontSize: 12)),
                          ],
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : (_contacts.isEmpty ? _requestPermission : _performSync),
                              icon: _isLoading
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.cloud_upload_rounded, size: 20),
                              label: Text(
                                _isLoading
                                    ? 'MENGHUBUNGKAN KE SERVER...'
                                    : (_contacts.isEmpty
                                        ? 'BERI IZIN BUKU ALAMAT SEKARANG'
                                        : 'SINKRONISASI ${_contacts.length} KONTAK SEKARANG'),
                                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _lastSyncResult != null ? AppColors.accentGreen : const Color(0xFF007AFF),
                                foregroundColor: _lastSyncResult != null ? Colors.black : Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
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
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
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
