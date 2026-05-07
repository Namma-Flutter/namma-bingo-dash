import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../const/app_colors.dart';
import '../models/user.dart';
import '../providers/app_providers.dart';
import '../utils/typography_utils.dart';

class EnhancedProfileScreen extends ConsumerStatefulWidget {
  const EnhancedProfileScreen({super.key});

  @override
  ConsumerState<EnhancedProfileScreen> createState() => _EnhancedProfileScreenState();
}

class _EnhancedProfileScreenState extends ConsumerState<EnhancedProfileScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _profilePictureController = TextEditingController();
  bool _hasClipboardContent = false;
  late AnimationController _progressController;
  late AnimationController _shakeController;
  double _completionProgress = 0.0;

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
        _nameController.text = currentUser.name;
        _linkedinController.text = currentUser.linkedinUrl;
        _profilePictureController.text = currentUser.profilePictureUrl ?? '';
      }
      _calculateProgress();
      _checkClipboard();
    });
  }

  void _calculateProgress() {
    int totalFields = 3;
    int completedFields = 0;
    if (_nameController.text.trim().isNotEmpty) completedFields++;
    if (_linkedinController.text.trim().isNotEmpty && _validateLinkedInUrl(_linkedinController.text) == null) completedFields++;
    if (_profilePictureController.text.trim().isNotEmpty && _isValidUrl(_profilePictureController.text)) completedFields++;
    
    final newProgress = completedFields / totalFields;
    if (newProgress != _completionProgress) {
      setState(() {
        _completionProgress = newProgress;
      });
      _progressController.animateTo(_completionProgress, curve: Curves.easeInOut);
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
          _hasClipboardContent = data?.text != null && data!.text!.isNotEmpty;
        });
      }
    } catch (e) {
      // Handle silently
    }
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
    if (value == null || value.isEmpty) {
      return 'Please enter your LinkedIn URL';
    }
    
    final linkedinPattern = RegExp(
      r'^(https?:\/\/)?(www\.|[a-z]{2}\.)?linkedin\.com\/in\/[a-zA-Z0-9\-_%]+\/?(\?.*)?$',
      caseSensitive: false,
    );
    
    if (!linkedinPattern.hasMatch(value)) {
      return 'Please enter a valid LinkedIn URL';
    }
    
    return null;
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

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      final currentUser = ref.read(currentUserProvider);
      String linkedinUrl = _linkedinController.text.trim();
      if (linkedinUrl.isNotEmpty && !linkedinUrl.startsWith('http')) {
        linkedinUrl = 'https://$linkedinUrl';
      }

      final newUser = User(
        id: currentUser?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
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
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (context, anim1, anim2) => const SizedBox(),
          transitionBuilder: (context, anim1, anim2, child) {
            final curve = Curves.elasticOut.transform(anim1.value);
            final size = MediaQuery.of(context).size;
            final dialogWidth = size.width < 500 ? size.width * 0.9 : 400.0;
            
            return Transform.scale(
              scale: curve,
              child: Opacity(
                opacity: anim1.value.clamp(0.0, 1.0),
                child: Center(
                  child: Material(
                    type: MaterialType.transparency,
                    child: Container(
                      width: dialogWidth,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.cardBackground.withOpacity(0.98),
                            AppColors.background.withOpacity(0.95),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: AppColors.lightCyan.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(0.2),
                            blurRadius: 40,
                            spreadRadius: -10,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Stack(
                          children: [
                            Positioned(
                              top: -100,
                              left: -100,
                              child: Container(
                                width: 250,
                                height: 250,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryBlue.withOpacity(0.05),
                                ),
                              ),
                            ),
                            
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      const SizedBox(
                                        width: 200,
                                        height: 200,
                                        child: ConfettiWidget(),
                                      ),
                                      const AnimatedCheckmark(),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  ShaderMask(
                                    shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                                    child: Text(
                                      'FANTASTIC!',
                                      style: AppTypography.h1(context, letterSpacing: 4),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Profile Updated Successfully',
                                            style: AppTypography.bodyMedium(context, fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Your new identity is ready to go',
                                            style: AppTypography.bodySmall(context, color: Colors.white54),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
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
              ),
            );
          },
        );

        Future.delayed(const Duration(seconds: 4), () {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          ),
        ),
        title: Text(
          'My Profile',
          style: AppTypography.h3(context, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: AnimatedBuilder(
                          animation: _shakeController,
                          builder: (context, child) {
                            final double offset = math.sin(_shakeController.value * math.pi * 4) * 5;
                            return Transform.translate(
                              offset: Offset(offset, 0),
                              child: child,
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                                child: AnimatedBuilder(
                                  animation: _progressController,
                                  builder: (context, child) {
                                    return LinearProgressIndicator(
                                      value: _progressController.value,
                                      backgroundColor: Colors.white10,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _progressController.value == 1.0 
                                          ? Colors.greenAccent 
                                          : AppColors.lightCyan
                                      ),
                                      minHeight: 4,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(35),
                                    child: Container(
                                      width: 70,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.primaryBlue.withOpacity(0.2),
                                      ),
                                      child: _isValidUrl(_profilePictureController.text)
                                          ? Image.network(
                                              _profilePictureController.text,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return Shimmer.fromColors(
                                                  baseColor: AppColors.navyDeep,
                                                  highlightColor: AppColors.lightCyan,
                                                  child: Container(color: Colors.white24),
                                                );
                                              },
                                              errorBuilder: (context, error, stackTrace) =>
                                                  _buildInitials(),
                                            )
                                          : _buildInitials(),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Personal Details',
                                            style: AppTypography.h3(context, color: AppColors.lightCyan),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Fill in your info to complete your profile',
                                          style: AppTypography.caption(context, color: Colors.white.withOpacity(0.5)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              TextFormField(
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  labelText: 'Full Name',
                                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                  prefixIcon: const Icon(Icons.person, color: AppColors.lightCyan),
                                  suffixIcon: _nameController.text.trim().length >= 3 
                                    ? const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20)
                                    : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppColors.lightCyan, width: 2),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.background,
                                ),
                                style: AppTypography.bodyMedium(context),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  _calculateProgress();
                                },
                              ),
                              const SizedBox(height: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextFormField(
                                    controller: _linkedinController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'LinkedIn Profile URL',
                                      labelStyle: AppTypography.bodySmall(context, color: Colors.white.withOpacity(0.7)),
                                      prefixIcon: const Icon(Icons.link, color: AppColors.lightCyan),
                                      suffixIcon: _validateLinkedInUrl(_linkedinController.text) == null
                                        ? const Icon(Icons.verified, color: Colors.greenAccent, size: 20)
                                        : null,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: AppColors.lightCyan, width: 2),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                      ),
                                      filled: true,
                                      fillColor: AppColors.background,
                                      hintText: 'linkedin.com/in/yourprofile',
                                      hintStyle: AppTypography.bodySmall(context, color: Colors.white.withOpacity(0.5)),
                                    ),
                                    validator: _validateLinkedInUrl,
                                    keyboardType: TextInputType.url,
                                    onChanged: (value) {
                                      _calculateProgress();
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      if (_hasClipboardContent)
                                        Container(
                                          margin: const EdgeInsets.only(right: 8),
                                          decoration: BoxDecoration(
                                            color: AppColors.cardBackground,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: AppColors.lightCyan.withOpacity(0.3),
                                            ),
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(8),
                                              onTap: () async {
                                                final data = await Clipboard.getData(Clipboard.kTextPlain);
                                                if (data?.text != null) {
                                                  _linkedinController.text = data!.text!;
                                                  _calculateProgress();
                                                  _checkClipboard();
                                                }
                                              },
                                              child:  Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.content_paste, color: AppColors.lightCyan, size: 16),
                                                    const SizedBox(width: 4),
                                                    Text('Paste', style: AppTypography.label(context, color: AppColors.lightCyan)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (_linkedinController.text.isNotEmpty)
                                        Container(
                                          margin: const EdgeInsets.only(right: 8),
                                          decoration: BoxDecoration(
                                            color: AppColors.cardBackground,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: AppColors.lightCyan.withOpacity(0.3),
                                            ),
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(8),
                                              onTap: () async {
                                                await Clipboard.setData(ClipboardData(text: _linkedinController.text));
                                                _checkClipboard();
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: const Row(
                                                        children: [
                                                          Icon(Icons.check_circle, color: Colors.white),
                                                          SizedBox(width: 8),
                                                          Text('Copied to clipboard!'),
                                                        ],
                                                      ),
                                                      backgroundColor: AppColors.primaryBlue,
                                                      behavior: SnackBarBehavior.floating,
                                                    ),
                                                  );
                                                }
                                              },
                                              child:  Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.content_copy, color: AppColors.lightCyan, size: 16),
                                                    const SizedBox(width: 4),
                                                    Text('Copy', style: AppTypography.label(context, color: AppColors.lightCyan)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextFormField(
                                    controller: _profilePictureController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'Profile Picture URL (Optional)',
                                      labelStyle: AppTypography.bodySmall(context, color: Colors.white.withOpacity(0.7)),
                                      prefixIcon: const Icon(Icons.image, color: AppColors.lightCyan),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: AppColors.lightCyan, width: 2),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                      ),
                                      filled: true,
                                      fillColor: AppColors.background,
                                      hintText: 'https://example.com/photo.jpg',
                                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                    ),
                                    keyboardType: TextInputType.url,
                                    onChanged: (value) {
                                      _calculateProgress();
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      if (_hasClipboardContent)
                                        Container(
                                          margin: const EdgeInsets.only(right: 8),
                                          decoration: BoxDecoration(
                                            color: AppColors.cardBackground,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: AppColors.lightCyan.withOpacity(0.3),
                                            ),
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(8),
                                              onTap: () async {
                                                final data = await Clipboard.getData(Clipboard.kTextPlain);
                                                if (data?.text != null) {
                                                  _profilePictureController.text = data!.text!;
                                                  _calculateProgress();
                                                  _checkClipboard();
                                                }
                                              },
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.content_paste, color: AppColors.lightCyan, size: 16),
                                                    SizedBox(width: 4),
                                                    Text('Paste', style: TextStyle(color: AppColors.lightCyan, fontSize: 12)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (_profilePictureController.text.isNotEmpty)
                                        Container(
                                          margin: const EdgeInsets.only(right: 8),
                                          decoration: BoxDecoration(
                                            color: AppColors.cardBackground,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: AppColors.lightCyan.withOpacity(0.3),
                                            ),
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(8),
                                              onTap: () async {
                                                await Clipboard.setData(ClipboardData(text: _profilePictureController.text));
                                                _checkClipboard();
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: const Row(
                                                        children: [
                                                          Icon(Icons.check_circle, color: Colors.white),
                                                          SizedBox(width: 8),
                                                          Text('Copied to clipboard!'),
                                                        ],
                                                      ),
                                                      backgroundColor: AppColors.primaryBlue,
                                                      behavior: SnackBarBehavior.floating,
                                                    ),
                                                  );
                                                }
                                              },
                                              child:  Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.content_copy, color: AppColors.lightCyan, size: 16),
                                                    const SizedBox(width: 4),
                                                    Text('Copy', style: AppTypography.label(context, color: AppColors.lightCyan)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              Container(
                                width: double.infinity,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryBlue.withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    'SAVE PROFILE',
                                    style: AppTypography.bodyMedium(context, fontWeight: FontWeight.bold, letterSpacing: 1.2),
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
                const SizedBox(height: 32),
                
                // Community & Links Section
                Text(
                  'Community & Links',
                  style: AppTypography.h3(context, color: AppColors.lightCyan),
                ),
                const SizedBox(height: 16),
                
                // Namma Flutter Website
                _buildCommunityLink(
                  context,
                  title: 'Official Website',
                  subtitle: 'nammaflutter.com',
                  icon: Icons.language_rounded,
                  isExternal: true,
                  onTap: () async {
                    final uri = Uri.parse('https://nammaflutter.com/');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
                const SizedBox(height: 12),
                
                // Social Media (Linktree)
                _buildCommunityLink(
                  context,
                  title: 'Join Our Community',
                  subtitle: 'Discord, Telegram, & more',
                  icon: Icons.groups_rounded,
                  isExternal: true,
                  onTap: () async {
                    final uri = Uri.parse('https://linktr.ee/nammaflutter');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityLink(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isExternal = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: AppColors.lightCyan),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTypography.bodyMedium(context, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            subtitle,
                            style: AppTypography.caption(context, color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isExternal ? Icons.open_in_new_rounded : Icons.arrow_forward_ios_rounded,
                      color: Colors.white24,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitials() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
      ),
      child: Center(
        child: Text(
          _nameController.text.isNotEmpty
              ? _nameController.text[0].toUpperCase()
              : 'U',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class ConfettiWidget extends StatefulWidget {
  const ConfettiWidget({super.key});

  @override
  State<ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<ConfettiWidget> with SingleTickerProviderStateMixin {
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
      builder: (context, child) {
        return CustomPaint(
          painter: ConfettiPainter(_controller.value),
        );
      },
    );
  }
}

class ConfettiPainter extends CustomPainter {
  final double progress;
  ConfettiPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.pink, Colors.purple, Colors.orange];
    
    for (int i = 0; i < 50; i++) {
      final color = colors[random.nextInt(colors.length)];
      final paint = Paint()..color = color.withOpacity(1.0 - progress);
      
      final x = random.nextDouble() * size.width;
      final y = (random.nextDouble() * size.height + progress * 200) % size.height;
      final radius = random.nextDouble() * 4 + 2;
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AnimatedCheckmark extends StatefulWidget {
  const AnimatedCheckmark({super.key});

  @override
  State<AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<AnimatedCheckmark> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _checkAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _checkAnimation,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.greenAccent.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.greenAccent, width: 4),
        ),
        child: const Icon(Icons.check, color: Colors.greenAccent, size: 60),
      ),
    );
  }
}
