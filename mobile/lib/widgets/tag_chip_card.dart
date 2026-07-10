import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/phone_record.dart';

class TagChipCard extends StatelessWidget {
  final TagItem tag;
  final Function(String voteType) onVote;

  const TagChipCard({
    super.key,
    required this.tag,
    required this.onVote,
  });

  Color _getAvatarColor(String text) {
    final colors = [
      const Color(0xFFE91E63), // Pink
      const Color(0xFF009688), // Teal
      const Color(0xFFE65100), // Orange
      const Color(0xFF673AB7), // Purple
      const Color(0xFF1E88E5), // Blue
      const Color(0xFF43A047), // Green
    ];
    if (text.isEmpty) return colors[0];
    return colors[text.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final avatarText = tag.labelName.trim().isNotEmpty
        ? (tag.labelName.length >= 2 ? tag.labelName.substring(0, 2).toUpperCase() : tag.labelName[0].toUpperCase())
        : '#';
    final badgeNumber = tag.upvotes > 0 ? tag.upvotes : 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1E2636), width: 1)),
      ),
      child: Row(
        children: [
          // Circle Avatar ala GetContact Kontak Cepat
          CircleAvatar(
            radius: 22,
            backgroundColor: _getAvatarColor(avatarText),
            child: Text(
              avatarText,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Nama Tag / Label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        tag.labelName,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (tag.isSpam) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'SPAM',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFEF4444),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  tag.phoneNumberId.isNotEmpty ? tag.phoneNumberId : 'Diverifikasi oleh Komunitas',
                  style: GoogleFonts.outfit(
                    color: Colors.white54,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Badge Biru ikonik GetContact [ # 200 ]
          InkWell(
            onTap: () => onVote('UPVOTE'),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0B4F9C), // Biru khas badge GetContact
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '# $badgeNumber',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
