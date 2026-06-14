import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'dart:convert';
import '../utils/download_helper.dart';
import '../const/app_colors.dart';
import '../providers/app_providers.dart';

class QrGeneratorScreen extends ConsumerStatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  ConsumerState<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends ConsumerState<QrGeneratorScreen> {
  final GlobalKey _qrKey = GlobalKey();
  bool _isDownloading = false;

  Future<void> _downloadQRCode() async {
    setState(() => _isDownloading = true);
    try {
      final boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();
      await saveImage(
          pngBytes, 'bingo_card_${DateTime.now().millisecondsSinceEpoch}.png');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.neonGreen),
                SizedBox(width: 8),
                Text('QR saved!', style: TextStyle(color: Colors.white)),
              ],
            ),
            backgroundColor: const Color(0xFF050F05),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: const BorderSide(color: AppColors.neonGreen, width: 1),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: AppColors.error),
                const SizedBox(width: 8),
                Expanded(
                    child: Text('Error: ${e.toString()}',
                        style: const TextStyle(color: Colors.white))),
              ],
            ),
            backgroundColor: const Color(0xFF0F0505),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
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
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _ScanlinePainter())),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('NO PLAYER', style: GoogleFonts.pressStart2p(
                    color: AppColors.neonPink, fontSize: 14,
                    shadows: [const Shadow(color: AppColors.neonPink, blurRadius: 20)],
                  )),
                  const SizedBox(height: 8),
                  Text('PROFILE NOT SET', style: GoogleFonts.pressStart2p(
                    color: Colors.white38, fontSize: 7)),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: () => context.go('/profile'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.neonPink, width: 2),
                        borderRadius: BorderRadius.circular(6),
                        color: AppColors.neonPink.withValues(alpha: 0.1),
                        boxShadow: [BoxShadow(color: AppColors.neonPink.withValues(alpha: 0.3), blurRadius: 16)],
                      ),
                      child: Text('[ SET UP PROFILE ]',
                          style: GoogleFonts.pressStart2p(color: AppColors.neonPink, fontSize: 8)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final qrDataObject = {
      'app':               'namma_bingo_app',
      'signature':         'BINGO_USER_V1',
      'type':              'bingo_user',
      'id':                currentUser.id,
      'name':              currentUser.name,
      'linkedinUrl':       currentUser.linkedinUrl,
      'profilePictureUrl': currentUser.profilePictureUrl,
    };
    final qrData = base64Encode(utf8.encode(jsonEncode(qrDataObject)));
    final connCount = currentUser.scannedBoxes.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _ScanlinePainter())),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                children: [
                  // ── Screen title ──────────────────────────────────────
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PLAYER ID', style: GoogleFonts.pressStart2p(
                            color: AppColors.neonPink,
                            fontSize: 13,
                            shadows: [Shadow(color: AppColors.neonPink.withValues(alpha: 0.8), blurRadius: 14)],
                          )),
                          const SizedBox(height: 3),
                          Text('your arcade card', style: TextStyle(
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
                          border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.6), width: 1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$connCount CONN.',
                          style: GoogleFonts.pressStart2p(
                            color: AppColors.neonGreen, fontSize: 8),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Arcade player card ────────────────────────────────
                  RepaintBoundary(
                    key: _qrKey,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF07071C),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.neonPink, width: 2),
                        boxShadow: [
                          BoxShadow(color: AppColors.neonPink.withValues(alpha: 0.35), blurRadius: 24, spreadRadius: 2),
                          BoxShadow(color: AppColors.neonPurple.withValues(alpha: 0.12), blurRadius: 48),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Card header bar
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.neonPink.withValues(alpha: 0.2),
                                  AppColors.neonPurple.withValues(alpha: 0.15),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.neonPink.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.neonPink.withValues(alpha: 0.6), width: 1),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text('NAMMA BINGO',
                                      style: GoogleFonts.pressStart2p(
                                        color: AppColors.neonPink, fontSize: 6)),
                                ),
                                const Spacer(),
                                Text('PLAYER CARD',
                                    style: GoogleFonts.pressStart2p(
                                      color: Colors.white.withValues(alpha: 0.4),
                                      fontSize: 6,
                                    )),
                              ],
                            ),
                          ),

                          // Avatar + name
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                            child: Row(
                              children: [
                                // Avatar
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.neonPink, width: 2.5),
                                    boxShadow: [
                                      BoxShadow(color: AppColors.neonPink.withValues(alpha: 0.4), blurRadius: 12),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: _isValidUrl(currentUser.profilePictureUrl)
                                        ? Image.network(
                                            currentUser.profilePictureUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                _buildInitial(currentUser.name),
                                          )
                                        : _buildInitial(currentUser.name),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        currentUser.name.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      _StatRow('CONNECTIONS', '$connCount / 25'),
                                      const SizedBox(height: 3),
                                      _StatRow('STATUS', connCount >= 25 ? 'BINGO MASTER' : 'ACTIVE'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Divider with corner decorations
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Container(width: 6, height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.neonPink.withValues(alpha: 0.5))),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: AppColors.neonPink.withValues(alpha: 0.2),
                                  ),
                                ),
                                Container(width: 6, height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.neonPink.withValues(alpha: 0.5))),
                              ],
                            ),
                          ),

                          // QR code area
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(color: AppColors.neonPink.withValues(alpha: 0.2), blurRadius: 16),
                                ],
                              ),
                              child: LayoutBuilder(
                                builder: (ctx, constraints) => QrImageView(
                                  data: qrData,
                                  version: QrVersions.auto,
                                  size: constraints.maxWidth,
                                  errorCorrectionLevel: QrErrorCorrectLevel.L,
                                  eyeStyle: const QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: Color(0xFF07071C),
                                  ),
                                  dataModuleStyle: const QrDataModuleStyle(
                                    dataModuleShape: QrDataModuleShape.square,
                                    color: Color(0xFF07071C),
                                  ),
                                  gapless: false,
                                ),
                              ),
                            ),
                          ),

                          // Scan instruction
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              '[ SHOW THIS TO CONNECT ]',
                              style: GoogleFonts.pressStart2p(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 6,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Action buttons ────────────────────────────────────
                  Row(
                    children: [
                      // Edit profile button
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.go('/profile'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.neonPink.withValues(alpha: 0.15),
                                  AppColors.neonPurple.withValues(alpha: 0.15),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.neonPink, width: 1.5),
                              boxShadow: [BoxShadow(color: AppColors.neonPink.withValues(alpha: 0.2), blurRadius: 10)],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.edit, color: AppColors.neonPink, size: 15),
                                const SizedBox(width: 6),
                                Text('EDIT', style: GoogleFonts.pressStart2p(
                                  color: AppColors.neonPink, fontSize: 9)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Save QR button
                      Expanded(
                        child: GestureDetector(
                          onTap: _isDownloading ? null : _downloadQRCode,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.neonBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _isDownloading
                                    ? AppColors.neonBlue.withValues(alpha: 0.3)
                                    : AppColors.neonBlue,
                                width: 1.5,
                              ),
                              boxShadow: [BoxShadow(color: AppColors.neonBlue.withValues(alpha: 0.2), blurRadius: 10)],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isDownloading)
                                  const SizedBox(
                                    width: 14, height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2, color: AppColors.neonBlue),
                                  )
                                else
                                  const Icon(Icons.download, color: AppColors.neonBlue, size: 15),
                                const SizedBox(width: 6),
                                Text(
                                  _isDownloading ? 'SAVING' : 'SAVE',
                                  style: GoogleFonts.pressStart2p(
                                    color: _isDownloading
                                        ? AppColors.neonBlue.withValues(alpha: 0.4)
                                        : AppColors.neonBlue,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitial(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      color: AppColors.neonPink.withValues(alpha: 0.15),
      child: Center(
        child: Text(initial,
            style: const TextStyle(
              color: AppColors.neonPink,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            )),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label:', style: TextStyle(
          color: Colors.white.withValues(alpha: 0.35),
          fontSize: 9,
          letterSpacing: 0.5,
          fontWeight: FontWeight.w600,
        )),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(
          color: AppColors.neonGreen,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        )),
      ],
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.012)
      ..style = PaintingStyle.fill;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1.5), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
