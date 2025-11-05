// lib/features/player/widgets/player_modals.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/audio_player_service.dart';
import '../../../l10n/app_localizations.dart';

class PlayerModals {
  // PlayerModals.showSleepTimer — shows current value, lets select & cancel
  static void showSleepTimer(
    BuildContext context,
    int? currentMinutes,
    AudioPlayerService audioService,
    ValueChanged<int?> onChanged,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        int? selected = currentMinutes;
        final options = <int>[5, 10, 15, 20, 30, 45];

        return StatefulBuilder(builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context).sleepTimer,
                    style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black)),
                const SizedBox(height: 8),
                Text(
                  selected != null
                      ? AppLocalizations.of(context)
                          .currentMinutes(selected.toString())
                      : AppLocalizations.of(context).noTimerSet,
                  style:
                      GoogleFonts.inter(fontSize: 13, color: Color(0xFF6E6E6E)),
                ),
                const SizedBox(height: 16),

                // minute chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final m in options)
                      ChoiceChip(
                        label: Text(AppLocalizations.of(context)
                            .setMinutes(m.toString())),
                        selected: selected == m,
                        onSelected: (_) => setState(() => selected = m),
                        selectedColor: Colors.black,
                        backgroundColor: const Color(0xFFF5F5F5),
                        labelStyle: GoogleFonts.inter(
                          color: selected == m
                              ? Colors.white
                              : const Color(0xFF333333),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),
                Row(
                  children: [
                    if (currentMinutes != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await audioService.cancelSleepTimer();
                            onChanged(null);
                            if (context.mounted) Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black,
                            side: const BorderSide(color: Colors.black),
                          ),
                          child: Text(AppLocalizations.of(context).cancelTimer),
                        ),
                      ),
                    if (currentMinutes != null) const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: selected == null
                            ? null
                            : () async {
                                await audioService.setSleepTimer(selected!);
                                onChanged(selected);
                                if (context.mounted) Navigator.pop(context);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(selected == null
                            ? AppLocalizations.of(context).set
                            : AppLocalizations.of(context)
                                .setMinutes(selected.toString())),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
      },
    );
  }

  static void showVolumeControl(
    BuildContext context,
    double currentVolume,
    AudioPlayerService audioService,
    Function(double) onVolumeChanged,
  ) {
    double tempVolume = currentVolume;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Volume Control',
                  style: GoogleFonts.inter(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Icon(
                      tempVolume == 0 ? Icons.volume_off : Icons.volume_down,
                      color: Colors.white70,
                      size: 24.sp,
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 4.h,
                          thumbShape:
                              RoundSliderThumbShape(enabledThumbRadius: 10.r),
                          overlayShape:
                              RoundSliderOverlayShape(overlayRadius: 20.r),
                          activeTrackColor: Colors.greenAccent,
                          inactiveTrackColor: Colors.grey[700],
                          thumbColor: Colors.greenAccent,
                          overlayColor: Colors.greenAccent.withOpacity(0.2),
                        ),
                        child: Slider(
                          value: tempVolume,
                          min: 0.0,
                          max: 1.0,
                          divisions: 20,
                          onChanged: (value) {
                            setModalState(() {
                              tempVolume = value;
                            });
                            onVolumeChanged(value);
                            audioService.setVolume(value);
                          },
                        ),
                      ),
                    ),
                    Icon(
                      tempVolume > 0.7 ? Icons.volume_up : Icons.volume_down,
                      color: Colors.white70,
                      size: 24.sp,
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    '${(tempVolume * 100).round()}%',
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.greenAccent,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                // Quick volume presets
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [0.0, 0.25, 0.5, 0.75, 1.0].map((preset) {
                    return TextButton(
                      onPressed: () {
                        setModalState(() {
                          tempVolume = preset;
                        });
                        onVolumeChanged(preset);
                        audioService.setVolume(preset);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: tempVolume == preset
                            ? Colors.greenAccent.withOpacity(0.2)
                            : Colors.grey[800],
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 8.h),
                      ),
                      child: Text(
                        '${(preset * 100).round()}%',
                        style: TextStyle(
                          color: tempVolume == preset
                              ? Colors.greenAccent
                              : Colors.white70,
                          fontWeight: tempVolume == preset
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 20.h),
              ],
            ),
          );
        },
      ),
    );
  }

  static void showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.white70),
              title: const Text(
                'Session Info',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                // Show session details
              },
            ),
            ListTile(
              leading: const Icon(Icons.download, color: Colors.white70),
              title: const Text(
                'Download for Offline',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text(AppLocalizations.of(context).premiumFeature)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_problem, color: Colors.white70),
              title: const Text(
                'Report Issue',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                // Report issue
              },
            ),
          ],
        ),
      ),
    );
  }
}
