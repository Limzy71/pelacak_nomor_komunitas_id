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
  final Set<int> _selectedIndices = {};
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
            content: Text('Anda telah menolak izin kontak secara permanen. Buka Pengaturan Android untuk mengaktifkan izin kontak.', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
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
          _contacts = contacts.where((c) => c.phones.isNotEmpty && c.displayName.trim().isNotEmpty).toList();
          _selectedIndices.clear();
          for (int i = 0; i < _contacts.length; i++) {
            _selectedIndices.add(i); // default select all
          }
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

  void _loadDemoContacts() {
    // Demo contacts if real address book is empty on emulator/test device
    final demoList = [
      Contact()
        ..name.first = 'Andi'
        ..name.last = 'Kurir JNE'
        ..phones = [Phone('081234567891')],
      Contact()
        ..name.first = 'Budi'
        ..name.last = 'Santoso (Telkomsel)'
        ..phones = [Phone('+6281122334455')],
      Contact()
        ..name.first = 'Citra'
        ..name.last = 'Marketing Bank'
        ..phones = [Phone('085711223344')],
      Contact()
        ..name.first = 'Deni'
        ..name.last = 'Service Motor'
        ..phones = [Phone('081988776655')],
      Contact()
        ..name.first = 'Eka'
        ..name.last = 'HRD Perusahaan'
        ..phones = [Phone('083811223344')],
    ];

    setState(() {
      _contacts = demoList;
      _selectedIndices.clear();
      for (int i = 0; i < _contacts.length; i++) {
        _selectedIndices.add(i);
      }
      _hasPermission = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('5 Kontak Demo berhasil dimuat untuk pengujian!'),
        backgroundColor: AppColors.accentCyan,
      ),
    );
  }

  Future<void> _performSync() async {
    if (_selectedIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu kontak untuk disinkronkan.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _lastSyncResult = null;
    });

    final payload = <Map<String, String>>[];
    for (final idx in _selectedIndices) {
      final c = _contacts[idx];
      final rawNum = c.phones.first.number;
      payload.add({
        'name': c.displayName,
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
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppColors.trustSafeGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.sync_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact Pooling',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Kontribusi Buku Alamat ke Database Bersama',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppColors.accentGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading && _contacts.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_lastSyncResult != null)
                            GlassCard(
                              borderColor: AppColors.accentGreen.withValues(alpha: 0.5),
                              backgroundColor: AppColors.accentGreen.withValues(alpha: 0.12),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.cloud_done_rounded, color: AppColors.accentGreen, size: 32),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Sinkronisasi Berhasil!',
                                              style: GoogleFonts.outfit(
                                                color: AppColors.accentGreen,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              _lastSyncResult!.message,
                                              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentGreen.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '+${_lastSyncResult!.syncedCount} Kontak Terdaftar',
                                          style: GoogleFonts.outfit(
                                            color: AppColors.accentGreen,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_errorMessage != null)
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
                          // Info Card
                          GlassCard(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.privacy_tip_outlined, color: AppColors.accentCyan, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Privasi & Normalisasi E.164',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Dengan menyinkronkan kontak, Anda membantu seluruh komunitas mengenali panggilan masuk dari kurir, penipu, dan nomor penting. Nomor otomatis dinormalisasi ke format E.164 (+628...).',
                                  style: GoogleFonts.outfit(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (!_hasPermission && _contacts.isEmpty) ...[
                            const SizedBox(height: 20),
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardBgElevated,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.contacts_rounded, size: 48, color: AppColors.primaryLight),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Akses Buku Alamat Perangkat',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Izinkan aplikasi membaca daftar kontak untuk memilih nomor yang akan dibagikan ke komunitas.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: _requestPermission,
                                    icon: const Icon(Icons.check_circle_outline, size: 20),
                                    label: const Text('BERI IZIN & BACA KONTAK'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  TextButton.icon(
                                    onPressed: _loadDemoContacts,
                                    icon: const Icon(Icons.science_outlined, color: AppColors.accentCyan, size: 18),
                                    label: Text(
                                      'Gunakan 5 Kontak Demo (Pengujian Cepat)',
                                      style: GoogleFonts.outfit(color: AppColors.accentCyan, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Daftar Kontak (${_selectedIndices.length} / ${_contacts.length} Dipilih)',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    if (_contacts.isEmpty)
                                      TextButton(
                                        onPressed: _loadDemoContacts,
                                        child: Text('Muat Demo', style: GoogleFonts.outfit(color: AppColors.accentCyan)),
                                      ),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          if (_selectedIndices.length == _contacts.length) {
                                            _selectedIndices.clear();
                                          } else {
                                            for (int i = 0; i < _contacts.length; i++) {
                                              _selectedIndices.add(i);
                                            }
                                          }
                                        });
                                      },
                                      child: Text(
                                        _selectedIndices.length == _contacts.length ? 'Batal Semua' : 'Pilih Semua',
                                        style: GoogleFonts.outfit(color: AppColors.primaryLight, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_contacts.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Tidak ada kontak dengan nomor telepon ditemukan.',
                                        style: GoogleFonts.outfit(color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton(
                                        onPressed: _loadDemoContacts,
                                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.cardBgElevated),
                                        child: Text('Muat Kontak Demo', style: GoogleFonts.outfit(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _contacts.length,
                                itemBuilder: (ctx, idx) {
                                  final contact = _contacts[idx];
                                  final phone = contact.phones.first.number;
                                  final isSelected = _selectedIndices.contains(idx);

                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedIndices.remove(idx);
                                        } else {
                                          _selectedIndices.add(idx);
                                        }
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary.withValues(alpha: 0.12)
                                            : AppColors.cardBgElevated,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primaryLight
                                              : AppColors.border,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                            color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 14),
                                          CircleAvatar(
                                            backgroundColor: AppColors.cardBg,
                                            child: Text(
                                              contact.displayName.isNotEmpty
                                                  ? contact.displayName[0].toUpperCase()
                                                  : '?',
                                              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  contact.displayName,
                                                  style: GoogleFonts.outfit(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                Text(
                                                  phone,
                                                  style: GoogleFonts.outfit(
                                                    color: AppColors.textSecondary,
                                                    fontSize: 13,
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
                            const SizedBox(height: 80),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _contacts.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, -4)),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: (_isLoading || _selectedIndices.isEmpty) ? null : _performSync,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_rounded, size: 22),
                label: Text(
                  _isLoading ? 'MENGIRIM KE SERVER...' : 'SINKRONKASI ${_selectedIndices.length} KONTAK SEKARANG',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  disabledBackgroundColor: AppColors.cardBgElevated,
                ),
              ),
            )
          : null,
    );
  }
}
