import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/phone_record.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/tag_chip_card.dart';
import '../widgets/trust_meter.dart';

class SearchScreen extends StatefulWidget {
  final ApiService apiService;

  const SearchScreen({super.key, required this.apiService});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  PhoneRecord? _phoneRecord;
  String? _statusMessage;

  // Dummy recent calls ala GetContact Screenshot 1
  final List<Map<String, dynamic>> _recentCalls = [
    {
      'name': 'Brisik Kontol Ngespam Aja Lo Oranh Lagi ...',
      'sub': 'Pencarian Nomor Telepon',
      'date': 'Kemarin',
      'isSpam': true,
      'number': '+62895384292008'
    },
    {
      'name': 'Kak Azmil',
      'sub': 'Pencarian Nomor Telepon',
      'date': 'Kemarin',
      'isSpam': false,
      'number': '081224164268'
    },
    {
      'name': 'Kia Kia',
      'sub': 'Pencarian Nomor Telepon',
      'date': 'Rabu',
      'isSpam': false,
      'number': '081341095903'
    },
    {
      'name': 'Penipu Adi Nata Prayoga',
      'sub': 'Pencarian Nomor Telepon',
      'date': 'Rabu',
      'isSpam': true,
      'number': '+6285789697768'
    },
    {
      'name': 'Ingge',
      'sub': 'Pencarian Nomor Telepon',
      'date': '16 Juni',
      'isSpam': false,
      'number': '085299887766'
    },
  ];

