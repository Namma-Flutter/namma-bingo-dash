import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../const/app_colors.dart';
import '../theme/app_text_styles.dart';

class ShellScreen extends ConsumerStatefulWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  int _selectedIndex = 0;

  void _onTap(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0: { context.go('/'); } break;
      case 1: { context.go('/connections'); } break;
      case 2: { context.go('/qr-generator'); } break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    if (path == '/') {
      _selectedIndex = 0;
    } else if (path == '/connections') {
      _selectedIndex = 1;
    } else if (path == '/qr-generator') {
      _selectedIndex = 2;
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.96),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.06),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 58,
                child: Row(
                  children: [
                    _NavTab(icon: Icons.grid_view_rounded,  label: 'GRID',  index: 0, selected: _selectedIndex == 0, onTap: _onTap),
                    _NavTab(icon: Icons.people_rounded,     label: 'CREW',  index: 1, selected: _selectedIndex == 1, onTap: _onTap),
                    _NavTab(icon: Icons.qr_code_rounded,   label: 'QR-ID', index: 2, selected: _selectedIndex == 2, onTap: _onTap),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final bool selected;
  final void Function(int) onTap;

  const _NavTab({
    required this.icon,
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final col = selected ? AppColors.neonPink : Colors.white.withValues(alpha: 0.28);

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Neon top-bar indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: selected ? 28 : 0,
              height: 2,
              margin: const EdgeInsets.only(bottom: 5),
              decoration: BoxDecoration(
                color: AppColors.neonPink,
                borderRadius: BorderRadius.circular(1),
                boxShadow: selected
                    ? [BoxShadow(color: AppColors.neonPink.withValues(alpha: 0.9), blurRadius: 8)]
                    : null,
              ),
            ),
            Icon(icon, color: col, size: 19),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.pixel(
                size: 6,
                color: col,
                shadows: selected
                    ? [Shadow(color: AppColors.neonPink.withValues(alpha: 0.9), blurRadius: 6)]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
