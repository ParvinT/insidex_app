// lib/features/offline/offline_mode_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../downloads/downloads_screen.dart';
import '../../core/themes/app_theme_extension.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/download_provider.dart';
import '../../core/routes/app_routes.dart';

/// Offline mode screen shown when user opens app without internet
/// but has previously logged in
class OfflineModeScreen extends StatefulWidget {
  const OfflineModeScreen({super.key});

  @override
  State<OfflineModeScreen> createState() => _OfflineModeScreenState();
}

class _OfflineModeScreenState extends State<OfflineModeScreen> {
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _initializeForOffline();
  }

  Future<void> _initializeForOffline() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedUserId = prefs.getString('cached_user_id');

      if (cachedUserId != null && cachedUserId.isNotEmpty) {
        debugPrint(
          '📥 [OfflineMode] Found cached user ID, initializing provider...',
        );
        if (mounted) {
          await context.read<DownloadProvider>().initializeForOffline(
                cachedUserId,
              );
          debugPrint(
            '✅ [OfflineMode] Provider initialized for offline playback',
          );
        }
      } else {
        debugPrint('⚠️ [OfflineMode] No cached user ID found');
      }
    } catch (e) {
      debugPrint('❌ [OfflineMode] Initialization error: $e');
    }
  }

  Future<void> _retryConnection() async {
    setState(() => _isRetrying = true);

    final downloadProvider = context.read<DownloadProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final stillOfflineText = AppLocalizations.of(context).stillOffline;

    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = !connectivityResult.contains(ConnectivityResult.none);

    if (!mounted) return;

    if (isOnline) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedUserId = prefs.getString('cached_user_id');

        if (cachedUserId != null && cachedUserId.isNotEmpty) {
          debugPrint('🔄 [OfflineMode] Switching to online mode...');
          await downloadProvider.reinitializeForOnline(
            cachedUserId,
          );
          debugPrint('✅ [OfflineMode] Provider switched to online mode');
        }
      } catch (e) {
        debugPrint('⚠️ [OfflineMode] Reinitialize error: $e');
      }

      if (!mounted) return;

      // Internet restored, restart app flow
      navigator.pushReplacementNamed(AppRoutes.splash);
    } else {
      setState(() => _isRetrying = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(stillOfflineText),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Offline icon
              Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  color: colors.greyLight.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_off_rounded,
                  size: 60.sp,
                  color: colors.textSecondary,
                ),
              ),

              SizedBox(height: 32.h),

              // Title
              Text(
                l10n.youAreOffline,
                style: GoogleFonts.inter(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 12.h),

              // Subtitle
              Text(
                l10n.offlineDescription,
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  color: colors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 48.h),

              // Go to Downloads button
              SizedBox(
                width: double.infinity,
                height: 56.h.clamp(52.0, 64.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DownloadsScreen(),
                      ),
                    );
                  },
                  icon: Icon(Icons.download_rounded, size: 22.sp),
                  label: Text(
                    l10n.goToDownloads,
                    style: GoogleFonts.inter(
                      fontSize: 16.sp.clamp(14.0, 18.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.textPrimary,
                    foregroundColor: colors.textOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    elevation: 0,
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              // Retry button
              SizedBox(
                width: double.infinity,
                height: 56.h.clamp(52.0, 64.0),
                child: OutlinedButton.icon(
                  onPressed: _isRetrying ? null : _retryConnection,
                  icon: _isRetrying
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colors.textPrimary,
                            ),
                          ),
                        )
                      : Icon(Icons.refresh_rounded, size: 22.sp),
                  label: Text(
                    _isRetrying ? l10n.checking : l10n.tryAgain,
                    style: GoogleFonts.inter(
                      fontSize: 16.sp.clamp(14.0, 18.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textPrimary,
                    side: BorderSide(
                      color: colors.textPrimary.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
