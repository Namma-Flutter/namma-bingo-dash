import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/download_helper.dart';
import '../const/app_colors.dart';
import '../providers/app_providers.dart';
import '../utils/typography_utils.dart';

class QrGeneratorScreen extends ConsumerStatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  ConsumerState<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends ConsumerState<QrGeneratorScreen> {
  final GlobalKey _qrKey = GlobalKey();
  bool _isDownloading = false;

  Future<void> _downloadQRCode() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      RenderRepaintBoundary boundary = 
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      await saveImage(pngBytes, 'qr_code_${DateTime.now().millisecondsSinceEpoch}.png');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('QR Code downloaded!'),
              ],
            ),
            backgroundColor: AppColors.primaryBlue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: const Color(0xFFFF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'My QR Code',
            style: AppTypography.h2(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_add, size: 64, color: AppColors.lightCyan),
              const SizedBox(height: 16),
              Text(
                'Please set up your profile first',
                style: AppTypography.h3(context),
              ),
              const SizedBox(height: 8),
               Text(
                'Go to Profile to add your information',
                style: AppTypography.bodySmall(context, color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    final qrDataObject = {
      'app': 'namma_bingo_app',
      'signature': 'BINGO_USER_V1',
      'type': 'bingo_user',
      'id': currentUser.id,
      'name': currentUser.name,
      'linkedinUrl': currentUser.linkedinUrl,
      'profilePictureUrl': currentUser.profilePictureUrl,
      'scannedBoxes': currentUser.scannedBoxes.toList(),
      'timestamp': DateTime.now().toIso8601String(),
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };
    
    final jsonString = jsonEncode(qrDataObject);
    final qrData = base64Encode(utf8.encode(jsonString));

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'My QR Code',
                style: AppTypography.h2(context),
              ),
              centerTitle: true,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile info card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.lightCyan,
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: _isValidUrl(currentUser.profilePictureUrl)
                                  ? Image.network(
                                      currentUser.profilePictureUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Container(
                                        color: AppColors.primaryBlue.withOpacity(0.2),
                                        child: Center(
                                          child: Text(
                                            currentUser.name.isNotEmpty 
                                                ? currentUser.name.substring(0, 1).toUpperCase()
                                                : '?',
                                            style: AppTypography.h2(context, color: AppColors.lightCyan),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: AppColors.primaryBlue.withOpacity(0.2),
                                      child: Center(
                                        child: Text(
                                          currentUser.name.isNotEmpty 
                                              ? currentUser.name.substring(0, 1).toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: AppColors.lightCyan,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentUser.name,
                                  style: AppTypography.h3(context),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Connections: ${currentUser.scannedBoxes.length}/25',
                                  style: AppTypography.bodySmall(context, color: AppColors.lightCyan, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // QR Card
                    RepaintBoundary(
                      key: _qrKey,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'SCAN ME',
                              style: AppTypography.h2(context, color: AppColors.background, letterSpacing: 4, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: QrImageView(
                                data: qrData,
                                version: QrVersions.auto,
                                size: MediaQuery.of(context).size.width * 0.6,
                                foregroundColor: AppColors.background,
                                gapless: false,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Show this to others so they can scan you!',
                              style: AppTypography.bodySmall(context, color: Colors.black54),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Download/Save Buttons
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryBlue.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(15),
                                onTap: () => context.go('/profile'),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.edit, color: Colors.white, size: 16),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          'EDIT PROFILE',
                                          style: AppTypography.label(context, color: Colors.white, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(15),
                                onTap: _isDownloading ? null : _downloadQRCode,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_isDownloading)
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.lightCyan,
                                          ),
                                        )
                                      else
                                          const Icon(Icons.download, color: Colors.white, size: 16),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          _isDownloading ? 'SAVING...' : 'SAVE QR',
                                          style: AppTypography.label(context, color: Colors.white, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
      ),
    );
  }
}