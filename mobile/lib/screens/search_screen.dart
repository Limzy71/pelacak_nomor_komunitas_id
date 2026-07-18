import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/phone_record.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/tag_chip_card.dart';
import '../widgets/app_toast.dart';
import '../widgets/trust_meter.dart';
import 'my_phone_searchers_screen.dart';
import 'my_tags_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final ApiService apiService;

  const SearchScreen({super.key, required this.apiService});

  @override
  State<SearchScreen> createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _isLoading = false;
  String? _errorMessage;
  PhoneRecord? _phoneRecord;
  String? _statusMessage;

  void _showAutoDismissStatus(String? status, {String? error}) {
    setState(() {
      _statusMessage = status;
      _errorMessage = error;
    });
    if (status != null || error != null) {
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted && (_statusMessage == status || _errorMessage == error)) {
          setState(() {
            if (_statusMessage == status) _statusMessage = null;
            if (_errorMessage == error) _errorMessage = null;
          });
        }
      });
    }
  }

  // Status apakah bar pencarian sedang diklik/difokuskan (untuk menampilkan mode Gambar ke-5)
  bool _isSearchExpanded = false;
  String _selectedCountryCode = '+62';
  // _callLogFilterTime dihapus

  String _getDynamicSearchHint() {
    switch (_selectedCountryCode.trim()) {
      case '+62':
        return 'Contoh: 0812... / 62812...';
      case '+60':
        return 'Contoh: 012... / 6012...';
      case '+65':
        return 'Contoh: 812... / 65812...';
      case '+1':
        return 'Contoh: 202... / 1202...';
      case '+44':
        return 'Contoh: 0712... / 44712...';
      case '+61':
        return 'Contoh: 0412... / 61412...';
      case '+81':
        return 'Contoh: 090... / 8190...';
      case '+82':
        return 'Contoh: 010... / 8210...';
      default:
        return 'Contoh awalan nomor ($_selectedCountryCode)...';
    }
  }

  String _formatQueryWithCountryCode(String raw) {
    String clean = raw.trim().replaceAll(' ', '').replaceAll('-', '');
    if (clean.isEmpty) return clean;
    if (clean.startsWith('+')) return clean;
    if (_selectedCountryCode == '+62') {
      if (clean.startsWith('08')) {
        return '+62${clean.substring(1)}';
      } else if (clean.startsWith('628')) {
        return '+$clean';
      } else if (clean.startsWith('8')) {
        return '+62$clean';
      }
    } else {
      if (clean.startsWith('0')) {
        return '$_selectedCountryCode${clean.substring(1)}';
      } else if (!clean.startsWith(_selectedCountryCode.replaceAll('+', ''))) {
        return '$_selectedCountryCode$clean';
      } else {
        return '+$clean';
      }
    }
    return clean;
  }

  // State Kontak & Call Log — DIHAPUS SEPENUHNYA (Tugas 5)
  // Konstanta false aman sebagai pengganti agar tidak ada crash di referensi lama
  final bool _hasContactPermission = false;
  final bool _isContactsLoading = false;

  // Daftar nyata riwayat "Baru Saja Dilihat" (Real dari kontak & riwayat pencarian sesi ini)
  final List<Map<String, dynamic>> _recentlyViewed = [];

  // Daftar nyata tag nomor pengguna
  final List<String> _userTags = [];

  // Statistik Real-Time Proteksi & Pencarian Nomor Pengguna Sendiri
  int _myPhoneSearchCount = 0;
  double _myPhoneTrustScore = 100.0;
  List<TagItem> _myPhoneTags = [];
  String _myPhoneNumber = '';
  bool _isMyStatsLoading = true;
  // Cache data pencari nomor agar layar buka instan. Null berarti belum pernah di-fetch.
  List<SearcherItemData>? _cachedSearcherItems;

  void refreshHomeData() {
    if (!mounted) return;
    _loadUserTagsFromPrefs();
    _fetchMyPhoneSearchStats();
    // Sinkronisasi kontak dihapus (Tugas 5) — tidak ada lagi _checkAndLoadContacts
  }

  // Cooldown sinkronisasi kontak dihapus bersama fiturnya
  // DateTime? _lastContactSyncTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserTagsFromPrefs();
    _fetchMyPhoneSearchStats();
    // Sinkronisasi kontak dihapus (Tugas 5) — tidak ada lagi _checkAndLoadContacts
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Sinkronisasi kontak & call log dihapus (Tugas 5)
      // Hanya refresh stats nomor sendiri saat app di-resume
      _fetchMyPhoneSearchStats();
    }
  }

  Future<void> _fetchMyPhoneSearchStats() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('user_my_phone') ?? '';
    if (phone.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _isMyStatsLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      if (_myPhoneTags.isEmpty && _userTags.isEmpty && _myPhoneSearchCount == 0) {
        setState(() {
          _myPhoneNumber = phone.trim();
          _isMyStatsLoading = true;
        });
      } else {
        _myPhoneNumber = phone.trim();
      }
    }

    try {
      final res = await widget.apiService.lookupPhoneNumber(_myPhoneNumber, skipIncrement: true, hasContactAccess: false);
      if (mounted && res.data != null) {
        setState(() {
          _myPhoneSearchCount = res.data!.searchCount;
          _myPhoneTrustScore = res.data!.trustScore;
          _myPhoneTags = res.data!.tags;
          for (final t in res.data!.tags) {
            if (!_userTags.contains(t.labelName)) {
              _userTags.add(t.labelName);
            }
          }
          _isMyStatsLoading = false;
        });
        _saveUserTagsToPrefs();
        // Pre-fetch data pencari di background setelah stats berhasil
        _prefetchSearchers(_myPhoneNumber);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isMyStatsLoading = false;
        });
      }
    }
  }

  Future<void> _prefetchSearchers(String phoneNumber) async {
    if (phoneNumber.trim().isEmpty) return;
    try {
      // Gunakan widget.apiService agar baseUrl konsisten (tidak membuat instance baru)
      final data = await widget.apiService.getPhoneSearchers(phoneNumber);
      if (mounted) {
        setState(() {
          _cachedSearcherItems = data;
        });
      }
    } catch (_) {}
  }

  // _fetchQuickContactsTagCounts dihapus



  Future<void> _loadUserTagsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTags = prefs.getStringList('user_my_tags') ?? [];
    if (mounted && savedTags.isNotEmpty) {
      setState(() {
        for (final t in savedTags) {
          if (!_userTags.contains(t)) {
            _userTags.add(t);
          }
        }
      });
    }
  }

  Future<void> _saveUserTagsToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('user_my_tags', _userTags);
  }

  List<TagItem> get _allMyTagsCombined {
    final list = <TagItem>[];
    final seen = <String>{};
    
    // Prioritas: _myPhoneTags dari backend (pastikan tag profil pengguna ditandai sebagai self-tag)
    for (final t in _myPhoneTags) {
      final cleanLabel = t.labelName.trim();
      if (cleanLabel.isNotEmpty && !seen.contains(cleanLabel)) {
        seen.add(cleanLabel);
        final isSelfTag = _userTags.any((ut) => ut.trim().toLowerCase() == cleanLabel.toLowerCase()) ||
            (t.userId != null && _myPhoneNumber.isNotEmpty && t.userId == _myPhoneNumber);
        list.add(TagItem(
          id: t.id,
          phoneNumberId: t.phoneNumberId,
          labelName: cleanLabel,
          userId: isSelfTag ? (_myPhoneNumber.isNotEmpty ? _myPhoneNumber : 'me') : t.userId,
          upvotes: t.upvotes,
          downvotes: t.downvotes,
          createdAt: t.createdAt,
        ));
      }
    }
    
    // Fallback: Untuk _userTags (lokal/tanpa userId)
    for (final t in _userTags) {
      final cleanLabel = t.trim();
      if (cleanLabel.isNotEmpty && !seen.contains(cleanLabel)) {
        seen.add(cleanLabel);
        list.add(TagItem(
          id: '',
          phoneNumberId: '',
          labelName: cleanLabel,
          userId: _myPhoneNumber.isNotEmpty ? _myPhoneNumber : 'me',
        ));
      }
    }
    return list;
  }

  // _showContactAccessConsentModal — DIHAPUS (Tugas 5)
  // Tidak ada lagi alur permission kontak / unlock-via-kontak.


  // _showQuotaExceededModal — DIGANTI (Tugas 5)
  // Modal baru tanpa CTA "aktifkan kontak" — hanya informasi dan tutup.
  void _showQuotaExceededModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          decoration: const BoxDecoration(
            color: Color(0xFF131A29),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, -5)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48, height: 5,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 24),
              Container(
                width: 68, height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.4), width: 1.5),
                ),
                child: const Icon(Icons.lock_clock_rounded, color: Color(0xFFFBBF24), size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                'Kuota Pencarian Harian Habis',
                style: GoogleFonts.sora(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Kuota pencarian gratis harian Anda (1x) telah habis.\nKuota akan diperbarui besok pukul 07:00 WIB.',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary, fontSize: 14, height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('Tutup', style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  // _checkAndLoadContacts, _fetchRealCallLogs, _fetchRealDeviceContacts,
  // _fetchQuickContactsTagCounts — SEMUA DIHAPUS (Tugas 5)
  // Diganti dengan stub kosong agar tidak ada referensi yang putus di referensi lama yang terlewat.


  // Stub Contact ditiadakan

  String _getInitials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '#';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Color _getAvatarColor(String seed) {
    final colors = [
      const Color(0xFF3B4358),
      const Color(0xFF6C63FF),
      const Color(0xFF10B981),
      const Color(0xFFEF4444),
      const Color(0xFF2B8CFF),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
    ];
    return colors[seed.hashCode.abs() % colors.length];
  }

  // _formatCallTime dan _fetchRecentCallTags dihapus (Tugas 5)

  // _realRecentCalls dan _realQuickContacts ditiadakan sepenuhnya (Tugas 5)
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    final cleanQuery = _formatQueryWithCountryCode(query);
    if (cleanQuery.isEmpty) {
      AppToast.show(
        context,
        message: 'Masukkan nomor telepon yang valid.',
        type: ToastType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusMessage = null;
      _isSearchExpanded =
          false; // Tutup mode daftar dilihat dan tampilkan hasil real
    });

    try {
      // Normalisasi _myPhoneNumber ke E.164 sebelum dibandingkan dengan cleanQuery
      // agar skipIncrement benar meski user login dengan format '08xxx' atau '628xxx'
      String normMyPhone = _myPhoneNumber.replaceAll(RegExp(r'[\s\-\(\)\.]+'), '');
      if (normMyPhone.startsWith('08')) {
        normMyPhone = '+62${normMyPhone.substring(1)}';
      } else if (normMyPhone.startsWith('628') && !normMyPhone.startsWith('+')) {
        normMyPhone = '+$normMyPhone';
      }
      final isSelfSearch = normMyPhone.isNotEmpty && cleanQuery == normMyPhone;

      final res = await widget.apiService.lookupPhoneNumber(
        cleanQuery,
        skipIncrement: isSelfSearch,
        hasContactAccess: false,
      );
      if (mounted) {
        setState(() {
          _phoneRecord = res.data;
          // Jangan tampilkan banner status bila data detail nomor berhasil dimuat ke layar
          if (res.data == null) {
            _showAutoDismissStatus(res.message);
          } else {
            _statusMessage = null;
            _errorMessage = null;
          }
          _isLoading = false;

          // Tambahkan ke daftar nyata "Baru Saja Dilihat" (Kecuali nomor milik pengguna sendiri)
          if (cleanQuery != _myPhoneNumber) {
            _recentlyViewed.removeWhere((item) => item['number'] == cleanQuery);
            String name = cleanQuery;
            if (res.data != null && res.data!.tags.isNotEmpty) {
              name = res.data!.tags.first.labelName;
            } else {
              name = cleanQuery;
            }
            _recentlyViewed.insert(0, {
              'name': name,
              'number': cleanQuery,
              'date': 'Baru Saja',
              'initial': _getInitials(name),
              'color': _getAvatarColor(name),
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        if (e is QuotaExceededException || e.toString().contains('Limit pencarian gratis')) {
          AppToast.show(
            context,
            message: 'Kuota pencarian gratis habis. Diperbarui besok pukul 07:00 WIB.',
            type: ToastType.info,
          );
          _showQuotaExceededModal();
          String rawErr = e.toString().toLowerCase();
          String userMsg = 'Terjadi kesalahan tidak terduga.';
          if (rawErr.contains('timeout') || rawErr.contains('socketexception') || rawErr.contains('connection refused') || rawErr.contains('future not completed')) {
            userMsg = 'Koneksi ke server lambat atau terputus. Silakan periksa jaringan internet Anda.';
          } else {
            userMsg = e.toString().replaceAll('Exception: ', '');
          }
          _showAutoDismissStatus(null, error: userMsg);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleVote(TagItem tag, String voteType) async {
    try {
      final success = await widget.apiService.voteTag(tag.id, voteType, userId: _myPhoneNumber.isNotEmpty ? _myPhoneNumber : null);
      if (success && mounted) {
        AppToast.show(
          context,
          message: 'Penilaian reputasi ($voteType) berhasil dicatat.',
          type: ToastType.success,
        );
        if (_phoneRecord != null) {
          _performSearch(_phoneRecord!.phoneNumber);
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Terjadi kesalahan saat memberikan penilaian.';
        final rawErr = e.toString().toLowerCase();
        if (rawErr.contains('timeout') || rawErr.contains('socketexception') || rawErr.contains('connection refused')) {
          errorMsg = 'Koneksi ke server terputus. Pastikan internet Anda stabil.';
        } else {
          errorMsg = e.toString().replaceAll('Exception: ', '');
        }

        AppToast.show(
          context,
          message: errorMsg,
          type: ToastType.error,
        );
      }
    }
  }

  String _getFlagForCountryCode(String code) {
    switch (code.trim()) {
      case '+62': return '🇮🇩';
      case '+60': return '🇲🇾';
      case '+65': return '🇸🇬';
      case '+1': return '🇺🇸';
      case '+44': return '🇬🇧';
      case '+61': return '🇦🇺';
      case '+81': return '🇯🇵';
      case '+82': return '🇰🇷';
      case '+86': return '🇨🇳';
      case '+91': return '🇮🇳';
      default: return '🌐';
    }
  }

  void _showCountryCodeModal() {
    final countries = [
      {'name': 'Indonesia', 'code': '+62', 'flag': '🇮🇩'},
      {'name': 'Malaysia', 'code': '+60', 'flag': '🇲🇾'},
      {'name': 'Singapura', 'code': '+65', 'flag': '🇸🇬'},
      {'name': 'Amerika Serikat', 'code': '+1', 'flag': '🇺🇸'},
      {'name': 'Inggris', 'code': '+44', 'flag': '🇬🇧'},
      {'name': 'Australia', 'code': '+61', 'flag': '🇦🇺'},
      {'name': 'Jepang', 'code': '+81', 'flag': '🇯🇵'},
      {'name': 'Korea Selatan', 'code': '+82', 'flag': '🇰🇷'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141926),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.5,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Text(
                    'Pilih Kode Negara',
                    style: GoogleFonts.sora(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 12),
                    children: countries.map((item) {
                      final isSel = _selectedCountryCode == item['code'];
                      return ListTile(
                        leading: Text(item['flag']!, style: const TextStyle(fontSize: 24)),
                        title: Text(
                          item['name']!,
                          style: GoogleFonts.sora(
                            color: Colors.white,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: Text(
                          item['code']!,
                          style: GoogleFonts.plusJakartaSans(
                            color: isSel ? const Color(0xFF007AFF) : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() => _selectedCountryCode = item['code']!);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddTagDialog() {
    final tagController = TextEditingController();
    final phoneController = TextEditingController(text: _phoneRecord?.phoneNumber ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141926),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_offer_rounded,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _phoneRecord == null ? 'Tambah Tag Saya' : 'Tambah Label Baru',
                    style: GoogleFonts.sora(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                _phoneRecord == null
                    ? 'Buat label identitas atau catatan khusus untuk nomor Anda sendiri yang tersimpan di Tag Saya.'
                    : 'Bantu pengguna lain mengenali nomor ini dengan memberikan label nama, profesi, atau kategori.',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: tagController,
                style: GoogleFonts.plusJakartaSans(color: Colors.white),
                decoration: InputDecoration(
                  hintText: _phoneRecord == null
                      ? 'Nama Tag Saya (misal: My Im3 / Bisnis Saya / Pribadi)'
                      : 'Contoh: Kurir Paket / Toko Online / Rekan Kerja',
                  hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white38),
                  prefixIcon: const Icon(
                    Icons.label_outline_rounded,
                    color: AppColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1E263D),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
                autofocus: true,
              ),
              if (_phoneRecord == null) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.plusJakartaSans(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Nomor Telepon Anda (Opsional, untuk sinkronisasi server)',
                    hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white38),
                    prefixIcon: const Icon(Icons.phone_rounded, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: const Color(0xFF1E263D),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    final label = tagController.text.trim();
                    if (label.isEmpty) return;
                    final numTarget = phoneController.text.trim();
                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);

                    try {
                      String phoneId = _phoneRecord?.id ?? '';
                      // Jika menambah dari Beranda/Tag Saya dan ada nomor telepon yang dimasukkan
                      if (phoneId.isEmpty && numTarget.isNotEmpty) {
                        final lookupRes = await widget.apiService.lookupPhoneNumber(numTarget, hasContactAccess: _hasContactPermission);
                        if (lookupRes.found && lookupRes.data != null) {
                          phoneId = lookupRes.data!.id;
                        }
                      }

                      if (phoneId.isNotEmpty) {
                        await widget.apiService.addTag(phoneId, label, userId: _myPhoneNumber);
                      }

                      if (mounted) {
                        if (!_userTags.contains(label)) {
                          setState(() => _userTags.add(label));
                          _saveUserTagsToPrefs();
                        }
                        AppToast.show(
                          context,
                          message: 'Label "#$label" berhasil ditambahkan.',
                          type: ToastType.success,
                        );
                        if (_phoneRecord != null) {
                          _performSearch(_phoneRecord!.phoneNumber);
                        } else if (numTarget.isNotEmpty) {
                          _searchController.text = numTarget;
                          _performSearch(numTarget);
                        } else {
                          setState(() => _isLoading = false);
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        String errorMsg = 'Terjadi kesalahan saat menyimpan tag.';
                        final rawErr = e.toString().toLowerCase();
                        if (rawErr.contains('timeout') || rawErr.contains('socketexception') || rawErr.contains('connection refused')) {
                          errorMsg = 'Koneksi ke server terputus. Pastikan internet Anda stabil.';
                        } else if (rawErr.contains('quota') || rawErr.contains('limit')) {
                          errorMsg = 'Limit harian Anda telah habis.';
                        }

                        AppToast.show(
                          context,
                          message: errorMsg,
                          type: ToastType.error,
                        );
                        setState(() => _isLoading = false);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('SIMPAN TAG', style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Modals call log dan kontak ditiadakan (Tugas 5)


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSearchExpanded && _phoneRecord == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Jika sedang di mode pencarian aktif → kembali ke idle
        if (_isSearchExpanded) {
          setState(() {
            _isSearchExpanded = false;
            _searchController.clear();
            _searchFocusNode.unfocus();
          });
          return;
        }
        // Jika sedang menampilkan hasil pencarian → bersihkan hasil
        if (_phoneRecord != null) {
          setState(() {
            _phoneRecord = null;
            _errorMessage = null;
            _statusMessage = null;
            _searchController.clear();
          });
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D111C),
        body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Column(
                children: [
                // Top Bar yang berubah secara dinamis antara mode biasa dan mode aktif pencarian (Gambar ke-5)
                _buildDynamicTopBar(),

                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFFEF4444),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFEF4444),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() => _errorMessage = null),
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.close_rounded,
                              color: Color(0xFFEF4444),
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_statusMessage != null && _statusMessage!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _statusMessage!,
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF10B981),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() => _statusMessage = null),
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.close_rounded,
                              color: Color(0xFF10B981),
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Konten Utama
                Expanded(
                  child: _isLoading || _isContactsLoading
                      ? Shimmer.fromColors(
                          baseColor: const Color(0xFF1E2636),
                          highlightColor: const Color(0xFF2D3754),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            physics: const NeverScrollableScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Skeleton header card
                                Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Skeleton tag chips row
                                Row(
                                  children: [
                                    Container(width: 80, height: 34, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
                                    const SizedBox(width: 8),
                                    Container(width: 110, height: 34, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
                                    const SizedBox(width: 8),
                                    Container(width: 70, height: 34, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // Skeleton section title
                                Container(width: 180, height: 18, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                                const SizedBox(height: 14),
                                // Skeleton list items
                                ...List.generate(3, (i) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: Container(
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                )),
                              ],
                            ),
                          ),
                        )
                      : _isSearchExpanded
                      ? _buildSearchExpandedView() // Tampilan saat tombol search dipencet (Gambar ke-5)
                      : _phoneRecord != null
                      ? _buildRealSearchResultView() // Tampilan hasil detail nomor
                      : _buildHomeIdle4Sections(), // Tampilan beranda murni 4 struktur nyata dari kontak
                ),
              ],
            ),
          ),

            // Floating Dialpad Button ala aplikasi referensi (muncul di Beranda saat idle)
            if (!_isSearchExpanded && _phoneRecord == null)
              Positioned(
                right: 20,
                bottom: 24,
                child: FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      _isSearchExpanded = true;
                    });
                    _searchFocusNode.requestFocus();
                  },
                  backgroundColor: const Color(0xFF004085),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.apps_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
    );
  }

  // Bar Atas Dinamis
  Widget _buildDynamicTopBar() {
    if (_isSearchExpanded) {
      // Mode Gambar ke-5: Tombol Kembali + Kapsul Kode Negara + Input
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
        color: const Color(0xFF131824),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _isSearchExpanded = false;
                  _searchFocusNode.unfocus();
                });
              },
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: _showCountryCodeModal,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2637),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2E384D), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getFlagForCountryCode(_selectedCountryCode),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _selectedCountryCode,
                      style: GoogleFonts.sora(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 1),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white60,
                      size: 13,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2637),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF2E384D)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: _getDynamicSearchHint(),
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        keyboardType: TextInputType.phone,
                        onSubmitted: _performSearch,
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () => _searchController.clear(),
                        child: const Icon(
                          Icons.clear,
                          color: Colors.white60,
                          size: 18,
                        ),
                      ),

                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else if (_phoneRecord != null) {
      // Mode Hasil Pencarian Detail: Tombol Kembali + Kapsul Info Nomor/Tutup
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
        color: const Color(0xFF131824),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _phoneRecord = null;
                  _statusMessage = null;
                  _errorMessage = null;
                  _searchController.clear();
                });
              },
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isSearchExpanded = true;
                  });
                  _searchFocusNode.requestFocus();
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2133),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF2A3450), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        color: Colors.white60,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _phoneRecord!.phoneNumber,
                          style: GoogleFonts.sora(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _phoneRecord = null;
                            _statusMessage = null;
                            _errorMessage = null;
                            _searchController.clear();
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.white60,
                            size: 20,
                          ),
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
    } else {
      // Mode Kapsul Normal (Beranda) dengan Contoh Negara Dinamis
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        color: Colors.transparent, // Menyatu dengan warna background utama
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2133),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF2A3450), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              InkWell(
                onTap: _showCountryCodeModal,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF28324A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_getFlagForCountryCode(_selectedCountryCode), style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 3),
                      Text(
                        _selectedCountryCode,
                        style: GoogleFonts.sora(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 1),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white60,
                        size: 13,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isSearchExpanded = true;
                    });
                    _searchFocusNode.requestFocus();
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        color: Colors.white60,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getDynamicSearchHint(),
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Ikon Contact Book dihilangkan (Tugas 5)
            ],
          ),
        ),
      );
    }
  }

  // =========================================================================
  // 4 STRUKTUR MURNI BERANDA (100% REAL DATA DARI KONTAK PERANGKAT)
  // =========================================================================
  Widget _buildHomeIdle4Sections() {
    return RefreshIndicator(
      color: AppColors.primaryLight,
      backgroundColor: const Color(0xFF1F2637),
      onRefresh: () async {}, // stub karena kontak sudah dihapus
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

          // 1. TAMPILAN PANGGILAN TERBARU (CALL LOG) DIHILANGKAN

            // -------------------------------------------------------------
            // 2. TAMPILAN TAG PENGGUNA / TAG SAYA (Struktur Gambar 2 & 3)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tag Saya',
                  style: GoogleFonts.sora(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                if (_allMyTagsCombined.isNotEmpty)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MyTagsDetailScreen(
                              allTags: _allMyTagsCombined,
                              apiService: widget.apiService,
                              myPhoneNumber: _myPhoneNumber,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2636),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2D3754)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Detail',
                              style: GoogleFonts.sora(
                                color: AppColors.primaryLight,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_rounded, color: AppColors.primaryLight, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_allMyTagsCombined.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Belum ada tag/label khusus untuk nomor Anda.',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ..._allMyTagsCombined.take(5).map(
                  (t) => Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MyTagsDetailScreen(
                              allTags: _allMyTagsCombined,
                              apiService: widget.apiService,
                              myPhoneNumber: _myPhoneNumber,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF007AFF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '# ${t.labelName}',
                              style: GoogleFonts.sora(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // 3. TAMPILAN KONTAK CEPAT DIHILANGKAN
            const SizedBox(height: 28),

            // -------------------------------------------------------------
            // 4. MEMUNCULKAN DAFTAR ORANG YANG MENCARI NOMOR PENGGUNA (Gambar 4 & 5)
            // -------------------------------------------------------------
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MyPhoneSearchersScreen(
                        searchCount: _myPhoneSearchCount,
                        trustScore: _myPhoneTrustScore,
                        myPhoneTags: _myPhoneTags,
                        myPhoneNumber: _myPhoneNumber,
                        searcherItems: _cachedSearcherItems,
                        apiService: widget.apiService,
                        onRefresh: _fetchMyPhoneSearchStats,
                        onSearchNumber: (String number) {
                          Navigator.pop(context); // Tutup halaman MyPhoneSearchersScreen
                          _searchController.text = number;
                          _performSearch(number); // Lakukan pencarian
                        },
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141926),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF20273C)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
                                  ),
                                  child: const Icon(
                                    Icons.person_search_rounded,
                                    color: AppColors.primaryLight,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Aktivitas Pencarian Nomor Anda',
                                    style: GoogleFonts.sora(
                                      color: AppColors.primaryLight,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E2636),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF2D3754)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Detail',
                                  style: GoogleFonts.sora(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (_isMyStatsLoading)
                        Text(
                          'Memeriksa aktivitas pencarian...',
                          style: GoogleFonts.sora(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else if (_myPhoneSearchCount > 0)
                        Text(
                          '${_myPhoneSearchCount}x Diperiksa Orang Lain',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      else
                        Text(
                          'Belum tercatat aktivitas pemeriksaan atau penelusuran pada profil nomor Anda.',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textSecondary,
                            fontSize: 13.5,
                            height: 1.45,
                          ),
                        ),

                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // =======================================
  // TAMPILAN SAAT TOMBOL SEARCH DIPENCET
  // =======================================
  Widget _buildSearchExpandedView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Baru Saja Dilihat',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              if (_recentlyViewed.isNotEmpty)
                InkWell(
                  onTap: () {
                    setState(() {
                      _recentlyViewed.clear();
                    });
                  },
                  child: Text(
                    'Hapus',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF2B8CFF),
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_recentlyViewed.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Belum Ada Nomor Dilihat',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.sora(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Riwayat nomor telepon yang baru saja Anda periksa akan muncul di sini.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: _recentlyViewed.map((item) {
                return InkWell(
                  onTap: () {
                    _searchController.text = item['number'] as String;
                    _performSearch(item['number'] as String);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFF1E2636), width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: item['color'] as Color,
                          child: Text(
                            item['initial'] as String,
                            style: GoogleFonts.sora(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'] as String,
                                style: GoogleFonts.sora(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['number'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          item['date'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white54,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // Tampilan Hasil Pencarian Detail Nomor Asli
  Widget _buildRealSearchResultView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF141926),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF20273C)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _phoneRecord!.phoneNumber,
                  style: GoogleFonts.sora(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                TrustMeter(
                  score: _phoneRecord!.trustScore,
                  searchCount: _phoneRecord!.searchCount,
                ),
                if (_phoneRecord!.carrier != null &&
                    _phoneRecord!.carrier!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        (_phoneRecord!.carrier!.contains('PSTN') ||
                                _phoneRecord!.carrier!.contains('Fixed Line') ||
                                _phoneRecord!.carrier!.contains('Telkom Indonesia'))
                            ? Icons.phone_rounded
                            : Icons.cell_tower_rounded,
                        color: AppColors.accentCyan,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Operator: ${_phoneRecord!.carrier}',
                          style: GoogleFonts.sora(
                            color: AppColors.accentCyan,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tag & Label (${_phoneRecord!.tags.length})',
                style: GoogleFonts.sora(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              InkWell(
                onTap: _showAddTagDialog,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryLight),
                  ),
                  child: Text(
                    '+ Tambah Tag',
                    style: GoogleFonts.sora(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_phoneRecord!.tags.isEmpty)
            Text(
              'Belum ada label tag untuk nomor ini. Tekan tombol "+ Tambah Tag" untuk memberi label.',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _phoneRecord!.tags.map((t) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: t.isSpam
                        ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                        : const Color(0xFF1E263D),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: t.isSpam
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF2C3756),
                    ),
                  ),
                  child: Text(
                    '# ${t.labelName}',
                    style: GoogleFonts.plusJakartaSans(
                      color: t.isSpam ? const Color(0xFFEF4444) : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 28),

          Text(
            'Daftar Ulasan & Reputasi',
            style: GoogleFonts.sora(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          if (_phoneRecord!.tags.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF141926),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF20273C)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.label_off_rounded,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Belum Ada Ulasan Tag',
                    style: GoogleFonts.sora(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Jadilah yang pertama memberikan label apakah nomor ini kurir, penipu, atau rekan bisnis.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: _showAddTagDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      'Beri Tag Sekarang',
                      style: GoogleFonts.sora(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: _phoneRecord!.tags
                  .map(
                    (t) => TagChipCard(
                      tag: t,
                      onVote: (type) => _handleVote(t, type),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
