import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../const/app_colors.dart';
import '../utils/typography_utils.dart';

class ShellScreen extends ConsumerStatefulWidget {
  final Widget child;
  
  const ShellScreen({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/connections');
        break;
      case 2:
        context.go('/qr-generator');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Update selected index based on current route
    final String location = GoRouterState.of(context).uri.path;
    if (location == '/') {
      _selectedIndex = 0;
    } else if (location == '/connections') {
      _selectedIndex = 1;
    } else if (location == '/qr-generator') {
      _selectedIndex = 2;
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(
                      icon: Icons.grid_view_rounded,
                      label: 'Grid',
                      index: 0,
                      isSelected: _selectedIndex == 0,
                    ),
                    _buildNavItem(
                      icon: Icons.people_outline,
                      label: 'Network',
                      index: 1,
                      isSelected: _selectedIndex == 1,
                    ),
                    _buildNavItem(
                      icon: Icons.qr_code_rounded,
                      label: 'QR Code',
                      index: 2,
                      isSelected: _selectedIndex == 2,
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

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected 
              ? AppColors.primaryBlue.withOpacity(0.1) 
              : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected 
                  ? AppColors.lightCyan 
                  : Colors.white.withOpacity(0.4),
                size: isSelected ? 22 : 18,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTypography.label(context, 
                  color: isSelected ? AppColors.lightCyan : Colors.white.withOpacity(0.4), 
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
              if (isSelected)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.lightCyan,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}