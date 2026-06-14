import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../const/app_colors.dart';
import '../models/user.dart';
import '../providers/app_providers.dart';

class EnhancedProfileScreen extends ConsumerStatefulWidget {
  const EnhancedProfileScreen({super.key});

  @override
  ConsumerState<EnhancedProfileScreen> createState() =>
      _EnhancedProfileScreenState();
}

class _EnhancedProfileScreenState
    extends ConsumerState<EnhancedProfileScreen>
    with TickerProviderStateMixin {
  final _formKey               = GlobalKey<FormState>();
  final _nameController        = TextEditingController();
  final _linkedinController    = TextEditingController();
  final _profilePictureController = TextEditingController();
  bool _hasClipboardContent   = false;
  late AnimationController _progressController;
  late AnimationController _shakeController;
  double _completionProgress  = 0.0;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        _nameController.text     = currentUser.name;
        _linkedinController.text = currentUser.linkedinUrl;
        _syncLinkedInPhoto(currentUser.linkedinUrl);
      }
      _calculateProgress();
      _checkClipboard();
    });
  }

  void _calculateProgress() {
    int completed = 0;
    if (_nameController.text.trim().isNotEmpty) completed++;
    if (_linkedinController.text.trim().isNotEmpty &&
        _validateLinkedInUrl(_linkedinController.text) == null) {
      completed++;
    }
    final newProgress = completed / 2;
    if (newProgress != _completionProgress) {
      setState(() => _completionProgress = newProgress);
      _progressController.animateTo(_completionProgress,
          curve: Curves.easeInOut);
    }
  }

  void _shakeForm() {
    _shakeController.forward(from: 0).then((_) => _shakeController.reverse());
    HapticFeedback.vibrate();
  }

  Future<void> _checkClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (mounted) {
        setState(() {
          _hasClipboardContent =
              data?.text != null && data!.text!.isNotEmpty;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _linkedinController.dispose();
    _profilePictureController.dispose();
    _progressController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  String? _validateLinkedInUrl(String? value) {
    if (value == null || value.isEmpty) return 'LinkedIn URL required';
    final pat = RegExp(
      r'^(https?:\/\/)?(www\.|[a-z]{2}\.)?linkedin\.com\/in\/[a-zA-Z0-9\-_%]+\/?(\?.*)?$',
      caseSensitive: false,
    );
    if (!pat.hasMatch(value)) return 'Enter a valid LinkedIn URL';
    return null;
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

  void _syncLinkedInPhoto(String linkedinUrl) {
    final match = RegExp(
      r'linkedin\.com/in/([a-zA-Z0-9\-_%]+)',
      caseSensitive: false,
    ).firstMatch(linkedinUrl.trim());
    final url = match != null
        ? 'https://unavatar.io/linkedin/${match.group(1)!.replaceAll('/', '')}'
        : '';
    if (_profilePictureController.text != url) {
      _profilePictureController.text = url;
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      final currentUser = ref.read(currentUserProvider);
      String linkedinUrl = _linkedinController.text.trim();
      if (linkedinUrl.isNotEmpty && !linkedinUrl.startsWith('http')) {
        linkedinUrl = 'https://$linkedinUrl';
      }
      final newUser = User(
        id: currentUser?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        linkedinUrl: linkedinUrl,
        profilePictureUrl: _profilePictureController.text.trim().isEmpty
            ? null
            : _profilePictureController.text.trim(),
        scannedBoxes: currentUser?.scannedBoxes ?? {},
      );
      await ref.read(currentUserProvider.notifier).updateUser(newUser);

      if (mounted) {
        showGeneralDialog(
          context: context,
          barrierDismissible: false,
          barrierLabel: '',
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, anim1, anim2) => const SizedBox(),
          transitionBuilder: (context, anim1, anim2, child) {
            final curve = Curves.elasticOut.transform(anim1.value);
            return Transform.scale(
              scale: curve,
              child: Opacity(
                opacity: anim1.value.clamp(0.0, 1.0),
                child: Center(
                  child: Material(
                    type: MaterialType.transparency,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.88,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06061A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.neonGreen, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.neonGreen.withValues(alpha: 0.35),
                            blurRadius: 30,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 180,
                                  height: 180,
                                  child: ConfettiWidget(),
                                ),
                                const AnimatedCheckmark(),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text('PROFILE\nSAVED!',
                                style: GoogleFonts.pressStart2p(
                                  color: AppColors.neonGreen,
                                  fontSize: 16,
                                  height: 1.5,
                                  shadows: [
                                    Shadow(
                                      color: AppColors.neonGreen
                                          .withValues(alpha: 0.9),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.neonGreen
                                      .withValues(alpha: 0.3),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                color: AppColors.neonGreen
                                    .withValues(alpha: 0.05),
                              ),
                              child: Text(
                                'Your arcade card is ready!\nReturning to game...',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.45,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.pop(context);
            context.go('/');
          }
        });
      }
    } else {
      _shakeForm();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _ScanlinePainter())),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header bar ───────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                    child: Row(
                      children: [
                        // Back button
                        GestureDetector(
                          onTap: () =>
                              context.canPop() ? context.pop() : context.go('/'),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              color: Colors.white.withValues(alpha: 0.04),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: Colors.white70, size: 16),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PLAYER SETUP',
                                style: GoogleFonts.pressStart2p(
                                  color: AppColors.neonPink,
                                  fontSize: 11,
                                  shadows: [
                                    Shadow(
                                      color: AppColors.neonPink
                                          .withValues(alpha: 0.8),
                                      blurRadius: 12,
                                    ),
                                  ],
                                )),
                            const SizedBox(height: 2),
                            Text('configure your arcade card',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  fontSize: 10,
                                  letterSpacing: 0.3,
                                )),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Avatar + progress ────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.neonPink, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.neonPink.withValues(alpha: 0.4),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _isValidUrl(_profilePictureController.text)
                                ? Image.network(
                                    _profilePictureController.text,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (_, child, progress) {
                                      if (progress == null) return child;
                                      return Shimmer.fromColors(
                                        baseColor: const Color(0xFF0A0A22),
                                        highlightColor:
                                            AppColors.neonPink.withValues(alpha: 0.4),
                                        child: Container(color: Colors.white12),
                                      );
                                    },
                                    errorBuilder: (_, __, ___) =>
                                        _buildInitials(),
                                  )
                                : _buildInitials(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('PROFILE COMPLETION',
                                  style: GoogleFonts.pressStart2p(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    fontSize: 6,
                                  )),
                              const SizedBox(height: 6),
                              AnimatedBuilder(
                                animation: _progressController,
                                builder: (_, __) {
                                  final pct = (_progressController.value * 100)
                                      .toInt();
                                  final col = _progressController.value >= 1.0
                                      ? AppColors.neonGreen
                                      : AppColors.neonPink;
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('$pct%',
                                          style: GoogleFonts.pressStart2p(
                                            color: col,
                                            fontSize: 14,
                                            shadows: [
                                              Shadow(
                                                  color: col.withValues(
                                                      alpha: 0.7),
                                                  blurRadius: 10)
                                            ],
                                          )),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(2),
                                        child: LinearProgressIndicator(
                                          value: _progressController.value,
                                          backgroundColor:
                                              Colors.white.withValues(alpha: 0.08),
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(col),
                                          minHeight: 4,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Form card ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF08081C),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.neonPink.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.neonPink.withValues(alpha: 0.06),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: AnimatedBuilder(
                          animation: _shakeController,
                          builder: (context, child) {
                            final offset =
                                math.sin(_shakeController.value * math.pi * 4) *
                                    6;
                            return Transform.translate(
                              offset: Offset(offset, 0),
                              child: child,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Section label
                                Text('IDENTITY',
                                    style: GoogleFonts.pressStart2p(
                                      color:
                                          AppColors.neonPink.withValues(alpha: 0.7),
                                      fontSize: 7,
                                    )),
                                const SizedBox(height: 16),

                                // Name field
                                _ArcadeField(
                                  controller: _nameController,
                                  label: 'FULL NAME',
                                  hint: 'Enter your name',
                                  icon: Icons.person_rounded,
                                  accentColor: AppColors.neonPink,
                                  capitalization: TextCapitalization.words,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Name required';
                                    }
                                    return null;
                                  },
                                  onChanged: (_) => _calculateProgress(),
                                  suffix: _nameController.text.trim().length >= 3
                                      ? const Icon(Icons.check_circle_rounded,
                                          color: AppColors.neonGreen, size: 18)
                                      : null,
                                ),

                                const SizedBox(height: 16),

                                // LinkedIn field
                                _ArcadeField(
                                  controller: _linkedinController,
                                  label: 'LINKEDIN URL',
                                  hint: 'linkedin.com/in/yourname',
                                  icon: Icons.link_rounded,
                                  accentColor: AppColors.neonBlue,
                                  keyboardType: TextInputType.url,
                                  validator: _validateLinkedInUrl,
                                  onChanged: (v) {
                                    _syncLinkedInPhoto(v);
                                    _calculateProgress();
                                  },
                                  suffix: _validateLinkedInUrl(
                                              _linkedinController.text) ==
                                          null
                                      ? const Icon(Icons.verified_rounded,
                                          color: AppColors.neonGreen, size: 18)
                                      : null,
                                ),

                                // Clipboard/copy buttons
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    if (_hasClipboardContent)
                                      _PillButton(
                                        icon: Icons.content_paste_rounded,
                                        label: 'PASTE',
                                        color: AppColors.neonBlue,
                                        onTap: () async {
                                          final data = await Clipboard.getData(
                                              Clipboard.kTextPlain);
                                          if (data?.text != null) {
                                            _linkedinController.text =
                                                data!.text!;
                                            _syncLinkedInPhoto(data.text!);
                                            _calculateProgress();
                                            _checkClipboard();
                                          }
                                        },
                                      ),
                                    if (_hasClipboardContent)
                                      const SizedBox(width: 8),
                                    if (_linkedinController.text.isNotEmpty)
                                      _PillButton(
                                        icon: Icons.content_copy_rounded,
                                        label: 'COPY',
                                        color: AppColors.neonBlue,
                                        onTap: () async {
                                          final messenger = ScaffoldMessenger.of(context);
                                          await Clipboard.setData(ClipboardData(
                                              text: _linkedinController.text));
                                          _checkClipboard();
                                          if (!mounted) return;
                                          messenger.showSnackBar(
                                              SnackBar(
                                                content: const Row(
                                                  children: [
                                                    Icon(Icons.check_circle,
                                                        color:
                                                            AppColors.neonGreen),
                                                    SizedBox(width: 8),
                                                    Text('Copied!',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white)),
                                                  ],
                                                ),
                                                backgroundColor:
                                                    const Color(0xFF050F05),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  side: const BorderSide(
                                                      color:
                                                          AppColors.neonGreen,
                                                      width: 1),
                                                ),
                                              ),
                                            );
                                        },
                                      ),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                // Save button
                                GestureDetector(
                                  onTap: _saveProfile,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.neonPink
                                              .withValues(alpha: 0.2),
                                          AppColors.neonPurple
                                              .withValues(alpha: 0.2),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: AppColors.neonPink, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.neonPink
                                              .withValues(alpha: 0.35),
                                          blurRadius: 16,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        '[ SAVE PROFILE ]',
                                        style: GoogleFonts.pressStart2p(
                                          color: AppColors.neonPink,
                                          fontSize: 10,
                                          shadows: [
                                            Shadow(
                                              color: AppColors.neonPink
                                                  .withValues(alpha: 0.8),
                                              blurRadius: 10,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Community links ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('COMMUNITY',
                        style: GoogleFonts.pressStart2p(
                          color: AppColors.neonBlue.withValues(alpha: 0.7),
                          fontSize: 7,
                        )),
                  ),
                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _CommunityCard(
                          title: 'OFFICIAL WEBSITE',
                          subtitle: 'nammaflutter.com',
                          icon: Icons.language_rounded,
                          accentColor: AppColors.neonBlue,
                          onTap: () async {
                            final uri = Uri.parse('https://nammaflutter.com/');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        _CommunityCard(
                          title: 'JOIN COMMUNITY',
                          subtitle: 'Discord, Telegram & more',
                          icon: Icons.groups_rounded,
                          accentColor: AppColors.neonPurple,
                          onTap: () async {
                            final uri =
                                Uri.parse('https://linktr.ee/nammaflutter');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitials() {
    final initial = _nameController.text.isNotEmpty
        ? _nameController.text[0].toUpperCase()
        : '?';
    return Container(
      color: AppColors.neonPink.withValues(alpha: 0.12),
      child: Center(
        child: Text(initial,
            style: const TextStyle(
                color: AppColors.neonPink,
                fontSize: 28,
                fontWeight: FontWeight.w900)),
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _ArcadeField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Color accentColor;
  final TextCapitalization capitalization;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final Widget? suffix;

  const _ArcadeField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.accentColor,
    this.capitalization = TextCapitalization.none,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(label,
              style: GoogleFonts.pressStart2p(
                color: accentColor.withValues(alpha: 0.65),
                fontSize: 6,
              )),
        ),
        TextFormField(
          controller: controller,
          textCapitalization: capitalization,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.25), fontSize: 13),
            prefixIcon: Icon(icon, color: accentColor, size: 20),
            suffixIcon: suffix,
            filled: true,
            fillColor: const Color(0xFF060614),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: accentColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide:
                  const BorderSide(color: AppColors.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide:
                  const BorderSide(color: AppColors.error, width: 2),
            ),
            errorStyle: const TextStyle(color: AppColors.error, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PillButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
          borderRadius: BorderRadius.circular(4),
          color: color.withValues(alpha: 0.07),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 5),
            Text(label,
                style: GoogleFonts.pressStart2p(color: color, fontSize: 6)),
          ],
        ),
      ),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _CommunityCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF08081C),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accentColor.withValues(alpha: 0.18), width: 1),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Left accent bar
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(7),
                    bottomLeft: Radius.circular(7),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: accentColor.withValues(alpha: 0.5), width: 1.5),
                color: accentColor.withValues(alpha: 0.1),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.pressStart2p(
                          color: accentColor, fontSize: 7)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.open_in_new_rounded,
                color: accentColor.withValues(alpha: 0.5), size: 16),
          ],
        ),
      ),
          ],
        ),
      ),
    );
  }
}

// ── Background ─────────────────────────────────────────────────────────────────

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.012)
      ..style = PaintingStyle.fill;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1.5), p);
    }
    final dot = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.018)
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

// ── Save dialog widgets ────────────────────────────────────────────────────────

class ConfettiWidget extends StatefulWidget {
  const ConfettiWidget({super.key});

  @override
  State<ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<ConfettiWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) =>
          CustomPaint(painter: _ConfettiPainter(_controller.value)),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  _ConfettiPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    const colors = [
      AppColors.neonPink,
      AppColors.neonBlue,
      AppColors.neonGreen,
      AppColors.neonYellow,
      AppColors.neonPurple,
    ];
    for (int i = 0; i < 40; i++) {
      final color = colors[rng.nextInt(colors.length)];
      final paint = Paint()..color = color.withValues(alpha: 1.0 - progress);
      final x  = rng.nextDouble() * size.width;
      final y  = (rng.nextDouble() * size.height + progress * 220) % size.height;
      final r  = rng.nextDouble() * 4 + 2;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}

class AnimatedCheckmark extends StatefulWidget {
  const AnimatedCheckmark({super.key});

  @override
  State<AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<AnimatedCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _anim,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.neonGreen, width: 3),
          color: AppColors.neonGreen.withValues(alpha: 0.12),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonGreen.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Icon(Icons.check_rounded,
            color: AppColors.neonGreen, size: 50),
      ),
    );
  }
}
