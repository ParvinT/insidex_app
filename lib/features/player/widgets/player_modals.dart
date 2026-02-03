// lib/features/player/widgets/player_modals.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/audio/audio_player_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/themes/app_theme_extension.dart';

class PlayerModals {
  // PlayerModals.showSleepTimer — shows current value, lets select & cancel
  static void showSleepTimer(
    BuildContext context,
    int? currentMinutes,
    AudioPlayerService audioService,
    ValueChanged<int?> onChanged,
  ) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.backgroundElevated,
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
                      color: colors.textPrimary,
                    )),
                const SizedBox(height: 8),
                Text(
                  selected != null
                      ? AppLocalizations.of(context)
                          .currentMinutes(selected.toString())
                      : AppLocalizations.of(context).noTimerSet,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: colors.textSecondary,
                  ),
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
                        selectedColor: colors.textPrimary,
                        backgroundColor: colors.greyLight,
                        labelStyle: GoogleFonts.inter(
                          color: selected == m
                              ? colors.textOnPrimary
                              : colors.textPrimary,
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
                            foregroundColor: colors.textPrimary,
                            side: BorderSide(color: colors.textPrimary),
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
                          backgroundColor: colors.textPrimary,
                          foregroundColor: colors.textOnPrimary,
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
}
