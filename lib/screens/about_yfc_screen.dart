import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_bubbles_background.dart';

class AboutYfcScreen extends StatelessWidget {
  const AboutYfcScreen({super.key});

  static const String appDownloadUrl = "https://play.google.com/store/apps/details?id=com.yfc.fellowship";
  static const String meetUrl = "https://meet.google.com/vtu-qgxk-zrv";
  static const String whatsappSupportUrl = "https://wa.me/9154300435?text=Hi%20YFC%20Support,%20I%20have%20an%20inquiry%20regarding%20the%20Fellowship%20app.";

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0B132B) : AppTheme.bgPrimaryLight;
    final appBarTitleColor = isDark ? AppTheme.goldAccent : const Color(0xFF000000);
    final heroTitleColor = isDark ? const Color(0xFFFFD700) : const Color(0xFF000000);
    final subtitleColor = isDark ? const Color(0xFFE0E0E0) : const Color(0xFF000000);
    final teluguSubtitleColor = isDark ? AppTheme.goldAccent : const Color(0xFF111111);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: isDark ? AppTheme.goldAccent : const Color(0xFF000000)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "ABOUT YFC FELLOWSHIP",
          style: GoogleFonts.cinzel(
            color: appBarTitleColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: FloatingBubblesBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Hero Emblem & Branding
              Container(
                width: 90,
                height: 90,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppTheme.shiningRed, Color(0xFFFFD700)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                      blurRadius: 28,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.add_rounded, size: 50, color: Colors.white),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                "YOUTH FOR CHRIST FELLOWSHIP",
                textAlign: TextAlign.center,
                style: GoogleFonts.cinzel(
                  color: heroTitleColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  shadows: isDark
                      ? [Shadow(color: const Color(0xFFFFD700).withValues(alpha: 0.5), blurRadius: 10)]
                      : null,
                ),
              ),
              const SizedBox(height: 6),

              Text(
                "Living in His Light • Growing in His Word",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: subtitleColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                "పరిశుద్ధ వాక్యములో ఎదుగుతూ...",
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansTelugu(
                  color: teluguSubtitleColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // CTA Action Button Group
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openUrl(appDownloadUrl),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.shiningRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                      icon: const Icon(Icons.get_app_rounded, size: 18),
                      label: const Text(
                        "Download App",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openUrl(meetUrl),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? AppTheme.goldAccent : const Color(0xFF000000),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: isDark ? AppTheme.goldAccent : AppTheme.shiningRed,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.video_call_rounded, size: 18),
                      label: const Text(
                        "Join Live Meet",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Fellowship Timings Section
              _buildSectionTitle("✨ DAILY FELLOWSHIP RHYTHM", isDark: isDark),
              const SizedBox(height: 12),
              _buildTimingCard(
                badgeText: "MORNING PRAYER",
                badgeColor: AppTheme.shiningRed,
                timeText: "5:00 AM – 5:30 AM IST",
                description: "Monday – Saturday • Live Google Meet Devotional, intercessory prayer & morning blessings.",
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildTimingCard(
                badgeText: "EVENING BIBLE STUDY",
                badgeColor: isDark ? AppTheme.goldAccent : AppTheme.shiningRed,
                timeText: "9:00 PM – 10:00 PM IST",
                description: "Monday – Saturday • Verse-by-verse bilingual study, group discussion & nightly champions quiz.",
                isDark: isDark,
              ),
              const SizedBox(height: 32),

              // 5 Core Pillars Section
              _buildSectionTitle("🌟 FIVE CORE PILLARS", isDark: isDark),
              const SizedBox(height: 12),
              _buildPillarTile(
                icon: "💬",
                title: "Global Bilingual Chat",
                description: "Connect with fellowship members globally with instant audio prayers, photo/video testimonials, and daily encouragement.",
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildPillarTile(
                icon: "🤖",
                title: "Berean AI Scripture Scholar",
                description: "Ask complex biblical questions and receive doctrinally sound, chapter-and-verse grounded answers instantaneously.",
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildPillarTile(
                icon: "🎨",
                title: "Daily Poster Generator",
                description: "Export high-resolution 9:16 social posters of daily verses with one tap directly to WhatsApp status in Telugu & English.",
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildPillarTile(
                icon: "🏆",
                title: "Daily Champions Quiz",
                description: "Gamified scripture recall based on nightly study with interactive leaderboards, streak tracking, and podium medals.",
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildPillarTile(
                icon: "📖",
                title: "Telugu, English & Interlinear Bible",
                description: "Complete 66-book canonical suite featuring Telugu (BSI), English (KJV), and Strong's Hebrew & Greek Interlinear concordances with custom font scaling and offline instant access.",
                isDark: isDark,
              ),
              const SizedBox(height: 32),

              // Footer & Support Line
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFFFF0F2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppTheme.goldAccent.withValues(alpha: 0.3) : AppTheme.goldAccent.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      "Youth For Christ (YFC) Fellowship",
                      style: GoogleFonts.cinzel(
                        color: isDark ? AppTheme.goldAccent : const Color(0xFF000000),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Transforming Youth Through Christ",
                      style: TextStyle(
                        color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF111111),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () => _openUrl(whatsappSupportUrl),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.shiningRed, // Ruby Crimson #D90429
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      icon: const Icon(Icons.headset_mic_rounded, size: 18),
                      label: const Text(
                        "Contact Support",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {required bool isDark}) {
    return Text(
      title,
      style: GoogleFonts.cinzel(
        color: isDark ? AppTheme.goldAccent : const Color(0xFF000000),
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTimingCard({
    required String badgeText,
    required Color badgeColor,
    required String timeText,
    required String description,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFFFF0F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppTheme.goldAccent.withValues(alpha: 0.35) : AppTheme.shiningRed.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
            ),
            child: Text(
              badgeText,
              style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            timeText,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF000000),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF111111),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarTile({
    required String icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFFFF0F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.goldAccent.withValues(alpha: 0.3) : AppTheme.shiningRed.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? AppTheme.goldAccent : const Color(0xFF000000),
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF111111),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
