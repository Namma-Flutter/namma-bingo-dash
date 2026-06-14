import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../widgets/bingo_grid.dart';
import '../const/app_colors.dart';
import '../utils/typography_utils.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  bool _showingQuestionMode = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnimation =
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currentQuestionIndex =
          ref.read(bingoBoxesProvider.notifier).completedCount;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Bottom-sheet: person details ────────────────────────────────────────────

  void _showPersonDetails(BuildContext context, int boxId) {
    final box = ref.read(bingoBoxesProvider).firstWhere((b) => b.id == boxId);
    final colColors = [
      AppColors.neonBlue, AppColors.neonPink, AppColors.neonGreen,
      AppColors.neonYellow, AppColors.neonPurple
    ];
    final accentColor = colColors[(boxId - 1) % 5];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF07071A),
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        side: BorderSide(color: accentColor, width: 1.5),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32, height: 3,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor, width: 2),
                    boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.4), blurRadius: 12)],
                  ),
                  child: ClipOval(
                    child: box.scannedByProfilePicture != null
                        ? Image.network(
                            box.scannedByProfilePicture!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildAvatar(box.scannedByName, accentColor),
                          )
                        : _buildAvatar(box.scannedByName, accentColor),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(box.scannedByName ?? 'Unknown',
                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          border: Border.all(color: accentColor, width: 1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '✓ CONNECTED',
                          style: GoogleFonts.pressStart2p(
                            color: accentColor, fontSize: 7, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (box.questionAnswered != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('QUESTION', style: GoogleFonts.pressStart2p(
                      color: accentColor.withValues(alpha: 0.7), fontSize: 7)),
                    const SizedBox(height: 6),
                    Text(box.questionAnswered!,
                        style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: box.scannedByLinkedIn?.isNotEmpty == true
                    ? () => _launchLinkedIn(box.scannedByLinkedIn!)
                    : null,
                icon: const Icon(Icons.link, size: 18),
                label: Text(
                  box.scannedByLinkedIn?.isNotEmpty == true ? 'CONNECT ON LINKEDIN' : 'NO LINKEDIN URL',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: box.scannedByLinkedIn?.isNotEmpty == true
                      ? accentColor : Colors.grey.shade800,
                  foregroundColor: Colors.black,
                  shadowColor: accentColor.withValues(alpha: 0.5),
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? name, Color color) {
    final initial = name?.isNotEmpty == true ? name![0].toUpperCase() : '?';
    return Container(
      color: color.withValues(alpha: 0.15),
      child: Center(
        child: Text(initial,
            style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
      ),
    );
  }

  // ── Unfilled question picker ─────────────────────────────────────────────────

  void _showUnfilledQuestions() {
    final bingoBoxes  = ref.read(bingoBoxesProvider);
    final currentUser = ref.read(currentUserProvider);
    final total       = ref.read(bingoBoxesProvider.notifier).questionsCount;
    final completed   = bingoBoxes.where((b) => b.isSelected).length;

    if (completed >= total) {
      _showCompletionDialog();
      return;
    }

    final notifier = ref.read(bingoBoxesProvider.notifier);
    final unfilled = <Map<String, dynamic>>[];
    for (int i = 0; i < total; i++) {
      final boxId = i + 1;
      if (!(currentUser?.scannedBoxes.contains(boxId) ?? false)) {
        unfilled.add({
          'index': i,
          'boxId': boxId,
          'question': notifier.getQuestionForBox(boxId),
        });
      }
    }

    final colColors = [
      AppColors.neonBlue, AppColors.neonPink, AppColors.neonGreen,
      AppColors.neonYellow, AppColors.neonPurple
    ];

    showDialog(
      context: context,
      builder: (dlgCtx) => Dialog(
        backgroundColor: const Color(0xFF07071A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.neonPink, width: 1.5),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            maxWidth:  MediaQuery.of(context).size.width  * 0.92,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                child: Row(
                  children: [
                    Text('PICK MISSION', style: GoogleFonts.pressStart2p(
                      color: AppColors.neonPink, fontSize: 9)),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(dlgCtx).pop(),
                      icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  itemCount: unfilled.length,
                  itemBuilder: (_, i) {
                    final q = unfilled[i];
                    final accent = colColors[((q['boxId'] as int) - 1) % 5];
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(dlgCtx).pop();
                        _showSelectedQuestion(q['index'], q['question'], q['boxId']);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 7),
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: accent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: accent, width: 1.5),
                                color: accent.withValues(alpha: 0.1),
                              ),
                              child: Center(
                                child: Text('${q['boxId']}',
                                    style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w900)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(q['question'],
                                  style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.3)),
                            ),
                            Icon(Icons.chevron_right, color: accent.withValues(alpha: 0.7), size: 18),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSelectedQuestion(int questionIndex, String question, int boxId) {
    setState(() {
      _showingQuestionMode  = true;
      _currentQuestionIndex = questionIndex;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dlgCtx) => Dialog(
        backgroundColor: const Color(0xFF07071A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.neonBlue, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.neonBlue, width: 1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'Q ${questionIndex + 1}/${ref.read(bingoBoxesProvider.notifier).questionsCount}',
                      style: GoogleFonts.pressStart2p(
                        color: AppColors.neonBlue, fontSize: 8),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      setState(() => _showingQuestionMode = false);
                      Navigator.of(dlgCtx).pop();
                    },
                    icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.neonBlue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.neonBlue.withValues(alpha: 0.3)),
                ),
                child: Text(question,
                    style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.45),
                    textAlign: TextAlign.center),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => _showingQuestionMode = false);
                        Navigator.of(dlgCtx).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('CANCEL',
                          style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dlgCtx).pop();
                        context.go('/camera', extra: {
                          'boxId':         boxId,
                          'questionIndex': questionIndex,
                          'questionText':  question,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonPink,
                        foregroundColor: Colors.black,
                        elevation: 6,
                        shadowColor: AppColors.neonPink.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('SCAN',
                          style: GoogleFonts.pressStart2p(fontSize: 10, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).then((_) => setState(() => _showingQuestionMode = false));
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF07071A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.neonYellow, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 16),
              Text(
                'BINGO!',
                style: GoogleFonts.pressStart2p(
                  color: AppColors.neonYellow,
                  fontSize: 22,
                  shadows: [const Shadow(color: AppColors.neonYellow, blurRadius: 24)],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'All ${ref.read(bingoBoxesProvider.notifier).questionsCount} connections made!',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.neonYellow, width: 2),
                    borderRadius: BorderRadius.circular(6),
                    color: AppColors.neonYellow.withValues(alpha: 0.12),
                    boxShadow: [BoxShadow(color: AppColors.neonYellow.withValues(alpha: 0.4), blurRadius: 16)],
                  ),
                  child: Text('[ AWESOME! ]',
                      style: GoogleFonts.pressStart2p(
                        color: AppColors.neonYellow, fontSize: 9)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open LinkedIn: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(questionsProvider);
    questionsAsync.whenData((questions) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(bingoBoxesProvider.notifier).updateQuestions(questions);
      });
    });

    final currentUser  = ref.watch(currentUserProvider);
    final bingoBoxes   = ref.watch(bingoBoxesProvider);
    final total        = ref.watch(bingoBoxesProvider.notifier).questionsCount;
    final scannedCount = currentUser?.scannedBoxes.length ?? 0;
    final completed    = bingoBoxes.where((b) => b.isSelected).length;

    if (_currentQuestionIndex != completed && !_showingQuestionMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentQuestionIndex = completed);
      });
    }

    final isDone = total > 0 && _currentQuestionIndex >= total;
    final hPad = MediaQuery.of(context).size.width < 400 ? 10.0 : 16.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, currentUser, scannedCount, total),
      body: Stack(
        children: [
          // CRT scanline background
          Positioned.fill(child: CustomPaint(painter: _ArcadeBgPainter())),

          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 6),

                  // ── Game title + score HUD ───────────────────────────
                  Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // NAMMA BINGO pixel title
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('NAMMA',
                                style: GoogleFonts.pressStart2p(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  fontSize: 8,
                                  letterSpacing: 2,
                                )),
                            Text('BINGO',
                                style: GoogleFonts.pressStart2p(
                                  color: AppColors.neonYellow,
                                  fontSize: 20,
                                  shadows: const [
                                    Shadow(color: AppColors.neonYellow, blurRadius: 18),
                                    Shadow(color: Color(0xFFFF9900), blurRadius: 30),
                                  ],
                                )),
                          ],
                        ),
                        const Spacer(),
                        // Score HUD
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currentUser?.name.split(' ').first.toUpperCase() ?? 'PLAYER 1',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 10,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.6), width: 1),
                                borderRadius: BorderRadius.circular(3),
                                color: AppColors.neonGreen.withValues(alpha: 0.08),
                              ),
                              child: Text(
                                '$scannedCount / $total',
                                style: GoogleFonts.pressStart2p(
                                  color: AppColors.neonGreen,
                                  fontSize: 10,
                                  shadows: [Shadow(color: AppColors.neonGreen.withValues(alpha: 0.7), blurRadius: 8)],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Progress bar ─────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 0),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: scannedCount / (total > 0 ? total : 1)),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOut,
                      builder: (_, v, __) => Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isDone ? '★ BINGO COMPLETE ★' : '${total - scannedCount} LEFT',
                                style: GoogleFonts.pressStart2p(
                                  color: isDone ? AppColors.neonYellow : Colors.white.withValues(alpha: 0.35),
                                  fontSize: 7,
                                ),
                              ),
                              Text(
                                '${(v * 100).toInt()}%',
                                style: TextStyle(
                                  color: isDone ? AppColors.neonYellow : AppColors.neonGreen,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: v,
                              backgroundColor: Colors.white.withValues(alpha: 0.07),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDone ? AppColors.neonYellow : AppColors.neonGreen,
                              ),
                              minHeight: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── Game board (card frame + BINGO header + grid) ────
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF08081C),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.neonYellow.withValues(alpha: 0.45),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.neonYellow.withValues(alpha: 0.07),
                            blurRadius: 30,
                            spreadRadius: 4,
                          ),
                          BoxShadow(
                            color: AppColors.neonPink.withValues(alpha: 0.04),
                            blurRadius: 60,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // B-I-N-G-O header row
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.neonYellow.withValues(alpha: 0.12),
                                  AppColors.neonYellow.withValues(alpha: 0.04),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.neonYellow.withValues(alpha: 0.25),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: const Row(
                              children: [
                                _ColHeader('B', AppColors.neonBlue),
                                _ColHeader('I', AppColors.neonPink),
                                _ColHeader('N', AppColors.neonGreen),
                                _ColHeader('G', AppColors.neonYellow),
                                _ColHeader('O', AppColors.neonPurple),
                              ],
                            ),
                          ),
                          // Grid
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: BingoGrid(
                              boxes: bingoBoxes,
                              onBoxTap: currentUser != null
                                  ? (boxId) {
                                      final box = bingoBoxes.firstWhere((b) => b.id == boxId);
                                      if (box.scannedBy != null &&
                                          currentUser.scannedBoxes.contains(boxId)) {
                                        _showPersonDetails(context, boxId);
                                      } else if (!currentUser.scannedBoxes.contains(boxId)) {
                                        context.go('/camera', extra: {'boxId': boxId});
                                      }
                                    }
                                  : null,
                              currentUser: currentUser,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Hint ─────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      'TAP BALL TO VIEW · TAP EMPTY TO SCAN',
                      style: GoogleFonts.pressStart2p(
                        color: Colors.white.withValues(alpha: 0.2),
                        fontSize: 6,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // ── Arcade scan button ───────────────────────────────
                  Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 20),
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (_, __) {
                        final p = _pulseAnimation.value;
                        final btnColor = isDone ? AppColors.neonGreen : AppColors.neonPink;
                        return GestureDetector(
                          onTap: currentUser != null
                              ? _showUnfilledQuestions
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Set up your profile before scanning'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  context.go('/profile');
                                },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: btnColor.withValues(alpha: 0.09 + 0.06 * p),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: btnColor, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: btnColor.withValues(alpha: 0.2 + 0.4 * p),
                                  blurRadius: 12 + 20 * p,
                                  spreadRadius: 1 + 3 * p,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isDone ? Icons.star_rounded : Icons.qr_code_scanner,
                                  color: btnColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  isDone ? '[ MISSION COMPLETE ]' : '[ SCAN  TO  CONNECT ]',
                                  style: GoogleFonts.pressStart2p(
                                    color: btnColor,
                                    fontSize: 9,
                                    shadows: [
                                      Shadow(
                                        color: btnColor.withValues(alpha: 0.6 + 0.4 * p),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, dynamic currentUser, int scanned, int total) {
    return AppBar(
      backgroundColor: AppColors.background.withValues(alpha: 0.95),
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => context.push('/profile'),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.neonPink.withValues(alpha: 0.6), width: 1.5),
              color: AppColors.neonPink.withValues(alpha: 0.1),
            ),
            child: ClipOval(
              child: currentUser?.profilePictureUrl != null
                  ? Image.network(
                      currentUser!.profilePictureUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _avatarPlaceholder(currentUser),
                    )
                  : _avatarPlaceholder(currentUser),
            ),
          ),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Image.network(
                'https://media.licdn.com/dms/image/v2/D560BAQHJALM_HLdjzg/company-logo_200_200/company-logo_200_200/0/1710185434227/nammaflutter_logo?e=1779926400&v=beta&t=OXTj9jG3myiQ53opFlHR94j8Obapxo0V7FWE8nwE5NA',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.neonPink.withValues(alpha: 0.2),
                  child: const Icon(Icons.groups, color: Colors.white54, size: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            AppTypography.scale(context, 14) > 12 ? 'NAMMA FLUTTER' : 'BINGO',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () => context.push('/profile'),
          icon: const Icon(Icons.settings_outlined, color: Colors.white54, size: 20),
        ),
      ],
    );
  }

  Widget _avatarPlaceholder(dynamic user) {
    final initial = (user?.name?.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'P';
    return Container(
      color: AppColors.neonPink.withValues(alpha: 0.1),
      child: Center(
        child: Text(initial,
            style: const TextStyle(color: AppColors.neonPink, fontSize: 14, fontWeight: FontWeight.w900)),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _ColHeader extends StatelessWidget {
  final String letter;
  final Color color;
  const _ColHeader(this.letter, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          letter,
          style: GoogleFonts.pressStart2p(
            color: color,
            fontSize: 13,
            shadows: [Shadow(color: color.withValues(alpha: 0.8), blurRadius: 10)],
          ),
        ),
      ),
    );
  }
}

// ── Background painter ────────────────────────────────────────────────────────

class _ArcadeBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scan = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.012)
      ..style = PaintingStyle.fill;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1.5), scan);
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
  bool shouldRepaint(covariant CustomPainter old) => false;
}
