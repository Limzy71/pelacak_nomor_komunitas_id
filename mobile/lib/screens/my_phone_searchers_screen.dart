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

  @override
  void initState() {
    super.initState();
    _searchCount = widget.searchCount;
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
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Siapa yang Mencari Nomor Saya',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 17.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
            onPressed: _handleRefresh,
            tooltip: 'Perbarui Data',
          ),
        ],
      ),
      body: _buildSearchersList(),
    );
  }

  // ignore: unused_element
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF161C2C),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF222B42), width: 1.5),
              ),
              child: const Icon(
                Icons.person_search_outlined,
                color: Color(0xFF007AFF),
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum Ada Riwayat Pemeriksaan',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Belum ada orang atau nomor asing yang mencari nomor Anda.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 14.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchersList() {
    // TODO(USER-REVIEW): Flag sementara (hardcode preview) agar USER bisa me-review desain card daftar pencari nomor.
    // Jika sudah pas & disetujui, ubah isPreviewingHardcode menjadi false untuk menggunakan data dinamis database.
    const bool isPreviewingHardcode = true;
    // ignore: dead_code
    final int displayCount = isPreviewingHardcode ? 3 : _searchCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ignore: dead_code
          if (displayCount == 0 && !isPreviewingHardcode) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF161C2C),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF222B42)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFF007AFF), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Belum ada orang yang mencari atau memeriksa profil nomor Anda.',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 38),
              decoration: BoxDecoration(
                color: const Color(0xFF161C2C),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF222B42)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_search_outlined,
                      size: 44,
                      color: AppColors.primaryLight.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Belum Ada Aktivitas Pencarian',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Saat ini belum ada pengguna atau nomor asing yang mencari profil nomor Anda.\n\nJika nanti ada nomor yang memeriksa atau menyimpan tag untuk Anda, aktivitasnya akan langsung muncul di sini.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: AppColors.textSecondary,
                      fontSize: 13.5,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF161C2C),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF222B42)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFF007AFF), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ditemukan $displayCount orang yang telah mencari atau memeriksa profil nomor Anda.',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSearcherItem(
              initials: 'SM',
              avatarColor: AppColors.primaryLight,
              profileName: 'Siska Marketing',
              phoneNumber: '+62 812-****-7890',
              timeAgo: 'Memeriksa nomor Anda • 2 jam yang lalu',
              communityTags: const ['#Rekan Kerja', '#Sales Corporate', '#Marketing Office'],
            ),
            const SizedBox(height: 14),
            _buildSearcherItem(
              initials: 'BS',
              avatarColor: AppColors.accentCyan,
              profileName: 'Budi Santoso (Kurir JNE)',
              phoneNumber: '+62 878-****-3312',
              timeAgo: 'Memeriksa nomor Anda • Kemarin, 14:20 WIB',
              communityTags: const ['#Kurir Paket', '#JNE Express', '#Antar Barang'],
            ),
            const SizedBox(height: 14),
            _buildSearcherItem(
              initials: 'AP',
              avatarColor: const Color(0xFF34D399),
              profileName: 'Aditya Pratama',
              phoneNumber: '+62 856-****-9011',
              timeAgo: 'Memeriksa nomor Anda • 3 hari yang lalu',
              communityTags: const ['#Mitra Bisnis', '#Klien Surabaya'],
            ),
            const SizedBox(height: 16),
            Text(
              '* Demi menjaga privasi pengguna, digit tengah nomor pencari disembunyikan.',
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSearcherItem({
    required String initials,
    required Color avatarColor,
    required String profileName,
    required String phoneNumber,
    required String timeAgo,
    required List<String> communityTags,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF161C2C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF222B42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: avatarColor.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: avatarColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  initials,
                  style: GoogleFonts.outfit(
                    color: avatarColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            profileName,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: avatarColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Pencari',
                            style: GoogleFonts.outfit(
                              color: avatarColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone_android_rounded, size: 14, color: avatarColor),
                        const SizedBox(width: 6),
                        Text(
                          phoneNumber,
                          style: GoogleFonts.outfit(
                            color: avatarColor,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeAgo,
                      style: GoogleFonts.outfit(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
          const SizedBox(height: 12),
          Text(
            'Tag yang disimpan oleh orang lain:',
            style: GoogleFonts.outfit(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: communityTags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2636),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2D3754)),
                ),
                child: Text(
                  tag,
                  style: GoogleFonts.outfit(
                    color: AppColors.primaryLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
