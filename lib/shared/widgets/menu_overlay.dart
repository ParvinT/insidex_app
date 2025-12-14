// lib/shared/widgets/menu_overlay.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../core/themes/app_theme_extension.dart';
import '../../core/routes/app_routes.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/subscription_provider.dart';
import '../../features/subscription/paywall_screen.dart';
import 'upgrade_prompt.dart';

class MenuOverlay extends StatefulWidget {
  final VoidCallback onClose;

  const MenuOverlay({
    super.key,
    required this.onClose,
  });

  @override
  State<MenuOverlay> createState() => _MenuOverlayState();
}

class _MenuOverlayState extends State<MenuOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Close menu with animation and return Future
  Future<void> _closeMenu() async {
    await _animationController.reverse();
    widget.onClose();
  }

  /// Close menu and then navigate
  Future<void> _closeMenuAndNavigate(VoidCallback navigate) async {
    await _closeMenu();
    if (mounted) {
      navigate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Dark overlay
            GestureDetector(
              onTap: _closeMenu,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ),

            // Menu panel
            Align(
              alignment: Alignment.centerRight,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  width: 280.w,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: colors.backgroundElevated,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30.r),
                      bottomLeft: Radius.circular(30.r),
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Padding(
                          padding: EdgeInsets.all(24.w),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppLocalizations.of(context).menu,
                                style: GoogleFonts.inter(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                ),
                              ),
                              IconButton(
                                onPressed: _closeMenu,
                                icon: Icon(
                                  Icons.close,
                                  color: colors.textPrimary,
                                  size: 24.sp,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Divider(
                          color: colors.border,
                          thickness: 1,
                          height: 1,
                        ),

                        // Menu Items
                        // Menu Items
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.symmetric(vertical: 20.h),
                            children: [
                              // Premium/Subscription item
                              Consumer<SubscriptionProvider>(
                                builder: (context, subProvider, _) {
                                  if (subProvider.isActive) {
                                    // Premium user - show subscription info
                                    return _buildMenuItem(
                                      icon: Icons.workspace_premium,
                                      title: 'Your Subscription',
                                      iconColor: Colors.amber.shade700,
                                      onTap: () => _closeMenuAndNavigate(() {
                                        showManageSubscriptionSheet(context);
                                      }),
                                    );
                                  }
                                  // Free user - show upgrade
                                  return _buildMenuItem(
                                    icon: Icons.workspace_premium,
                                    title: 'Upgrade to Premium',
                                    iconColor: Colors.amber.shade700,
                                    onTap: () => _closeMenuAndNavigate(() {
                                      showPaywall(context);
                                    }),
                                  );
                                },
                              ),

                              // Divider
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24.w,
                                  vertical: 8.h,
                                ),
                                child: Divider(
                                  color: colors.border.withValues(alpha: 0.5),
                                  height: 1,
                                ),
                              ),

                              _buildMenuItem(
                                icon: Icons.person_outline,
                                title: AppLocalizations.of(context).profile,
                                onTap: () => _closeMenuAndNavigate(() {
                                  AppRoutes.navigateToProfile(context);
                                }),
                              ),
                              _buildMenuItem(
                                icon: Icons.settings_outlined,
                                title: AppLocalizations.of(context).settings,
                                onTap: () => _closeMenuAndNavigate(() {
                                  Navigator.pushNamed(
                                      context, AppRoutes.settings);
                                }),
                              ),
                            ],
                          ),
                        ),

                        // Bottom section
                        Divider(
                          color: colors.border,
                          thickness: 1,
                          height: 1,
                        ),

                        Padding(
                          padding: EdgeInsets.all(24.w),
                          child: Column(
                            children: [
                              // Version info
                              Text(
                                '${AppLocalizations.of(context).version} 1.0.0',
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w400,
                                  color: colors.textSecondary,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              // Logo instead of INSIDEX text
                              Container(
                                height: 24.h,
                                alignment: Alignment.center,
                                child: SvgPicture.asset(
                                  'assets/images/logo.svg',
                                  height: 24.h,
                                  fit: BoxFit.contain,
                                  colorFilter: ColorFilter.mode(
                                    colors.textPrimary.withValues(alpha: 0.8),
                                    BlendMode.srcIn,
                                  ),
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
          ],
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? colors.textPrimary,
              size: 24.sp,
            ),
            SizedBox(width: 16.w),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: iconColor ?? colors.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: colors.textSecondary,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }
}
