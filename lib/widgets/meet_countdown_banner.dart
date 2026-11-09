import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/alarm_service.dart';
import '../theme/app_theme.dart';

class MeetCountdownBanner extends StatefulWidget {
  const MeetCountdownBanner({super.key});

  @override
  State<MeetCountdownBanner> createState() => _MeetCountdownBannerState();
}

class _MeetCountdownBannerState extends State<MeetCountdownBanner> {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceCardDark : AppTheme.surfaceCardLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shiningRed.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Status dot, Title + Subtext underneath, and LIVE MEET Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppTheme.statusGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appState.nextFellowshipMainTitle,
                        style: AppTheme.getScriptTextStyle(
                          isTelugu: appState.isTelugu,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.textLight : AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        appState.nextFellowshipTimeSubtext,
                        style: TextStyle(
                          color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.shiningRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.shiningRed.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    appState.isTelugu ? "ప్రత్యక్షం" : "LIVE MEET",
                    style: const TextStyle(
                      color: AppTheme.shiningRed,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Digital Timer on Left & Join Meet Button on Right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  appState.formattedCountdownTime,
                  style: const TextStyle(
                    color: AppTheme.shiningRed,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    fontFeatures: [FontFeature.tabularFigures()],
                    letterSpacing: 1.5,
                  ),
                ),

                ElevatedButton.icon(
                  onPressed: () => AlarmService.launchGoogleMeet(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.shiningRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.video_call_rounded, size: 20, color: Colors.white),
                  label: Text(
                    appState.isTelugu ? "జాయిన్ అవ్వండి" : "Join Meet",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
