import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../const/app_colors.dart';
import '../const/app_config.dart';
import '../theme/app_text_styles.dart';
import 'dart:convert';
import 'dart:math' as math;

class CameraScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? args;
  const CameraScreen({super.key, this.args});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with TickerProviderStateMixin {
  late MobileScannerController cameraController;
  late AnimationController _successAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _blinkController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  bool _isScanning = true;
  bool _showSuccessAnimation = false;
  bool _torchEnabled = false;
  int? _boxId;
  int? _questionIndex;
  String? _questionText;
  Offset? _focusPoint;
  late AnimationController _focusRingController;
  late Animation<double> _focusRingAnimation;

  // Connected player info for the success overlay
  String _connectedName = '';
  String? _connectedPicture;
  int _connectedBoxId = 0;
  int _connectedTotal = 0;

  static const String _qrSignature  = 'BINGO_USER_V1';
  static const String _appIdentifier = 'namma_bingo_app';

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
    if (widget.args != null) {
      _boxId          = widget.args!['boxId'] as int?;
      _questionIndex  = widget.args!['questionIndex'] as int?;
      _questionText   = widget.args!['questionText'] as String?;
    }

    _successAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    )..repeat(reverse: true);

    _focusRingController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _focusRingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _focusRingController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successAnimationController, curve: Curves.easeOutBack),
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    _successAnimationController.dispose();
    _pulseAnimationController.dispose();
    _blinkController.dispose();
    _focusRingController.dispose();
    super.dispose();
  }

  // ── Tap to focus ──────────────────────────────────────────────────────────

  Future<void> _onTapFocus(TapUpDetails details) async {
    if (!mounted) return;
    setState(() => _focusPoint = details.localPosition);
    _focusRingController.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => _focusPoint = null);
  }

  // ── QR validation ─────────────────────────────────────────────────────────

  bool _isValidBingoQR(String qrData) {
    try {
      String decoded = qrData;
      try {
        final bytes = base64Decode(qrData);
        decoded = utf8.decode(bytes);
      } catch (_) {}
      final data = json.decode(decoded);
      return data is Map<String, dynamic> &&
          data['app'] == _appIdentifier &&
          data['type'] == 'bingo_user' &&
          data['signature'] == _qrSignature &&
          data['name'] is String &&
          data['name'].toString().trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ── Success animation ─────────────────────────────────────────────────────

  Future<void> _triggerSuccessAnimation({
    required String name,
    String? picture,
    required int boxId,
    required int total,
  }) async {
    if (!mounted) return;
    setState(() {
      _connectedName    = name;
      _connectedPicture = picture;
      _connectedBoxId   = boxId;
      _connectedTotal   = total;
      _showSuccessAnimation = true;
    });
    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(pattern: [0, 200, 100, 200], intensities: [0, 255, 0, 255]);
      }
    } catch (_) {}

    _successAnimationController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _pulseAnimationController.forward();
    await Future.delayed(const Duration(milliseconds: 2200));

    if (mounted) {
      setState(() => _showSuccessAnimation = false);
      _successAnimationController.reset();
      _pulseAnimationController.reset();
    }
  }

  Widget _buildInitialAvatar() {
    final letter = _connectedName.isNotEmpty ? _connectedName[0].toUpperCase() : '?';
    return Container(
      color: AppColors.neonGreen.withValues(alpha: 0.12),
      child: Center(
        child: Text(letter, style: AppTextStyles.pixel(size: 24, color: AppColors.neonGreen)),
      ),
    );
  }

  Widget _buildSuccessAnimationOverlay() {
    return AnimatedBuilder(
      animation: _successAnimationController,
      builder: (context, _) {
        return Container(
          color: Colors.black.withValues(alpha: 0.94),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Multi-color confetti burst
              CustomPaint(
                painter: _ConfettiPainter(_scaleAnimation.value),
              ),
              // Main content
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // "CONNECTION ESTABLISHED" header
                      Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Text(
                          'CONNECTION\nESTABLISHED',
                          style: AppTextStyles.pixel(
                            size: 11,
                            color: AppColors.neonGreen,
                            height: 1.8,
                            shadows: [
                              Shadow(
                                color: AppColors.neonGreen.withValues(alpha: 0.9),
                                blurRadius: 24,
                              ),
                              Shadow(
                                color: AppColors.neonGreen.withValues(alpha: 0.4),
                                blurRadius: 48,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Player card
                      Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          width: 260,
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF050510),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.neonGreen, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.neonGreen.withValues(alpha: 0.35),
                                blurRadius: 40,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Avatar
                              Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.neonGreen,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.neonGreen.withValues(alpha: 0.45),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: _connectedPicture != null &&
                                          _connectedPicture!.isNotEmpty
                                      ? Image.network(
                                          _connectedPicture!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => _buildInitialAvatar(),
                                        )
                                      : _buildInitialAvatar(),
                                ),
                              ),
                              const SizedBox(height: 14),
                              // Player name
                              Text(
                                _connectedName.isNotEmpty ? _connectedName : 'Player',
                                style: AppTextStyles.outfit(
                                  size: 16,
                                  weight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 18),
                              // Stats row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _StatBadge(
                                    label: 'BOX',
                                    value: '#$_connectedBoxId',
                                    color: AppColors.neonBlue,
                                  ),
                                  Container(
                                    width: 1,
                                    height: 36,
                                    color: Colors.white12,
                                  ),
                                  _StatBadge(
                                    label: 'LINKS',
                                    value: '$_connectedTotal',
                                    color: AppColors.neonPurple,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      // Pulse "+ 1 CONNECTION"
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (_, __) => Opacity(
                          opacity: _pulseAnimation.value,
                          child: Text(
                            '+ 1  CONNECTION',
                            style: AppTextStyles.pixel(
                              size: 8,
                              color: AppColors.neonYellow,
                              shadows: [
                                Shadow(
                                  color: AppColors.neonYellow.withValues(alpha: 0.8),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _showArcadeDialog({
    required String title,
    required String message,
    required Color accentColor,
    required IconData icon,
    required String buttonLabel,
    required VoidCallback onConfirm,
  }) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF06061A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: accentColor, width: 2),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accentColor, width: 2),
                  color: accentColor.withValues(alpha: 0.1),
                  boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.4), blurRadius: 16)],
                ),
                child: Icon(icon, color: accentColor, size: 34),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: AppTextStyles.pixel(size: 9, color: accentColor, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.45),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: onConfirm,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 20),
                  decoration: BoxDecoration(
                    border: Border.all(color: accentColor, width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                    color: accentColor.withValues(alpha: 0.1),
                    boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.3), blurRadius: 10)],
                  ),
                  child: Text(
                    '[ $buttonLabel ]',
                    style: AppTextStyles.pixel(size: 8, color: accentColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUnauthorizedQRWarning() {
    _showArcadeDialog(
      title: 'INVALID\nQR CODE',
      message: 'This QR code is not from the Bingo app. Please scan only valid player badges.',
      accentColor: const Color(0xFFFF6B35),
      icon: Icons.warning_rounded,
      buttonLabel: 'TRY AGAIN',
      onConfirm: () {
        Navigator.of(context).pop();
        setState(() => _isScanning = true);
        ref.read(scanStatusProvider.notifier).state = null;
      },
    );
  }

  void _showSelfScanError() {
    _showArcadeDialog(
      title: 'CANNOT\nSELF SCAN',
      message: 'You cannot scan your own QR code. Ask another player to scan yours!',
      accentColor: AppColors.error,
      icon: Icons.block,
      buttonLabel: 'GOT IT',
      onConfirm: () {
        Navigator.of(context).pop();
        setState(() => _isScanning = true);
        ref.read(scanStatusProvider.notifier).state = null;
      },
    );
  }

  void _showAlreadyScannedError(String userName) {
    _showArcadeDialog(
      title: 'ALREADY\nCONNECTED',
      message: 'You have already connected with $userName. Find a new player!',
      accentColor: AppColors.neonYellow,
      icon: Icons.person_off,
      buttonLabel: 'SCAN AGAIN',
      onConfirm: () {
        Navigator.of(context).pop();
        setState(() => _isScanning = true);
        ref.read(scanStatusProvider.notifier).state = null;
      },
    );
  }

  void _showSameUserScanError(String userName) {
    _showArcadeDialog(
      title: 'DUPLICATE\nDETECTED',
      message: 'You already scanned $userName. Seek a new connection to level up!',
      accentColor: AppColors.neonPurple,
      icon: Icons.repeat_rounded,
      buttonLabel: 'FIND NEW',
      onConfirm: () {
        Navigator.of(context).pop();
        setState(() => _isScanning = true);
        ref.read(scanStatusProvider.notifier).state = null;
      },
    );
  }

  // ── QR detect ─────────────────────────────────────────────────────────────

  void _onDetect(BarcodeCapture barcodeCapture) async {
    if (!_isScanning) return;
    final barcodes = barcodeCapture.barcodes;
    if (barcodes.isEmpty) return;
    final qrData = barcodes.first.rawValue;
    if (qrData == null) return;
    setState(() => _isScanning = false);
    await _processQrData(qrData);
  }

  Future<void> _processQrData(String qrData) async {
    try {
      ref.read(scanStatusProvider.notifier).state = 'PROCESSING...';

      if (!_isValidBingoQR(qrData)) {
        _showUnauthorizedQRWarning();
        return;
      }

      String decodedData = qrData;
      try {
        final bytes = base64Decode(qrData);
        decodedData = utf8.decode(bytes);
      } catch (_) {}

      final data = json.decode(decodedData);
      final String scannedUserName    = data['name'] ?? 'Unknown Player';
      final String? profilePictureUrl = data['profilePictureUrl'];
      final String? linkedInUrl       = data['linkedinUrl'];
      final String scannedUserId      =
          data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();

      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) throw 'Please set up your profile first';

      if (scannedUserId == currentUser.id) {
        _showSelfScanError();
        return;
      }

      if (!AppConfig.allowRepetitivePersonScan) {
        final bingoBoxes = ref.read(bingoBoxesProvider);
        final hasAlreadyScanned =
            bingoBoxes.any((box) => box.scannedBy == scannedUserId && box.isSelected);
        if (hasAlreadyScanned) {
          _showAlreadyScannedError(scannedUserName);
          return;
        }
        final alreadySelf = bingoBoxes.any((box) =>
            box.scannedBy == scannedUserId &&
            box.isSelected &&
            currentUser.scannedBoxes.contains(box.id));
        if (alreadySelf && !AppConfig.allowSameUserScan) {
          _showSameUserScanError(scannedUserName);
          return;
        }
      }

      int? availableBoxId = _boxId;
      if (availableBoxId == null) {
        final totalBoxes = ref.read(bingoBoxesProvider.notifier).questionsCount;
        for (int i = 1; i <= totalBoxes; i++) {
          if (!currentUser.scannedBoxes.contains(i)) {
            availableBoxId = i;
            break;
          }
        }
        if (availableBoxId == null) {
          throw 'All boxes are filled! Maximum connections reached.';
        }
      } else {
        if (currentUser.scannedBoxes.contains(availableBoxId)) {
          throw 'This box is already scanned!';
        }
      }

      ref.read(scanStatusProvider.notifier).state = 'CONNECTING...';
      await Future.delayed(const Duration(seconds: 1));

      await ref.read(currentUserProvider.notifier).addScannedBox(availableBoxId);

      final notifier = ref.read(bingoBoxesProvider.notifier);
      final questionAnswered = _questionText ?? notifier.getQuestionForBox(availableBoxId);

      ref.read(bingoBoxesProvider.notifier).selectBox(
        availableBoxId,
        scannedUserId,
        scannedUserName,
        profilePictureUrl,
        linkedInUrl: linkedInUrl,
        questionAnswered: questionAnswered,
      );

      ref.read(scanStatusProvider.notifier).state = 'CONNECTED!';
      final totalConnections = ref.read(currentUserProvider)?.scannedBoxes.length ?? 0;
      await _triggerSuccessAnimation(
        name: scannedUserName,
        picture: profilePictureUrl,
        boxId: availableBoxId,
        total: totalConnections,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.neonGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Connected with $scannedUserName!',
                      style: const TextStyle(color: Colors.white)),
                ),
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
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) context.go('/');
        });
      }
    } catch (e) {
      if (mounted) {
        _showArcadeDialog(
          title: 'ERROR',
          message: e.toString(),
          accentColor: AppColors.error,
          icon: Icons.error_outline_rounded,
          buttonLabel: 'TRY AGAIN',
          onConfirm: () {
            Navigator.of(context).pop();
            setState(() => _isScanning = true);
          },
        );
      }
    } finally {
      ref.read(scanStatusProvider.notifier).state = null;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scanStatus = ref.watch(scanStatusProvider);
    final notifier   = ref.watch(bingoBoxesProvider.notifier);
    final currentQuestion = _questionText
        ?? (_boxId != null ? notifier.getQuestionForBox(_boxId!) : 'Find someone to connect with!');
    final scanSize = (MediaQuery.of(context).size.width * 0.72).clamp(220.0, 310.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera feed with tap-to-focus
          Positioned.fill(
            child: GestureDetector(
              onTapUp: _onTapFocus,
              child: MobileScanner(controller: cameraController, onDetect: _onDetect),
            ),
          ),

          // Focus ring overlay
          if (_focusPoint != null)
            Positioned(
              left: _focusPoint!.dx - 36,
              top: _focusPoint!.dy - 36,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _focusRingAnimation,
                  builder: (_, __) {
                    final scale = 0.6 + 0.4 * (1 - _focusRingAnimation.value);
                    final opacity = (1 - _focusRingAnimation.value * 0.5).clamp(0.0, 1.0);
                    return Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.neonGreen,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.neonGreen.withValues(alpha: 0.4),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.neonGreen,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Dark radial vignette
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.85,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.72)],
                ),
              ),
            ),
          ),

          // Top bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.85), Colors.transparent],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                  child: Row(
                    children: [
                      _HudButton(
                        icon: Icons.close,
                        onTap: () => context.go('/'),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'SCAN TERMINAL',
                            style: AppTextStyles.pixel(
                              size: 9,
                              color: AppColors.neonGreen,
                              shadows: [
                                Shadow(
                                  color: AppColors.neonGreen.withValues(alpha: 0.8),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _HudButton(
                        icon: _torchEnabled ? Icons.flash_on : Icons.flash_off,
                        color: _torchEnabled ? AppColors.neonYellow : Colors.white60,
                        onTap: () async {
                          await cameraController.toggleTorch();
                          setState(() => _torchEnabled = !_torchEnabled);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Scan frame (center)
          Center(
            child: SizedBox(
              width: scanSize,
              height: scanSize,
              child: Stack(
                children: [
                  // Inner border
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.neonGreen.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                  // Pixel corner markers
                  const Positioned(top: 0, left: 0,
                      child: _PixelCorner(color: AppColors.neonGreen, position: _CornerPos.topLeft)),
                  const Positioned(top: 0, right: 0,
                      child: _PixelCorner(color: AppColors.neonGreen, position: _CornerPos.topRight)),
                  const Positioned(bottom: 0, left: 0,
                      child: _PixelCorner(color: AppColors.neonGreen, position: _CornerPos.bottomLeft)),
                  const Positioned(bottom: 0, right: 0,
                      child: _PixelCorner(color: AppColors.neonGreen, position: _CornerPos.bottomRight)),
                ],
              ),
            ),
          ),

          // Bottom panel
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.95),
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.6, 1],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Blinking scan status
                      AnimatedBuilder(
                        animation: _blinkController,
                        builder: (_, __) => Opacity(
                          opacity: _isScanning
                              ? 0.4 + 0.6 * _blinkController.value
                              : 1.0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7, height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.neonGreen,
                                  boxShadow: [BoxShadow(
                                    color: AppColors.neonGreen.withValues(alpha: 0.9),
                                    blurRadius: 6,
                                  )],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                scanStatus ?? 'SCANNING...',
                                style: AppTextStyles.pixel(
                                  size: 8,
                                  color: AppColors.neonGreen,
                                  shadows: [
                                    Shadow(
                                      color: AppColors.neonGreen.withValues(alpha: 0.7),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Mission card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.neonGreen.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '> MISSION',
                                  style: AppTextStyles.pixel(
                                    size: 7,
                                    color: AppColors.neonGreen.withValues(alpha: 0.6),
                                  ),
                                ),
                                if (_questionIndex != null) ...[
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.neonGreen.withValues(alpha: 0.4),
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      '#${_questionIndex! + 1}',
                                      style: AppTextStyles.pixel(
                                        size: 7,
                                        color: AppColors.neonGreen.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 7),
                            Text(
                              currentQuestion,
                              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Processing overlay
          if (scanStatus != null && scanStatus != 'CONNECTED!')
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.88),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: const Color(0xFF050510),
                      border: Border.all(color: AppColors.neonGreen, width: 2),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(color: AppColors.neonGreen.withValues(alpha: 0.3), blurRadius: 20),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: AppColors.neonGreen, strokeWidth: 2),
                        const SizedBox(height: 18),
                        Text(
                          scanStatus,
                          style: AppTextStyles.pixel(
                            size: 9,
                            color: AppColors.neonGreen,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Success animation
          if (_showSuccessAnimation)
            Positioned.fill(child: _buildSuccessAnimationOverlay()),
        ],
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────────

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTextStyles.pixel(size: 11, color: color, shadows: [
            Shadow(color: color.withValues(alpha: 0.7), blurRadius: 10),
          ]),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: AppTextStyles.pixel(
            size: 6,
            color: color.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }
}

class _HudButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _HudButton({
    required this.icon,
    required this.onTap,
    this.color = Colors.white60,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.45), width: 1),
          borderRadius: BorderRadius.circular(4),
          color: Colors.black.withValues(alpha: 0.5),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

enum _CornerPos { topLeft, topRight, bottomLeft, bottomRight }

class _PixelCorner extends StatelessWidget {
  final Color color;
  final _CornerPos position;

  const _PixelCorner({required this.color, required this.position});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          top: (position == _CornerPos.topLeft || position == _CornerPos.topRight)
              ? BorderSide(color: color, width: 3)
              : BorderSide.none,
          bottom: (position == _CornerPos.bottomLeft || position == _CornerPos.bottomRight)
              ? BorderSide(color: color, width: 3)
              : BorderSide.none,
          left: (position == _CornerPos.topLeft || position == _CornerPos.bottomLeft)
              ? BorderSide(color: color, width: 3)
              : BorderSide.none,
          right: (position == _CornerPos.topRight || position == _CornerPos.bottomRight)
              ? BorderSide(color: color, width: 3)
              : BorderSide.none,
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  _ConfettiPainter(this.progress);

  static const _colors = [
    AppColors.neonGreen,
    AppColors.neonPink,
    AppColors.neonBlue,
    AppColors.neonYellow,
    AppColors.neonPurple,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 30; i++) {
      final angle = rng.nextDouble() * 2 * math.pi;
      final speed = 80.0 + rng.nextDouble() * size.width * 0.42;
      final dist  = progress * speed;
      final cx    = size.width / 2 + math.cos(angle) * dist;
      final cy    = size.height / 2 + math.sin(angle) * dist;
      final alpha = ((1.0 - progress) * 255).toInt().clamp(0, 255);
      paint.color = _colors[i % _colors.length].withAlpha(alpha);
      final radius = 2.5 + rng.nextDouble() * 2.5;
      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
