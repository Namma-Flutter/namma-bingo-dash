import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../providers/app_providers.dart';
import '../widgets/bingo_grid.dart';
import '../const/app_colors.dart';
import '../utils/typography_utils.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  bool _showingQuestionMode = false;
  late AnimationController _dashController;
  late AnimationController _dashFloatController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _dashController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _dashFloatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);

    // Initialize current question index based on completed boxes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bingoBoxes = ref.read(bingoBoxesProvider.notifier);
      _currentQuestionIndex = bingoBoxes.completedCount;
    });
  }

  @override
  void dispose() {
    _dashController.dispose();
    _dashFloatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _showPersonDetails(BuildContext context, int boxId) {
    final bingoBoxes = ref.read(bingoBoxesProvider);
    final box = bingoBoxes.firstWhere((box) => box.id == boxId);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Profile section
            Row(
              children: [
                // Profile image
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
                    child: box.scannedByProfilePicture != null
                        ? Image.network(
                            box.scannedByProfilePicture!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildFallbackAvatar(box.scannedByName),
                          )
                        : _buildFallbackAvatar(box.scannedByName),
                  ),
                ),
                const SizedBox(width: 16),

                // Name and title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        box.scannedByName ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lightCyan.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.lightCyan,
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'Connected',
                          style: TextStyle(
                            color: AppColors.lightCyan,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Question answered section
            if (box.questionAnswered != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.lightCyan.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.quiz,
                          color: AppColors.lightCyan,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Question Answered:',
                          style: TextStyle(
                            color: AppColors.lightCyan,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getQuestionText(box.questionAnswered!),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Connect button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed:
                    box.scannedByLinkedIn != null &&
                        box.scannedByLinkedIn!.isNotEmpty
                    ? () => _launchLinkedIn(box.scannedByLinkedIn!)
                    : null,
                icon: const Icon(Icons.link, size: 20),
                label: Text(
                  box.scannedByLinkedIn != null &&
                          box.scannedByLinkedIn!.isNotEmpty
                      ? 'Connect on LinkedIn'
                      : 'No LinkedIn URL available',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      box.scannedByLinkedIn != null &&
                          box.scannedByLinkedIn!.isNotEmpty
                      ? const Color(0xFF0077B5)
                      : Colors.grey,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar(String? name) {
    final initial = name?.isNotEmpty == true ? name![0].toUpperCase() : '?';
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.lightCyan,
          ),
        ),
      ),
    );
  }

  String _getQuestionText(String questionAnswered) {
    // The questionAnswered field already contains the full question text
    return questionAnswered.isNotEmpty
        ? questionAnswered
        : 'Question not found';
  }

  Future<void> _launchLinkedIn(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open LinkedIn: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUnfilledQuestions() {
    final bingoBoxes = ref.read(bingoBoxesProvider);
    final currentUser = ref.read(currentUserProvider);
    final completedBoxes = bingoBoxes.where((box) => box.isSelected).length;

    final totalQuestions = ref.read(bingoBoxesProvider.notifier).questionsCount;
    // Check if all questions are completed
    if (completedBoxes >= totalQuestions) {
      _showCompletionDialog();
      return;
    }

    // Get unfilled questions by checking which box IDs are not scanned
    final unfilledQuestions = <Map<String, dynamic>>[];
    final notifier = ref.read(bingoBoxesProvider.notifier);
    for (int i = 0; i < totalQuestions; i++) {
      final boxId = i + 1; // Box IDs start from 1
      final isBoxFilled = currentUser?.scannedBoxes.contains(boxId) ?? false;

      if (!isBoxFilled) {
        unfilledQuestions.add({
          'index': i,
          'boxId': boxId,
          'question': notifier.getQuestionForBox(boxId),
        });
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.primaryBlue, width: 2),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      const Text(
                        'Select Question to Fill',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Unfilled questions list
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: unfilledQuestions.length,
                    itemBuilder: (context, index) {
                      final questionData = unfilledQuestions[index];
                      final questionIndex = questionData['index'];
                      final question = questionData['question'];

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.lightCyan.withOpacity(0.3),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${questionIndex + 1}',
                              style: const TextStyle(
                                color: AppColors.lightCyan,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          title: Text(
                            question,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.3,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: AppColors.lightCyan,
                            size: 24,
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            final boxId = questionData['boxId'];
                            _showSelectedQuestion(
                              questionIndex,
                              question,
                              boxId,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSelectedQuestion(int questionIndex, String question, int boxId) {
    setState(() {
      _showingQuestionMode = true;
      _currentQuestionIndex = questionIndex;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.primaryBlue, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Question header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Question ${questionIndex + 1}/${ref.read(bingoBoxesProvider.notifier).questionsCount}',
                        style: const TextStyle(
                          color: AppColors.background,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showingQuestionMode = false;
                        });
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.close, color: Colors.white),
                      iconSize: 20,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Question text
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.lightCyan.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    question,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _showingQuestionMode = false;
                          });
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.lightCyan),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.lightCyan,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Navigate to camera to scan for this question
                          context.go('/camera', extra: {
                            'boxId': boxId,
                            'questionIndex': questionIndex,
                            'questionText': question,
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Find & Scan',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      setState(() {
        _showingQuestionMode = false;
      });
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.primaryBlue, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.celebration,
                  color: AppColors.dashYellow,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Congratulations!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You have completed all ${ref.read(bingoBoxesProvider.notifier).questionsCount} networking questions!',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Awesome!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(questionsProvider);
    
    // Update questions when they are loaded
    questionsAsync.whenData((questions) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(bingoBoxesProvider.notifier).updateQuestions(questions);
      });
    });

    final currentUser = ref.watch(currentUserProvider);
    final bingoBoxes = ref.watch(bingoBoxesProvider);
    final totalQuestions = ref.watch(bingoBoxesProvider.notifier).questionsCount;
    final totalBoxes = totalQuestions;
    final scannedCount = currentUser?.scannedBoxes.length ?? 0;
    final remainingForBingo = totalQuestions - scannedCount; 

    // Update current question index based on completed boxes
    final completedBoxes = bingoBoxes.where((box) => box.isSelected).length;
    if (_currentQuestionIndex != completedBoxes && !_showingQuestionMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _currentQuestionIndex = completedBoxes;
        });
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppTypography.scale(context, 32),
              height: AppTypography.scale(context, 32),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 1),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://media.licdn.com/dms/image/v2/D560BAQHJALM_HLdjzg/company-logo_200_200/company-logo_200_200/0/1710185434227/nammaflutter_logo?e=1779926400&v=beta&t=OXTj9jG3myiQ53opFlHR94j8Obapxo0V7FWE8nwE5NA',
                        // 'https://instagram.fmaa2-2.fna.fbcdn.net/v/t51.2885-19/432574850_3559687864280900_8167034722177835075_n.jpg',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Namma Flutter Community',
                    style: AppTypography.bodySmall(context, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'BINGO CHALLENGE',
                    style: AppTypography.bodyMedium(context, fontWeight: FontWeight.w700, color: AppColors.lightCyan),
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: currentUser?.profilePictureUrl != null
                ? ClipOval(
                    child: Image.network(
                      currentUser!.profilePictureUrl!,
                      fit: BoxFit.cover,
                      width: 40,
                      height: 40,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            currentUser.name.isNotEmpty
                                ? currentUser.name[0].toUpperCase()
                                : 'U',
                            style: AppTypography.h3(context, color: AppColors.lightCyan),
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        currentUser?.name.isNotEmpty == true
                            ? currentUser!.name[0].toUpperCase()
                            : 'U',
                        style: AppTypography.h3(context, color: AppColors.lightCyan),
                      ),
                    ),
                  ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.settings, color: Colors.white),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.backgroundGradient,
              ),
            ),
          ),
          // Animated Background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _dashController,
              builder: (context, child) {
                return Stack(
                  children: [
                    // Dash 1
                    Positioned(
                      top: 100 + (math.sin(_dashController.value * 2 * math.pi) * 50),
                      left: -50 + (_dashController.value * MediaQuery.of(context).size.width * 1.5) % (MediaQuery.of(context).size.width + 200),
                      child: Opacity(
                        opacity: 0.1,
                        child: Transform.rotate(
                          angle: _dashController.value * 2 * math.pi * 0.2,
                          child: Image.network(
                            'https://flutter.dev/assets/shadow-dash.d59d0e8266b087a7a7f8a61c50ad4f6e.png',
                            width: 250,
                          ),
                        ),
                      ),
                    ),
                    // Dash 2
                    Positioned(
                      bottom: 150 + (math.cos(_dashController.value * 2 * math.pi) * 30),
                      right: -100 + ((1 - _dashController.value) * MediaQuery.of(context).size.width * 1.2) % (MediaQuery.of(context).size.width + 300),
                      child: Opacity(
                        opacity: 0.08,
                        child: Transform.rotate(
                          angle: -_dashController.value * 2 * math.pi * 0.1,
                          child: Image.network(
                            'https://flutter.dev/assets/shadow-dash.d59d0e8266b087a7a7f8a61c50ad4f6e.png',
                            width: 350,
                          ),
                        ),
                      ),
                    ),
                    // Dash 3 (Static float)
                    Positioned(
                      top: 300,
                      right: 20,
                      child: AnimatedBuilder(
                        animation: _dashFloatController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _dashFloatController.value * 20),
                            child: Opacity(
                              opacity: 0.05,
                              child: Image.network(
                                'https://flutter.dev/assets/shadow-dash.d59d0e8266b087a7a7f8a61c50ad4f6e.png',
                                width: 150,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          
          // Foreground Content
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Bingo Challenge Hero Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'BINGO',
                                style: AppTypography.label(context, color: Colors.white, fontWeight: FontWeight.w900),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'CHALLENGE',
                              style: AppTypography.h2(context, fontWeight: FontWeight.w200, letterSpacing: 2),
                            ),
                          ],
                        ),
                        Text(
                          'Connect with fellow Flutter developers!',
                          style: AppTypography.caption(context, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
            // Stats Section
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: scannedCount.toDouble()),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeOut,
              builder: (context, animatedValue, child) {
                final animatedCount = animatedValue.round();
                final animatedPercent = totalBoxes > 0 ? ((animatedValue / totalBoxes) * 100).toInt() : 0;
                final animatedProgress = totalBoxes > 0 ? animatedValue / totalBoxes : 0.0;
                final animatedRemaining = totalQuestions - animatedCount;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (animatedRemaining > 0)
                            Text(
                              '$animatedRemaining more to go bingo!',
                              style: AppTypography.bodyMedium(context, color: AppColors.lightCyan, fontWeight: FontWeight.w600),
                            ),
                          Text(
                            '$animatedPercent%',
                            style: AppTypography.label(context, color: AppColors.lightCyan.withOpacity(0.8)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: animatedProgress,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.lightCyan,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Bingo Grid
            Container(
              margin: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width < 400 ? 8 : 16),
              child: BingoGrid(
                boxes: bingoBoxes,
                onBoxTap: currentUser != null
                    ? (boxId) {
                        final box = bingoBoxes.firstWhere(
                          (box) => box.id == boxId,
                        );

                        if (box.scannedBy != null &&
                            currentUser.scannedBoxes.contains(boxId)) {
                          // Show person details for filled slots
                          _showPersonDetails(context, boxId);
                        } else if (!currentUser.scannedBoxes.contains(boxId)) {
                          // Navigate to camera for empty slots
                          context.go('/camera', extra: {'boxId': boxId});
                        }
                      }
                    : null,
                currentUser: currentUser,
              ),
            ),

            // Helper text
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Tap filled slots to view details and connect on LinkedIn',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Scan Button
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                final pulse = _pulseAnimation.value;
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: _currentQuestionIndex >= totalQuestions
                          ? const LinearGradient(colors: [Color(0xFF00AA66), Color(0xFF00CC88)])
                          : AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: (_currentQuestionIndex >= totalQuestions ? const Color(0xFF00AA66) : AppColors.primaryBlue)
                              .withOpacity(0.3 + 0.35 * pulse),
                          blurRadius: 12 + 18 * pulse,
                          spreadRadius: 1 + 3 * pulse,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: currentUser != null
                          ? _showUnfilledQuestions
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please set up your profile before scanning'),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              context.go('/profile');
                            },
                      icon: const Icon(Icons.qr_code_scanner, size: 28),
                      label: Text(
                        _currentQuestionIndex >= totalQuestions
                            ? 'All Questions Complete!'
                            : 'Scan to Connect',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ),
  ],
),
);
  }
}
