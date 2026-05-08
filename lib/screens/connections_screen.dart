import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_providers.dart';
import '../const/app_colors.dart';
import '../utils/typography_utils.dart';

class ConnectionsScreen extends ConsumerWidget {
  const ConnectionsScreen({super.key});

  Future<void> _launchLinkedIn(String linkedInUrl) async {
    try {
      final uri = Uri.parse(linkedInUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Error handled silently for web compatibility
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bingoBoxes = ref.watch(bingoBoxesProvider);
    final currentUser = ref.watch(currentUserProvider);
    
    // Get connections that the current user scanned (their connections)
    final connections = bingoBoxes
        .where((box) => 
            currentUser?.scannedBoxes.contains(box.id) == true && 
            box.scannedByName != null
        )
        .toList();

    // Check if bingo is completed (all boxes scanned)
    final totalQuestions = ref.watch(bingoBoxesProvider.notifier).questionsCount;
    final isBingoCompleted = currentUser?.scannedBoxes.length == totalQuestions;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Bingo Connections',
          style: AppTypography.h2(context),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryBlue,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people, color: AppColors.lightCyan, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${connections.length}/$totalQuestions',
                  style: AppTypography.label(context, color: AppColors.lightCyan),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bingo Completion Banner
                if (isBingoCompleted)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.emoji_events, color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BINGO MASTER!',
                                style: AppTypography.h3(context, fontWeight: FontWeight.w900),
                              ),
                              Text(
                                'You\'ve connected with $totalQuestions people!',
                                style: AppTypography.bodySmall(context, color: Colors.white.withOpacity(0.9)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Stats Card
                Container(
                  padding: const EdgeInsets.all(24),
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
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.network_check,
                              size: 24,
                              color: AppColors.lightCyan,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Network',
                                  style: AppTypography.h3(context),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  connections.isEmpty
                                      ? 'Start scanning to build your network'
                                      : 'People you\'ve connected with',
                                  style: AppTypography.bodySmall(context, color: Colors.white.withOpacity(0.7)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Progress Bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progress: ${connections.length}/$totalQuestions',
                                style: AppTypography.bodySmall(context, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${totalQuestions > 0 ? ((connections.length / totalQuestions) * 100).toInt() : 0}%',
                                style: AppTypography.bodySmall(context, color: AppColors.lightCyan, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                            Container(
                            width: double.infinity,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: totalQuestions > 0 ? connections.length / totalQuestions : 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Section Title
                if (connections.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      '${connections.length} Connection${connections.length == 1 ? '' : 's'}',
                      style: AppTypography.h3(context, color: AppColors.lightCyan),
                    ),
                  ),

                // Connections List
                Expanded(
                  child: connections.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Center(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBlue.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.qr_code_scanner,
                                      size: 48,
                                      color: AppColors.lightCyan,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No connections yet',
                                    style: AppTypography.h3(context),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Start scanning QR codes to build your network',
                                    style: AppTypography.bodySmall(context, color: Colors.white.withOpacity(0.7)),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: connections.length,
                          itemBuilder: (context, index) {
                            final connection = connections[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.lightCyan.withOpacity(0.5),
                                        width: 2,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: _isValidUrl(connection.scannedByProfilePicture)
                                          ? Image.network(
                                              connection.scannedByProfilePicture!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  Center(
                                                child: Text(
                                                  connection.scannedByName?[0].toUpperCase() ?? '?',
                                                  style: const TextStyle(color: AppColors.lightCyan, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            )
                                          : Center(
                                              child: Text(
                                                connection.scannedByName?[0].toUpperCase() ?? '?',
                                                style: const TextStyle(color: AppColors.lightCyan, fontWeight: FontWeight.bold),
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
                                          connection.scannedByName ?? 'Unknown',
                                          style: AppTypography.bodyMedium(context, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          'Connected on ${connection.scannedAt?.day ?? ''}/${connection.scannedAt?.month ?? ''} at ${connection.scannedAt?.hour.toString().padLeft(2, '0') ?? ''}:${connection.scannedAt?.minute.toString().padLeft(2, '0') ?? ''}',
                                          style: AppTypography.caption(context, color: Colors.white54),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (connection.scannedByLinkedIn != null && connection.scannedByLinkedIn!.isNotEmpty)
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: AppColors.primaryGradient,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(12),
                                          onTap: () => _launchLinkedIn(connection.scannedByLinkedIn!),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.launch, size: 16, color: Colors.white),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'CONNECT',
                                                  style: AppTypography.label(context, color: Colors.white, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.1),
                                        ),
                                      ),
                                      child: Text(
                                        'NO LINK',
                                        style: AppTypography.label(context, color: Colors.white.withOpacity(0.5)),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
}