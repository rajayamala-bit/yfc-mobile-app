import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class ShareModalWidget extends StatelessWidget {
  const ShareModalWidget({super.key});

  static const String meetUrl = "https://meet.google.com/vtu-qgxk-zrv";
  static const String appDownloadUrl = "https://play.google.com/store/apps/details?id=com.yfc.fellowship";
  
  static const String appShareMessage = 
      "✝️ Join Youth For Christ (YFC) Fellowship!\n\n"
      "🌅 Morning Prayer: Mon–Sat 5:00 AM - 5:30 AM IST\n"
      "📖 Evening Bible Study: Mon–Sat 9:00 PM - 10:00 PM IST\n\n"
      "🎥 Google Meet Link: $meetUrl\n"
      "📱 Download YFC App: $appDownloadUrl\n"
      "(Join global chat, bilingual quizzes, & Berean AI!)";

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const ShareModalWidget(),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Invite & Share YFC Fellowship ✨",
                  style: GoogleFonts.cinzel(
                    color: AppTheme.goldAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "✝️ Join Youth For Christ (YFC) Fellowship!\n\n"
                  "🌅 Morning Prayer: Mon–Sat 5:00 AM - 5:30 AM IST\n"
                  "📖 Evening Bible Study: Mon–Sat 9:00 PM - 10:00 PM IST\n",
                  style: TextStyle(color: AppTheme.textDark, fontSize: 13, height: 1.4),
                ),
                InkWell(
                  onTap: () => _openUrl(meetUrl),
                  child: const Text(
                    "🎥 Google Meet Link: $meetUrl",
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 13,
                      height: 1.4,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () => _openUrl(appDownloadUrl),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.goldAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.get_app_rounded, color: AppTheme.shiningRed, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "📱 Download YFC App to join global chat, bilingual quizzes, & Berean AI!",
                            style: TextStyle(
                              color: AppTheme.shiningRed,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Share.share(appShareMessage, subject: "YFC Youth Fellowship Invitation");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.shiningRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              icon: const Icon(Icons.share_rounded, color: Colors.white),
              label: const Text(
                "1-Tap Share to Fellowship Group",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
