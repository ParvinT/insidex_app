// lib/features/player/widgets/player_modals.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/audio_player_service.dart';

class PlayerModals {
  static void showSleepTimer(
    BuildContext context,
    int? currentTimer,
    AudioPlayerService audioService,
    Function(int?) onTimerSet,
  ) {
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
                  'Sleep Timer',
                  style: GoogleFonts.inter(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8.h),
                if (currentTimer != null)
                  Text(
                    'Active: $currentTimer minutes',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: Colors.greenAccent,
                    ),
                  ),
                SizedBox(height: 24.h),
                Wrap(
                  spacing: 12.w,
                  runSpacing: 12.h,
                  children: [15, 30, 45, 60, 90, 120].map((minutes) {
                    final isSelected = currentTimer == minutes;
                    return ChoiceChip(
                      label: Text(
                        '$minutes min',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          audioService.setSleepTimer(minutes);
                          onTimerSet(minutes);
                          setModalState(() {});

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Sleep timer set to $minutes minutes'),
                              duration: const Duration(seconds: 2),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          audioService.cancelSleepTimer();
                          onTimerSet(null);
                          setModalState(() {});
                        }
                        Navigator.pop(context);
                      },
                      backgroundColor: Colors.grey[800],
                      selectedColor: Colors.greenAccent.withOpacity(0.3),
                      checkmarkColor: Colors.greenAccent,
                      side: BorderSide(
                        color:
                            isSelected ? Colors.greenAccent : Colors.grey[700]!,
                        width: isSelected ? 2 : 1,
                      ),
                    );
                  }).toList(),
                ),
                if (currentTimer != null) ...[
                  SizedBox(height: 16.h),
                  TextButton.icon(
                    onPressed: () {
                      audioService.cancelSleepTimer();
                      onTimerSet(null);
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sleep timer cancelled'),
                          duration: Duration(seconds: 2),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                    icon: const Icon(Icons.cancel, color: Colors.redAccent),
                    label: const Text(
                      'Cancel Timer',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
                SizedBox(height: 20.h),
              ],
            ),
          );
        },
      ),
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
                  const SnackBar(content: Text('Premium feature')),
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