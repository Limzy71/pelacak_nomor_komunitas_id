import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/phone_record.dart';
import '../theme/app_theme.dart';

class MyPhoneSearchersScreen extends StatefulWidget {
  final int searchCount;
  final double trustScore;
  final List<TagItem> myPhoneTags;
  final String myPhoneNumber;
  final VoidCallback? onRefresh;

  const MyPhoneSearchersScreen({
    super.key,
    required this.searchCount,
    required this.trustScore,
    required this.myPhoneTags,
    required this.myPhoneNumber,
    this.onRefresh,
  });

  @override
  State<MyPhoneSearchersScreen> createState() => _MyPhoneSearchersScreenState();
}

class _MyPhoneSearchersScreenState extends State<MyPhoneSearchersScreen> {
  late int _searchCount;
  late int _tagViewersCount;

  @override
  void initState() {
    super.initState();
    _searchCount = widget.searchCount;
    _tagViewersCount = _searchCount > 0 ? _searchCount + 1 : 0;
  }

  void _handleRefresh() {
    if (widget.onRefresh != null) {
      widget.onRefresh!();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Statistik pencarian telah diperbarui.',
          style: GoogleFonts.outfit(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F141F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F141F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Siapa yang Mencari Nomor Saya',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 18.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =========================================================
            // 1. BAGIAN: SIAPA YANG MENCARI NOMOR SAYA (Struktur Gambar 3)
            // =========================================================
            Text(
              'Siapa yang Mencari Nomor Saya',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchCount > 0
                  ? '$_searchCount orang telah mencari nomor Anda dalam 365 hari terakhir'
                  : 'Belum ada orang yang mencari nomor Anda dalam 365 hari terakhir',
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Kartu Daftar Nomor Pencari & Tag dari Orang Lain
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF161C2C),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF222B42)),
              ),
              child: _searchCount > 0
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pencari 1
                        _buildSearcherItem(
                          icon: Icons.person_search_rounded,
                          iconBg: AppColors.primaryLight.withValues(alpha: 0.15),
                          iconColor: AppColors.primaryLight,
                          phoneNumber: '+62 812-4491-XXXX',
                          timeAgo: 'Memeriksa nomor Anda • Terbaru',
                          externalTag: widget.myPhoneTags.isNotEmpty
                              ? widget.myPhoneTags.first.labelName
                              : 'Penelusuran Kontak',
                        ),
                        if (_searchCount > 1) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                          ),
                          // Pencari 2
                          _buildSearcherItem(
                            icon: Icons.manage_search_rounded,
                            iconBg: AppColors.accentCyan.withValues(alpha: 0.15),
                            iconColor: AppColors.accentCyan,
                            phoneNumber: '+62 878-9012-XXXX',
                            timeAgo: 'Memeriksa nomor Anda • 2 hari lalu',
                            externalTag: widget.myPhoneTags.length > 1
                                ? widget.myPhoneTags[1].labelName
                                : 'Pengecekan Rutin',
                          ),
                        ],
                        if (_searchCount > 2) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                          ),
                          Row(
                            children: [
                              Icon(Icons.more_horiz_rounded, color: AppColors.textSecondary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '+${_searchCount - 2} pencarian oleh nomor asing lainnya',
                                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.primaryLight.withValues(alpha: 0.12),
                          child: const Icon(Icons.person_search_outlined, color: AppColors.primaryLight, size: 28),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Belum Ada Nomor Pencari',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Saat ini belum ada orang atau nomor asing yang mencari nomor Anda. Jika ada nomor yang mencari Anda beserta tag yang mereka simpan, daftarnya akan langsung ditampilkan di sini.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
            ),
            const SizedBox(height: 14),

            // Tombol Biru Full Width (Struktur seperti di Gambar 3)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleRefresh,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  _searchCount > 0 ? 'Lihat Semua ($_searchCount Orang)' : 'Lihat Semua (0 Orang)',
                  style: GoogleFonts.outfit(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 36),

            // =========================================================
            // 2. BAGIAN: SIAPA YANG MELIHAT TAGAR SAYA (Struktur Gambar 3)
            // =========================================================
            Text(
              'Siapa yang Melihat Tagar Saya',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _tagViewersCount > 0
                  ? '$_tagViewersCount orang melihat tag Anda dalam 365 hari terakhir'
                  : 'Belum ada orang yang melihat tag Anda dalam 365 hari terakhir',
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Kartu Siapa yang Melihat Tagar Saya
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF161C2C),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF222B42)),
              ),
              child: _tagViewersCount > 0
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFF007AFF).withValues(alpha: 0.15),
                              child: const Icon(Icons.tag_rounded, color: Color(0xFF007AFF), size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '+62 852-1102-XXXX',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Melihat daftar tag & label nomor Anda',
                                    style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 6),
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF007AFF).withValues(alpha: 0.12),
                          child: const Icon(Icons.tag_faces_rounded, color: Color(0xFF007AFF), size: 26),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Belum Ada Penampilan Tag',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Belum ada pengguna asing yang melihat rincian tagar pada profil nomor Anda saat ini.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
            ),
            const SizedBox(height: 14),

            // Tombol Biru Bagian 2
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleRefresh,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  _tagViewersCount > 0 ? 'Lihat Semua ($_tagViewersCount Orang)' : 'Lihat Semua (0 Orang)',
                  style: GoogleFonts.outfit(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSearcherItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String phoneNumber,
    required String timeAgo,
    required String externalTag,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: iconBg,
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    phoneNumber,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeAgo,
                    style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              'Tag yang disimpan:',
              style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12.5),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2636),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2D3754)),
              ),
              child: Text(
                '# $externalTag',
                style: GoogleFonts.outfit(color: AppColors.primaryLight, fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
