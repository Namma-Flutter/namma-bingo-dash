import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_providers.dart';
import '../const/app_colors.dart';

class ConnectionsScreen extends ConsumerWidget {
  const ConnectionsScreen({super.key});

  Future<void> _launchLinkedIn(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0)    return '${diff.inDays}d ago';
    if (diff.inHours > 0)   return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'now';
  }

  bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bingoBoxes  = ref.watch(bingoBoxesProvider);
    final currentUser = ref.watch(currentUserProvider);
    final total       = ref.watch(bingoBoxesProvider.notifier).questionsCount;
    final isBingoDone = total > 0 && (currentUser?.scannedBoxes.length ?? 0) >= total;

    final connections = bingoBoxes
        .where((b) =>
            currentUser?.scannedBoxes.contains(b.id) == true &&
            b.scannedByName != null)
        .toList();

    final pct = total > 0 ? (connections.length / total * 100).toInt() : 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _ScanlinePainter())),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('HIGH SCORES', style: GoogleFonts.pressStart2p(
                            color: AppColors.neonPink,
                            fontSize: 12,
                            shadows: [Shadow(color: AppColors.neonPink.withValues(alpha: 0.8), blurRadius: 14)],
                          )),
                          const SizedBox(height: 3),
                          Text('player connections', style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 11,
                            letterSpacing: 0.5,
                          )),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.neonPink, width: 1.5),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [BoxShadow(color: AppColors.neonPink.withValues(alpha: 0.3), blurRadius: 10)],
                        ),
                        child: Text(
                          '${connections.length}/$total',
                          style: GoogleFonts.pressStart2p(
                            color: AppColors.neonPink, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── BINGO complete banner ────────────────────────────────
                if (isBingoDone)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.neonYellow, width: 1.5),
                        borderRadius: BorderRadius.circular(6),
                        color: AppColors.neonYellow.withValues(alpha: 0.06),
                        boxShadow: [BoxShadow(color: AppColors.neonYellow.withValues(alpha: 0.2), blurRadius: 16)],
                      ),
                      child: Row(
                        children: [
                          const Text('🏆', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('BINGO MASTER!', style: GoogleFonts.pressStart2p(
                                color: AppColors.neonYellow, fontSize: 9)),
                              const SizedBox(height: 3),
                              const Text('Full roster unlocked!',
                                  style: TextStyle(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Progress bar ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('PROGRESS', style: GoogleFonts.pressStart2p(
                            color: Colors.white.withValues(alpha: 0.3), fontSize: 7)),
                          Text('$pct%', style: const TextStyle(
                            color: AppColors.neonGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          )),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: total > 0 ? connections.length / total : 0,
                          backgroundColor: Colors.white.withValues(alpha: 0.07),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.neonGreen),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── List ─────────────────────────────────────────────────
                Expanded(
                  child: connections.isEmpty
                      ? _buildEmpty()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: connections.length,
                          itemBuilder: (context, i) {
                            final c = connections[i];
                            return _PlayerCard(
                              rank:           i + 1,
                              name:           c.scannedByName ?? 'Unknown',
                              profilePicture: c.scannedByProfilePicture,
                              linkedIn:       c.scannedByLinkedIn,
                              scannedAt:      c.scannedAt,
                              isValidUrl:     _isValidUrl,
                              formatDate:     _formatDate,
                              onLinkedIn: (c.scannedByLinkedIn?.isNotEmpty == true)
                                  ? () => _launchLinkedIn(c.scannedByLinkedIn!)
                                  : null,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('[ NO PLAYERS ]', style: GoogleFonts.pressStart2p(
            color: AppColors.neonPink, fontSize: 11,
            shadows: [const Shadow(color: AppColors.neonPink, blurRadius: 16)],
          )),
          const SizedBox(height: 12),
          Text(
            'Scan QR codes to add\nplayers to your roster',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 13, height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Player card ────────────────────────────────────────────────────────────────

class _PlayerCard extends StatelessWidget {
  final int rank;
  final String name;
  final String? profilePicture;
  final String? linkedIn;
  final DateTime? scannedAt;
  final bool Function(String?) isValidUrl;
  final String Function(DateTime) formatDate;
  final VoidCallback? onLinkedIn;

  const _PlayerCard({
    required this.rank,
    required this.name,
    required this.profilePicture,
    required this.linkedIn,
    required this.scannedAt,
    required this.isValidUrl,
    required this.formatDate,
    required this.onLinkedIn,
  });

  static const _accentColors = [
    AppColors.neonYellow,  // 1st
    Color(0xFFD0D0D0),     // 2nd silver
    Color(0xFFCD7F32),     // 3rd bronze
    AppColors.neonPink,
    AppColors.neonBlue,
    AppColors.neonGreen,
    AppColors.neonPurple,
  ];

  Color get _accent => _accentColors[(rank - 1).clamp(0, _accentColors.length - 1)];

  @override
  Widget build(BuildContext context) {
    final accent  = _accent;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final rankStr = rank.toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: accent, width: 3),
          top: BorderSide(color: accent.withValues(alpha: 0.1), width: 1),
          right: BorderSide(color: accent.withValues(alpha: 0.1), width: 1),
          bottom: BorderSide(color: accent.withValues(alpha: 0.1), width: 1),
        ),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: Row(
          children: [
            // Rank number
            SizedBox(
              width: 30,
              child: Text(
                rankStr,
                style: GoogleFonts.pressStart2p(
                  color: accent.withValues(alpha: 0.7),
                  fontSize: 9,
                ),
              ),
            ),
            // Avatar circle
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: 0.6), width: 1.5),
                color: accent.withValues(alpha: 0.1),
              ),
              child: ClipOval(
                child: isValidUrl(profilePicture)
                    ? Image.network(
                        profilePicture!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _initial(initial, accent),
                      )
                    : _initial(initial, accent),
              ),
            ),
            const SizedBox(width: 10),
            // Name + time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (scannedAt != null)
                    Text(formatDate(scannedAt!),
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.28), fontSize: 10)),
                ],
              ),
            ),
            // Connect button
            if (onLinkedIn != null)
              GestureDetector(
                onTap: onLinkedIn,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: accent, width: 1),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.25), blurRadius: 8)],
                  ),
                  child: Text('IN', style: GoogleFonts.pressStart2p(
                    color: accent, fontSize: 8)),
                ),
              )
            else
              Text('NO LINK', style: TextStyle(
                color: Colors.white.withValues(alpha: 0.15),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              )),
          ],
        ),
      ),
    );
  }

  Widget _initial(String letter, Color color) => Container(
        color: color.withValues(alpha: 0.12),
        child: Center(
          child: Text(letter,
              style: TextStyle(
                  color: color, fontSize: 17, fontWeight: FontWeight.w900)),
        ),
      );
}

// ── Background painter ─────────────────────────────────────────────────────────

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.013)
      ..style = PaintingStyle.fill;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1.5), p);
    }
    final dot = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.022)
      ..style = PaintingStyle.fill;
    for (double x = 0; x < size.width; x += 40) {
      for (double y = 0; y < size.height; y += 40) {
        canvas.drawCircle(Offset(x, y), 1.0, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
