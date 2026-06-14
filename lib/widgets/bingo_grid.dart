import 'package:flutter/material.dart';
import '../models/user.dart';
import '../const/app_colors.dart';
import '../theme/app_text_styles.dart';

class BingoGrid extends StatelessWidget {
  final List<BingoBox> boxes;
  final Function(int)? onBoxTap;
  final User? currentUser;

  const BingoGrid({
    super.key,
    required this.boxes,
    this.onBoxTap,
    this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    if (boxes.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.neonPink),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 1,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: boxes.length,
      itemBuilder: (context, index) {
        final box = boxes[index];
        final col = index % 5;
        final isOwn = currentUser?.scannedBoxes.contains(box.id) ?? false;
        return BingoBoxWidget(
          box: box,
          column: col,
          isScannedByCurrentUser: isOwn,
          onTap: onBoxTap != null ? () => onBoxTap!(box.id) : null,
          isEnabled: currentUser != null,
        );
      },
    );
  }
}

class BingoBoxWidget extends StatelessWidget {
  final BingoBox box;
  final int column;
  final bool isScannedByCurrentUser;
  final VoidCallback? onTap;
  final bool isEnabled;

  const BingoBoxWidget({
    super.key,
    required this.box,
    required this.column,
    required this.isScannedByCurrentUser,
    this.onTap,
    required this.isEnabled,
  });

  static const _colColors = [
    AppColors.neonBlue,
    AppColors.neonPink,
    AppColors.neonGreen,
    AppColors.neonYellow,
    AppColors.neonPurple,
  ];

  static const _colLetters = ['B', 'I', 'N', 'G', 'O'];

  @override
  Widget build(BuildContext context) {
    final color = _colColors[column];
    final letter = _colLetters[column];
    final isScanned = box.scannedBy != null;

    final borderColor = isScanned
        ? color.withValues(alpha: isScannedByCurrentUser ? 0.9 : 0.35)
        : color.withValues(alpha: 0.18);

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A1E),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: borderColor,
            width: isScannedByCurrentUser ? 1.5 : 1,
          ),
          boxShadow: isScannedByCurrentUser
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Column letter watermark at top
              Positioned(
                top: 3,
                child: Text(
                  letter,
                  style: AppTextStyles.pixel(
                    size: 5,
                    color: color.withValues(alpha: isScanned ? 0.12 : 0.3),
                  ),
                ),
              ),
              // Large bold number (always present)
              Text(
                '${box.id}',
                style: TextStyle(
                  color: isScanned
                      ? color.withValues(alpha: 0.15)
                      : color.withValues(alpha: 0.6),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              // Dauber stamp overlay (when scanned)
              if (isScanned) _DauberStamp(box: box, color: color, isOwn: isScannedByCurrentUser),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dauber stamp overlay ───────────────────────────────────────────────────────

class _DauberStamp extends StatelessWidget {
  final BingoBox box;
  final Color color;
  final bool isOwn;

  const _DauberStamp({required this.box, required this.color, required this.isOwn});

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
    final name = box.scannedByName;
    final initial = name?.isNotEmpty == true ? name![0].toUpperCase() : '?';
    final dauberAlpha = isOwn ? 0.88 : 0.55;

    return FractionallySizedBox(
      widthFactor: 0.76,
      heightFactor: 0.76,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: dauberAlpha),
          boxShadow: isOwn
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.7),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 28,
                    spreadRadius: 4,
                  ),
                ]
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 8,
                  ),
                ],
        ),
        child: ClipOval(
          child: _isValidUrl(box.scannedByProfilePicture)
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      box.scannedByProfilePicture!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _initial(initial),
                      loadingBuilder: (_, child, progress) =>
                          progress == null ? child : _initial(initial),
                    ),
                    // Ink tint overlay on photo
                    Container(color: color.withValues(alpha: isOwn ? 0.22 : 0.35)),
                  ],
                )
              : _initial(initial),
        ),
      ),
    );
  }

  Widget _initial(String letter) {
    return Container(
      color: Colors.transparent,
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: Colors.black.withValues(alpha: 0.75),
            height: 1,
          ),
        ),
      ),
    );
  }
}
