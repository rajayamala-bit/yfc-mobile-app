import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class StatusCardGenerator extends StatefulWidget {
  final String verseReference;
  final String verseTextEn;
  final String verseTextTe;

  const StatusCardGenerator({
    super.key,
    required this.verseReference,
    required this.verseTextEn,
    required this.verseTextTe,
  });

  static void show(
    BuildContext context, {
    required String verseReference,
    required String verseTextEn,
    required String verseTextTe,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatusCardGenerator(
        verseReference: verseReference,
        verseTextEn: verseTextEn,
        verseTextTe: verseTextTe,
      ),
    );
  }

  @override
  State<StatusCardGenerator> createState() => _StatusCardGeneratorState();
}

class _StatusCardGeneratorState extends State<StatusCardGenerator> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _isExporting = false;

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareImagePoster() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        _shareFallbackText();
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        _shareFallbackText();
        return;
      }

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/yfc_status_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: "✝️ ${widget.verseReference}\n🎥 Join Live Meet: https://meet.google.com/vtu-qgxk-zrv\n📱 Download YFC App: https://play.google.com/store/apps/details?id=com.yfc.fellowship\nShared via YFC Youth Fellowship",
        subject: "YFC Daily Devotional Status Poster",
      );
    } catch (e) {
      _shareFallbackText();
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _shareFallbackText() {
    Share.share(
      "✝️ ${widget.verseReference}\n\nEnglish: ${widget.verseTextEn}\n\nతెలుగు: ${widget.verseTextTe}\n\n🎥 Join Live Meet: https://meet.google.com/vtu-qgxk-zrv\n📱 Download YFC App: https://play.google.com/store/apps/details?id=com.yfc.fellowship\nShared via YFC Youth Fellowship App",
      subject: "YFC Daily Devotional Status Card",
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgPrimaryDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.style_rounded, color: AppTheme.shiningRed, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      "9:16 Social Poster Generator",
                      style: GoogleFonts.cinzel(
                        color: AppTheme.goldAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // 9:16 RepaintBoundary Visual Poster Container
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    child: RepaintBoundary(
                      key: _repaintKey,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF8B0000), // Deep Crimson Red
                              Color(0xFF500000), // Dark Burgundy
                              Color(0xFF2B0000), // Midnight Maroon
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          border: Border.all(color: const Color(0xFFFFD700), width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(120),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Background Shining Gold Cross Watermark
                            const Positioned.fill(
                              child: Center(
                                child: Opacity(
                                  opacity: 0.12,
                                  child: Icon(
                                    Icons.add_rounded,
                                    size: 260,
                                    color: Color(0xFFFFD700),
                                  ),
                                ),
                              ),
                            ),

                            // Poster Content Body
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Top YFC Branding Header
                                  Column(
                                    children: [
                                      Container(
                                        width: 52,
                                        height: 52,
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                                          color: Colors.black.withAlpha(80),
                                        ),
                                        child: ClipOval(
                                          child: Image.asset(
                                            'assets/images/app_icon.png',
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.add_rounded,
                                                color: Color(0xFFFFD700),
                                                size: 32,
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "YOUTH FOR CHRIST",
                                        style: GoogleFonts.cinzel(
                                          color: const Color(0xFFFFD700),
                                          fontSize: 16,
                                          letterSpacing: 2.2,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "FELLOWSHIP DAILY SCRIPTURE",
                                        style: GoogleFonts.inter(
                                          color: Colors.white70,
                                          fontSize: 10,
                                          letterSpacing: 1.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Center Verses (English + Telugu BSI)
                                  Column(
                                    children: [
                                      // English Verse
                                      Text(
                                        "“${widget.verseTextEn}”",
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic,
                                          height: 1.45,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),

                                      // Telugu Verse
                                      Text(
                                        "“${widget.verseTextTe}”",
                                        style: GoogleFonts.notoSansTelugu(
                                          color: const Color(0xFFFFD700),
                                          fontSize: 14,
                                          height: 1.55,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 20),

                                      // Verse Citation Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFD700).withAlpha(40),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: const Color(0xFFFFD700), width: 1.2),
                                        ),
                                        child: Text(
                                          widget.verseReference,
                                          style: GoogleFonts.cinzel(
                                            color: const Color(0xFFFFD700),
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Footer Tagline, Clickable Meet Link & Download App Badge
                                  Column(
                                    children: [
                                      Container(
                                        height: 1,
                                        color: const Color(0xFFFFD700).withAlpha(80),
                                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                                      ),
                                      GestureDetector(
                                        onTap: () => _openUrl("https://meet.google.com/vtu-qgxk-zrv"),
                                        child: const Text(
                                          "Join Live Meet: meet.google.com/vtu-qgxk-zrv 🔗",
                                          style: TextStyle(
                                            color: Color(0xFF64B5F6),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        "YFC Bilingual Youth Prayer & Bible Engine",
                                        style: TextStyle(
                                          color: Color(0xFFFFD700),
                                          fontSize: 9,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      GestureDetector(
                                        onTap: () => _openUrl("https://play.google.com/store/apps/details?id=com.yfc.fellowship"),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFD700).withAlpha(40),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFFFFD700), width: 1),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.system_update_rounded, color: Color(0xFFFFD700), size: 12),
                                              SizedBox(width: 4),
                                              Text(
                                                "📲 Download YFC App",
                                                style: TextStyle(
                                                  color: Color(0xFFFFD700),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
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
              ),
            ),
          ),

          // Share Poster CTA Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : _shareImagePoster,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.shiningRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                icon: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                      )
                    : const Icon(Icons.share_rounded, color: Colors.white),
                label: Text(
                  _isExporting ? "Generating 9:16 Poster..." : "Share Poster to WhatsApp Status 📱",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