  Future<void> _performSearch(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nomor telepon yang valid.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusMessage = null;
    });

    try {
      final res = await widget.apiService.lookupPhoneNumber(cleanQuery);
      if (mounted) {
        setState(() {
          _phoneRecord = res.data;
          _statusMessage = res.message;
          _isLoading = false;
        });
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

  Future<void> _handleVote(TagItem tag, String voteType) async {
    try {
      final success = await widget.apiService.voteTag(tag.id, voteType);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voting $voteType berhasil dicatat!'),
            backgroundColor: AppColors.primary,
          ),
        );
        if (_phoneRecord != null) {
          _performSearch(_phoneRecord!.phoneNumber);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  void _showAddTagDialog() {
    if (_phoneRecord == null) return;
    final tagController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF131824),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
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
                    child: const Icon(Icons.local_offer_rounded, color: AppColors.primaryLight),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Tambah Tag Komunitas',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Bantu komunitas mengenali nomor ini dengan memberikan label nama, penipu, atau profesi.',
                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tagController,
                style: GoogleFonts.outfit(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Contoh: Kurir Paket / Telemarketing / Penipu APK',
                  hintStyle: GoogleFonts.outfit(color: Colors.white38),
                  prefixIcon: const Icon(Icons.label, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: const Color(0xFF1F2637),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final label = tagController.text.trim();
                    if (label.isEmpty) return;
                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);
                    try {
                      final newTag = await widget.apiService.addTag(_phoneRecord!.id, label);
                      if (newTag != null && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Tag "$label" berhasil ditambahkan!'),
                            backgroundColor: AppColors.accentGreen,
                          ),
                        );
                        _performSearch(_phoneRecord!.phoneNumber);
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString().replaceAll('Exception: ', '')),
                            backgroundColor: AppColors.accentRed,
                          ),
                        );
                      }
                      setState(() => _isLoading = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'SIMPAN TAG',
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F131D),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top Bar Pencarian berdasarkan nomor ala GetContact
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
                                child: TextField(
                                  controller: _searchController,
                                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'Pencarian berdasarkan nomor',
                                    hintStyle: GoogleFonts.outfit(color: Colors.white60, fontSize: 14),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  keyboardType: TextInputType.phone,
                                  onSubmitted: _performSearch,
                                ),
                              ),
                              if (_searchController.text.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() => _phoneRecord = null);
                                  },
                                  child: const Icon(Icons.clear, color: Colors.white60, size: 18),
                                )
                              else
                                const Icon(Icons.account_circle_outlined, color: Colors.white70, size: 24),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_errorMessage!, style: GoogleFonts.outfit(color: const Color(0xFFEF4444), fontSize: 13))),
                      ],
                    ),
                  ),
                if (_statusMessage != null && _statusMessage!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_statusMessage!, style: GoogleFonts.outfit(color: const Color(0xFF10B981), fontSize: 13))),
                      ],
                    ),
                  ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF007AFF)))
                      : _phoneRecord == null
                          ? _buildHomeIdleView()
                          : _buildSearchResultView(),
                ),
              ],
            ),

            // Floating Dialpad Button ala GetContact di Beranda
            if (_phoneRecord == null)
              Positioned(
                right: 20,
                bottom: 24,
                child: FloatingActionButton(
                  onPressed: () {
                    // Fokus ke search box
                    FocusScope.of(context).requestFocus(FocusNode());
                  },
                  backgroundColor: const Color(0xFF004085),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: const Icon(Icons.apps_rounded, color: Colors.white, size: 28),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Tampilan Beranda (Idle) Persis Screenshot 1 GetContact
  Widget _buildHomeIdleView() {
    return RefreshIndicator(
      color: const Color(0xFF007AFF),
      backgroundColor: const Color(0xFF1F2637),
      onRefresh: () async {
        setState(() {});
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section: Panggilan Terbaru
            Text(
              'Panggilan Terbaru',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const SizedBox(height: 12),
            ..._recentCalls.map((item) {
              return InkWell(
                onTap: () {
                  _searchController.text = item['number'] as String;
                  _performSearch(item['number'] as String);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFF1E2636), width: 1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: (item['isSpam'] as bool) ? const Color(0xFFEF4444) : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (item['isSpam'] as bool) ...[
                                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 15),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  item['sub'] as String,
                                  style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          Text(
                            item['date'] as String,
                            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 18),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: () {},
                icon: Text(
                  'Tampilkan Semuanya',
                  style: GoogleFonts.outfit(color: const Color(0xFF2B8CFF), fontSize: 14, fontWeight: FontWeight.w600),
                ),
                label: const Icon(Icons.chevron_right_rounded, color: Color(0xFF2B8CFF), size: 18),
              ),
            ),
            const SizedBox(height: 24),

            // Section: Perlindungan dan Keamanan (Gauge Ala GetContact Screenshot 1)
            Text(
              'Perlindungan dan Keamanan',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF131824),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF1E2636)),
              ),
              child: Column(
                children: [
                  // Gauge Semi-Circle Illustration
                  SizedBox(
                    height: 130,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Curved Arch representation
                        Container(
                          width: 200,
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: const Color(0xFFEF4444), width: 14),
                              left: BorderSide(color: const Color(0xFFEF4444), width: 14),
                              right: BorderSide(color: const Color(0xFF334155), width: 14),
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(100),
                              topRight: Radius.circular(100),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          left: 45,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF131824), width: 4),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            Text(
                              'TINGKAT PERLINDUNGAN',
                              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rendah',
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Aktifkan perlindungan dari panggilan spam dan penipuan dengan menyinkronkan buku alamat.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // Tampilan Detail Nomor / Hasil Cari Persis Screenshot 3, 4, 5 GetContact
  Widget _buildSearchResultView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header nomor
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF131824),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF1E2636)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _phoneRecord!.phoneNumber,
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                    TrustMeter(score: _phoneRecord!.trustScore, searchCount: _phoneRecord!.searchCount),
                  ],
                ),
                if (_phoneRecord!.carrier != null && _phoneRecord!.carrier!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('Operator: ${_phoneRecord!.carrier}', style: GoogleFonts.outfit(color: AppColors.accentCyan, fontSize: 13)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tag Saya ala GetContact Screenshot 3
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tag Saya (${_phoneRecord!.tags.length})', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              InkWell(
                onTap: _showAddTagDialog,
                child: Text('+ Tambah Tag', style: GoogleFonts.outfit(color: const Color(0xFF2B8CFF), fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _phoneRecord!.tags.map((t) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '# ${t.labelName}',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Rekomendasi Panggil Anonim ala GetContact Screenshot 3
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF004085),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D253F),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                      const SizedBox(width: 6),
                      Text('Direkomendasikan', style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text('Lebih baik bersama', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Saat menelepon kembali nomor yang tidak dikenal, gunakan nomor virtual Anda alih-alih nomor Anda sendiri.',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Panggil Anonim', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Kontak Cepat / Daftar Tag ala GetContact Screenshot 4
          Text('Kontak Cepat', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 12),
          if (_phoneRecord!.tags.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF131824),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text('Belum ada tag untuk nomor ini.', style: GoogleFonts.outfit(color: Colors.white54)),
              ),
            )
          else
            Column(
              children: _phoneRecord!.tags.map((t) => TagChipCard(tag: t, onVote: (type) => _handleVote(t, type))).toList(),
            ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: () {},
              icon: Text(
                'Tampilkan Semua (${_phoneRecord!.tags.length} Orang)',
                style: GoogleFonts.outfit(color: const Color(0xFF2B8CFF), fontSize: 14, fontWeight: FontWeight.w600),
              ),
              label: const Icon(Icons.chevron_right_rounded, color: Color(0xFF2B8CFF), size: 18),
            ),
          ),
          const SizedBox(height: 24),

          // Banner 1 orang telah mencari nomor Anda ala GetContact Screenshot 5
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF131824),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF1E2636)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '1 orang telah mencari nomor Anda.',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      child: const Icon(Icons.person_outline_rounded, color: Colors.white54),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Anda bisa mencari tahu siapapun yang mencari nomor Anda dengan menggunakan PhoneRep Premium.',
                        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
