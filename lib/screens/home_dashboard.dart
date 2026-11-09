import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_state.dart';
import '../services/alarm_service.dart';
import '../services/content_service.dart';
import '../theme/app_theme.dart';
import '../widgets/berean_ai_widget.dart';
import '../widgets/bible_reader_widget.dart';
import '../widgets/global_chat_widget.dart';
import '../widgets/meet_countdown_banner.dart';
import '../widgets/quiz_podium_widget.dart';
import '../widgets/share_modal_widget.dart';
import '../widgets/status_card_generator.dart';
import '../widgets/ot_bible_study_explorer.dart';
import '../widgets/floating_bubbles_background.dart';
import '../widgets/app_drawer.dart';
import '../widgets/whats_new_carousel.dart';
import 'registration_screen.dart';
import 'members_directory_screen.dart';
import 'notifications_screen.dart';
import 'about_yfc_screen.dart';
import 'admin_study_screen.dart';
import '../services/notification_service.dart';

import 'dart:async';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription? _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    _initSharingIntent();
    NotificationService.onNotificationTap = (payload) {
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        appState.setNavIndex(1);
      }
    };
  }

  void _initSharingIntent() {
    final appState = Provider.of<AppState>(context, listen: false);

    // Stream for incoming shared media while app is running
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedFiles(value, appState);
      }
    }, onError: (_) {});

    // Initial media when app was launched via share sheet
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedFiles(value, appState);
        ReceiveSharingIntent.instance.reset();
      }
    });
  }

  void _handleSharedFiles(List<SharedMediaFile> files, AppState appState) {
    for (final file in files) {
      if (file.type == SharedMediaType.video ||
          file.path.endsWith('.mp4') ||
          file.path.endsWith('.mkv') ||
          file.path.endsWith('.mov') ||
          file.path.endsWith('.avi') ||
          file.path.endsWith('.3gp') ||
          file.path.endsWith('.webm')) {
        appState.setPendingSharedContent(videoPath: file.path);
      } else if (file.type == SharedMediaType.image ||
          file.path.endsWith('.jpg') ||
          file.path.endsWith('.png') ||
          file.path.endsWith('.jpeg') ||
          file.path.endsWith('.gif') ||
          file.path.endsWith('.webp')) {
        appState.setPendingSharedContent(imagePath: file.path);
      } else {
        appState.setPendingSharedContent(text: file.path);
      }
    }
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
    super.dispose();
  }

  static String _getUserInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return "YFC";
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  static Widget _buildUserAvatarWidget(AppState appState, {double radius = 18}) {
    final avatarUrl = appState.avatarUrl;
    if (avatarUrl.isNotEmpty) {
      ImageProvider imageProvider;
      if (avatarUrl.startsWith('http')) {
        imageProvider = NetworkImage(avatarUrl);
      } else {
        imageProvider = FileImage(File(avatarUrl));
      }
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppTheme.shiningRed,
        backgroundImage: imageProvider,
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.shiningRed,
      child: Text(
        _getUserInitials(appState.activeUserName),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.65,
        ),
      ),
    );
  }

  Widget _buildColorfulBibleIcon({bool isActive = false}) {
    return Container(
      width: 25,
      height: 25,
      decoration: BoxDecoration(
        color: const Color(0xFF5E0B1B), // Royal Deep Burgundy Cover
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: isActive ? const Color(0xFFFFD700) : const Color(0xFFE0C068),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? const Color(0xFFFFD700).withValues(alpha: 0.6)
                : const Color(0xFFD90429).withValues(alpha: 0.3),
            blurRadius: isActive ? 8 : 4,
            spreadRadius: isActive ? 1.5 : 0,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: 1,
            top: 2,
            bottom: 2,
            child: Container(
              width: 2.2,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          const Icon(
            Icons.add_rounded,
            color: Color(0xFFFFD700),
            size: 14,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isTelugu = appState.isTelugu;

    final List<Widget> navScreens = [
      const DashboardFeedTab(),
      const GlobalChatWidget(),
      const BibleReaderWidget(),
      const QuizPodiumWidget(),
      const BereanAiWidget(),
    ];

    return PopScope(
      canPop: appState.currentNavIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (appState.currentNavIndex != 0) {
          appState.setNavIndex(0);
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppTheme.bgPrimary,
        endDrawer: AppDrawer(
          onMenuSelected: (val) => _handleMenuAction(context, val, appState),
        ),
        appBar: AppBar(
          elevation: 0,
          centerTitle: false,
          titleSpacing: 16,
          title: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutYfcScreen()),
                ),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.goldAccent, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD90429).withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => const Icon(
                        Icons.church_rounded,
                        color: AppTheme.goldAccent,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "YOUTH FOR CHRIST",
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.normal,
                      fontSize: 15,
                      letterSpacing: 1.2,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                  Text(
                    "EACH ONE CATCH ONE",
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.normal,
                      fontSize: 9.5,
                      letterSpacing: 1.5,
                      color: Color(0xFFD90429), // Ruby Crimson accent
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            // Right Side: Clean menu/hamburger icon triggering slide-out AppDrawer
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppTheme.goldAccent, size: 28),
              tooltip: 'Open Menu',
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: FloatingBubblesBackground(
          child: IndexedStack(
            index: appState.currentNavIndex,
            children: navScreens,
          ),
        ),
        bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 4, right: 4, bottom: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(35),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF8B0000), // Deep Ruby Red (#8B0000)
                Color(0xFFB7092B), // Rich Crimson Red
                Color(0xFFD90429), // Radiant Red (#D90429)
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            border: Border.all(
              color: const Color(0xFFD4AF37), // Perimeter Gold Border
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B0000).withValues(alpha: 0.35),
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: BottomNavigationBar(
              currentIndex: appState.currentNavIndex,
              onTap: appState.setNavIndex,
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFFD4AF37), // Polished Metallic Gold
              unselectedItemColor: Colors.white, // Crisp White
              selectedFontSize: 9.5,
              unselectedFontSize: 9.5,
              selectedLabelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 9.5,
                letterSpacing: -0.3,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 9.5,
                letterSpacing: -0.3,
              ),
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home_rounded, color: Colors.white),
                  activeIcon: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.home_rounded, color: Color(0xFFD4AF37)),
                  ),
                  label: isTelugu ? "హోమ్" : "Home",
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white),
                  activeIcon: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.chat_bubble_rounded, color: Color(0xFFD4AF37)),
                  ),
                  label: isTelugu ? "చాట్" : "Chat",
                ),
                BottomNavigationBarItem(
                  icon: _buildColorfulBibleIcon(isActive: false),
                  activeIcon: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: _buildColorfulBibleIcon(isActive: true),
                  ),
                  label: isTelugu ? "బైబిల్" : "Bible",
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.emoji_events_rounded, color: Colors.white),
                  activeIcon: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFD4AF37)),
                  ),
                  label: isTelugu ? "ఛాంపియన్స్" : "Champions",
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
                  activeIcon: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFD4AF37)),
                  ),
                  label: isTelugu ? "బెరియన్" : "Berean",
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  void _handleMenuAction(BuildContext context, String value, AppState appState) {
    switch (value) {
      case "MEMBERS":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MembersDirectoryScreen()),
        );
        break;
      case "NOTIFICATIONS":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
        break;
      case "PROFILE":
        _showProfileModal(context, appState);
        break;
      case "ABOUT_YFC":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AboutYfcScreen()),
        );
        break;
      case "ALARM":
        _showAlarmModal(context, appState);
        break;
      case "SHARE":
        ShareModalWidget.show(context);
        break;
      case "SUPPORT":
        _showSupportTicketDialog(context, appState);
        break;
      case "ADMIN_STUDY":
        if (appState.isAdmin) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminStudyScreen()),
          );
        } else {
          _showAdminPinDialog(context, appState);
        }
        break;
      case "SETTINGS":
        _showSettingsModal(context, appState);
        break;
    }
  }

  static void _showAdminPinDialog(BuildContext context, AppState appState) {
    final isDark = appState.isDarkMode;
    final isTelugu = appState.isTelugu;
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.surfaceCardDark : AppTheme.surfaceCardLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.goldAccent, width: 1.2),
          ),
          title: Row(
            children: [
              const Icon(Icons.security_rounded, color: AppTheme.shiningRed, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isTelugu ? "పాస్టర్ అడ్మిన్ పిన్ ఎంటర్ చేయండి" : "Enter Admin Portal Security PIN",
                  style: GoogleFonts.cinzel(
                    color: AppTheme.goldAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isTelugu ? "అడ్మిన్ యాక్సెస్ పిన్ (డిఫాల్ట్: 7777):" : "Enter Leader Access PIN (Default PIN: 7777):",
                style: TextStyle(color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                style: TextStyle(color: isDark ? AppTheme.textLight : AppTheme.textDark, fontSize: 18, letterSpacing: 4),
                decoration: InputDecoration(
                  hintText: "7777",
                  filled: true,
                  fillColor: isDark ? AppTheme.bgPrimaryDark : const Color(0xFFFFF5F6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isTelugu ? "రద్దు" : "Cancel", style: const TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                if (pinController.text.trim() == "7777" || pinController.text.trim() == "1234") {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminStudyScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.red,
                      content: Text("Incorrect PIN. Access Denied (Default PIN: 7777)"),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.shiningRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isTelugu ? "ప్రవేశించండి" : "Enter Portal", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  static void _showSupportTicketDialog(BuildContext context, AppState appState) {
    final isDark = appState.isDarkMode;
    final isTelugu = appState.isTelugu;

    final nameToUse = (appState.activeUserName.isNotEmpty && appState.activeUserName != "YFC Member")
        ? appState.activeUserName
        : "Fellowship Member";
    final defaultText = "Hello Brother!\n\nI'm $nameToUse from YFC - facing Technical difficulties with the below function/s:\n";

    final textController = TextEditingController(text: defaultText);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0B132B) : AppTheme.surfaceCardLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.goldAccent, width: 1.2),
          ),
          title: Row(
            children: [
              const Icon(Icons.headset_mic_rounded, color: AppTheme.shiningRed, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isTelugu ? "సపోర్ట్ టికెట్ సమర్పించండి" : "Submit Support Ticket",
                  style: GoogleFonts.cinzel(
                    color: AppTheme.goldAccent,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isTelugu
                    ? "మీకు ఎదురవుతున్న సమస్య లేదా అభిప్రాయాన్ని వివరించండి:"
                    : "Describe the issue or feedback you are facing:",
                style: TextStyle(
                  color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                minLines: 2,
                maxLines: 4,
                style: TextStyle(
                  color: isDark ? AppTheme.textLight : AppTheme.textDark,
                  fontSize: 13.5,
                ),
                decoration: InputDecoration(
                  hintText: "[Enter your text/notes here..]",
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13, fontStyle: FontStyle.italic),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF070D1E) : const Color(0xFFFFF5F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppTheme.goldAccent.withValues(alpha: 0.4)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppTheme.goldAccent.withValues(alpha: 0.4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.goldAccent, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                isTelugu ? "రద్దు చేయండి" : "Cancel",
                style: const TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final issueText = textController.text.trim();
                if (issueText.isEmpty) return;
                Navigator.pop(context);

                final formattedUrl = "https://wa.me/919154300354?text=${Uri.encodeComponent(issueText)}";

                final uri = Uri.parse(formattedUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.shiningRed,
                foregroundColor: AppTheme.goldAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              icon: const Icon(Icons.send_rounded, size: 16, color: AppTheme.goldAccent),
              label: Text(
                isTelugu ? "టికెట్ పంపండి" : "Send Ticket",
                style: const TextStyle(
                  color: AppTheme.goldAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showProfileModal(BuildContext context, AppState appState) {
    final isDark = appState.isDarkMode;
    final isTelugu = appState.isTelugu;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.bgPrimaryDark : AppTheme.bgPrimaryLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.goldAccent.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    await appState.uploadProfileImage(pickedFile);
                  }
                },
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                      ),
                      child: _buildUserAvatarWidget(appState, radius: 36),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppTheme.goldAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 16, color: AppTheme.textDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                appState.activeUserName,
                style: GoogleFonts.cinzel(
                  color: AppTheme.goldAccent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                appState.phoneNumber.isNotEmpty ? appState.phoneNumber : "YFC Member",
                style: TextStyle(
                  color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              Divider(color: AppTheme.goldAccent.withValues(alpha: 0.2)),
              const SizedBox(height: 12),
              _buildProfileDetailRow(
                icon: Icons.cake_rounded,
                label: isTelugu ? "పుట్టిన తేదీ" : "Date of Birth",
                value: appState.dateOfBirth.isNotEmpty ? appState.dateOfBirth : "Not provided",
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildProfileDetailRow(
                icon: Icons.favorite_rounded,
                label: isTelugu ? "వివాహ పరిస్థితి" : "Marital Status",
                value: appState.maritalStatus,
                isDark: isDark,
              ),
              if (appState.maritalStatus == "Married" && appState.anniversaryDate.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildProfileDetailRow(
                  icon: Icons.celebration_rounded,
                  label: isTelugu ? "వివాహ వార్షికోత్సవం" : "Anniversary",
                  value: appState.anniversaryDate,
                  isDark: isDark,
                ),
              ],
              const SizedBox(height: 10),
              _buildProfileDetailRow(
                icon: Icons.translate_rounded,
                label: isTelugu ? "భాష" : "Preferred Language",
                value: appState.preferredLanguage == "TE" ? "తెలుగు (Telugu)" : "English",
                isDark: isDark,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.shiningRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  label: Text(
                    isTelugu ? "ప్రొఫైల్ సవరించండి >" : "EDIT PROFILE >",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.goldAccent),
        const SizedBox(width: 12),
        Text(
          "$label: ",
          style: TextStyle(
            color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
            fontSize: 13,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: isDark ? AppTheme.textLight : AppTheme.textDark,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  void _showAlarmModal(BuildContext context, AppState appState) {
    final isDark = appState.isDarkMode;
    final isTelugu = appState.isTelugu;
    final alarmService = AlarmService();

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.bgPrimaryDark : AppTheme.bgPrimaryLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.goldAccent.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.alarm_rounded, color: AppTheme.shiningRed, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        isTelugu ? "అలారం నియామకాలు" : "Fellowship Alarm Settings",
                        style: GoogleFonts.cinzel(
                          color: AppTheme.goldAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.surfaceCardDark : AppTheme.surfaceCardLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.wb_sunny_rounded, color: AppTheme.goldAccent, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isTelugu ? "ఉదయకాల ప్రార్థన (5:00 AM – 5:30 AM)" : "Morning Prayer (5:00 AM – 5:30 AM)",
                                    style: TextStyle(
                                      color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    alarmService.isMorningAlarmEnabled
                                        ? (isTelugu ? "అలారం యాక్టివ్ లో ఉంది" : "Alarm active & scheduled")
                                        : (isTelugu ? "అలారం నిలిపివేయబడింది" : "Alarm turned off"),
                                    style: TextStyle(
                                      color: alarmService.isMorningAlarmEnabled ? AppTheme.statusGreen : AppTheme.textMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              value: alarmService.isMorningAlarmEnabled,
                              activeThumbColor: AppTheme.goldAccent,
                              activeTrackColor: AppTheme.shiningRed,
                              onChanged: (val) async {
                                await alarmService.setMorningAlarmEnabled(val);
                                setModalState(() {});
                                if (!val && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Live fellowship reminders auto-sync daily at midnight."),
                                      duration: Duration(seconds: 3),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.nightlight_round, color: AppTheme.goldAccent, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isTelugu ? "సాయంత్రం అధ్యయనం (9:00 PM – 10:00 PM)" : "Evening Bible Study (9:00 PM – 10:00 PM)",
                                    style: TextStyle(
                                      color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    alarmService.isEveningAlarmEnabled
                                        ? (isTelugu ? "అలారం యాక్టివ్ లో ఉంది" : "Alarm active & scheduled")
                                        : (isTelugu ? "అలారం నిలిపివేయబడింది" : "Alarm turned off"),
                                    style: TextStyle(
                                      color: alarmService.isEveningAlarmEnabled ? AppTheme.statusGreen : AppTheme.textMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              value: alarmService.isEveningAlarmEnabled,
                              activeThumbColor: AppTheme.goldAccent,
                              activeTrackColor: AppTheme.shiningRed,
                              onChanged: (val) async {
                                await alarmService.setEveningAlarmEnabled(val);
                                setModalState(() {});
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.textMuted, width: 1.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            isTelugu ? "మూసివేయి" : "Close",
                            style: const TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            AlarmService().stopAlarm();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.shiningRed,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          ),
                          icon: const Icon(Icons.stop_circle_outlined, size: 18, color: Colors.white),
                          label: Text(
                            isTelugu ? "ఆపివేయండి" : "Stop Alarm",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSettingsModal(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: appState.isDarkMode ? AppTheme.bgPrimaryDark : AppTheme.bgPrimaryLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            final isDark = appState.isDarkMode;
            final isTelugu = appState.isTelugu;

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.goldAccent.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.settings_rounded, color: AppTheme.goldAccent, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        isTelugu ? "యాప్ సెట్టింగ్‌లు" : "App Settings",
                        style: GoogleFonts.cinzel(
                          color: AppTheme.goldAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Theme Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.surfaceCardDark : AppTheme.surfaceCardLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                              color: AppTheme.goldAccent,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isTelugu ? "యాప్ థీమ్" : "App Theme",
                                  style: TextStyle(
                                    color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  isDark
                                      ? (isTelugu ? "సెలెస్టియల్ నేవీ (డార్క్)" : "Celestial Navy (Dark)")
                                      : (isTelugu ? "ప్యూర్ వైట్ (లైట్)" : "Pure White (Light)"),
                                  style: TextStyle(color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Switch(
                          value: isDark,
                          activeThumbColor: AppTheme.goldAccent,
                          activeTrackColor: AppTheme.shiningRed,
                          onChanged: (val) {
                            appState.toggleThemeMode();
                            setStateModal(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Language Switcher
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.surfaceCardDark : AppTheme.surfaceCardLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.language_rounded, color: AppTheme.shiningRed, size: 22),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isTelugu ? "భాష" : "Language",
                                  style: TextStyle(
                                    color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  isTelugu ? "తెలుగు" : "English",
                                  style: TextStyle(color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {
                            appState.toggleLanguage();
                            setStateModal(() {});
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.shiningRed,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: Text(
                            isTelugu ? "English కు మార్చు" : "తెలుగులోకి మార్చు",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// Sub-Tab 1: Main Dashboard Feed View
class DashboardFeedTab extends StatelessWidget {
  const DashboardFeedTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isTelugu = appState.isTelugu;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Alarm Ringing Alert Banner (Stop Alarm Button)
          ValueListenableBuilder<bool>(
            valueListenable: AlarmService().isAlarmRingingNotifier,
            builder: (context, isRinging, _) {
              if (!isRinging) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.shiningRed,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.shiningRed.withAlpha(120),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isTelugu ? "🔔 అలారం మోగుతోంది!" : "🔔 ALARM IS RINGING!",
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                isTelugu
                                    ? "ఆడియో లూప్‌ను ఆపివేయడానికి క్రింద నొక్కండి"
                                    : "Tap below to immediately halt audio and dismiss notification.",
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          AlarmService().stopAlarm();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.shiningRed,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.stop_circle_rounded, color: AppTheme.shiningRed, size: 20),
                        label: Text(
                          isTelugu ? "అలారం ఆపివేయి ⏹️" : "STOP ALARM NOW ⏹️",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Live Google Meet Countdown & 10s Test Alarm Banner
          const MeetCountdownBanner(),

          // Daily Bread Devotional Card
          _buildDailyBreadCard(context, isTelugu),

          // Curated Native Content Cards Section (Biblical News & OT Bible Study)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTelugu ? "కొత్త విశేషాలు" : "WHAT'S NEW?",
                  style: GoogleFonts.cinzel(
                    color: const Color(0xFFB8860B), // Metallic Gold (#B8860B)
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),

                // Auto-Sliding Live Israel365 News Carousel
                WhatsNewCarousel(isTelugu: isTelugu),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDailyBreadCard(BuildContext context, bool isTelugu) {
    final promise = ContentService.getTodayPromise();
    final verseRef = promise.reference;
    final verseEn = promise.textEn;
    final verseTe = promise.textTe;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF8B0000), // Deep Crimson Red
            Color(0xFF500000), // Dark Burgundy
            Color(0xFF2B0000), // Midnight Maroon
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD700), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(100),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AppTheme.goldAccent.withAlpha(40),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title & 1-Tap Poster Share Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFFD700), width: 1),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.auto_awesome_rounded,
                          color: Color(0xFFFFD700),
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isTelugu ? "నేటి వాగ్దాన వాక్యం" : "DAILY BREAD PROMISE",
                    style: GoogleFonts.cinzel(
                      color: const Color(0xFFFFD700),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded, color: Color(0xFFFFD700), size: 22),
                tooltip: "Share 9:16 Social Poster",
                onPressed: () {
                  StatusCardGenerator.show(
                    context,
                    verseReference: verseRef,
                    verseTextEn: verseEn,
                    verseTextTe: verseTe,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // English Devotional Verse
          Text(
            "“$verseEn”",
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14,
              fontStyle: FontStyle.italic,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),

          // Telugu Devotional Verse
          Text(
            "“$verseTe”",
            style: GoogleFonts.notoSansTelugu(
              color: const Color(0xFFFFD700),
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),

          // Verse Citation Badge
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withAlpha(40),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD700), width: 1.2),
              ),
              child: Text(
                "— $verseRef",
                style: GoogleFonts.cinzel(
                  color: const Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildNativeContentCard(
    BuildContext context, {
    required ContentArticle article,
    required IconData icon,
    required Color badgeColor,
    required bool isTelugu,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        if (article.category == "OT BIBLE STUDY") {
          OTBibleStudyExplorer.show(context);
        } else {
          _showContentReaderModal(context, article, isTelugu, isDark);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceCardDark : const Color(0xFFFFF0F2), // Native YFC Blush-Pink Card Aesthetic
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD4AF37), width: 1.4), // Polished Gold Frame Border
          boxShadow: [
            BoxShadow(
              color: AppTheme.shiningRed.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Article Feature Image Banner
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: article.imageUrl.startsWith('assets/')
                  ? Image.asset(
                      article.imageUrl,
                      height: 115,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 110,
                        color: isDark ? Colors.grey[850] : Colors.pink[50],
                        child: const Center(
                          child: Icon(Icons.newspaper_rounded, color: AppTheme.goldAccent, size: 40),
                        ),
                      ),
                    )
                  : Image.network(
                      article.imageUrl,
                      height: 115,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 110,
                        color: isDark ? Colors.grey[850] : Colors.pink[50],
                        child: const Center(
                          child: Icon(Icons.newspaper_rounded, color: AppTheme.goldAccent, size: 40),
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(icon, color: AppTheme.goldAccent, size: 18),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              article.category,
                              style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        article.publishDate,
                        style: TextStyle(
                          color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Headline in high-contrast deep black (#000000 in light mode)
                  Text(
                    isTelugu ? article.titleTe : article.titleEn,
                    style: GoogleFonts.cinzel(
                      color: isDark ? AppTheme.textLight : const Color(0xFF000000),
                      fontWeight: FontWeight.bold,
                      fontSize: 14.0,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Clean 1-line summary
                  Text(
                    isTelugu ? article.summaryTe : article.summaryEn,
                    style: TextStyle(
                      color: isDark ? AppTheme.textMutedDark : const Color(0xFF333333),
                      fontSize: 11.5,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        article.category == "OT BIBLE STUDY"
                            ? (isTelugu ? "అధ్యయనం ప్రారంభించండి" : "Explore OT Study")
                            : (isTelugu ? "పూర్తి పాఠం చదవండి" : "Read Full Story"),
                        style: const TextStyle(
                          color: AppTheme.shiningRed,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, size: 13, color: AppTheme.shiningRed),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showContentReaderModal(BuildContext context, ContentArticle article, bool isTelugu, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.bgPrimaryDark : AppTheme.bgPrimaryLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.goldAccent.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.shiningRed.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.shiningRed.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      article.category,
                      style: const TextStyle(color: AppTheme.shiningRed, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Article Header Image
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: article.imageUrl.startsWith('assets/')
                    ? Image.asset(
                        article.imageUrl,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(),
                      )
                    : Image.network(
                        article.imageUrl,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(),
                      ),
              ),
              const SizedBox(height: 14),
              Text(
                isTelugu ? article.titleTe : article.titleEn,
                style: GoogleFonts.cinzel(
                  color: isDark ? AppTheme.textLight : const Color(0xFF000000),
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "${article.sourceName} • ${article.publishDate}",
                style: TextStyle(color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Divider(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    ContentService.sanitizeText(isTelugu ? article.fullContentTe : article.fullContentEn),
                    style: TextStyle(
                      color: isDark ? AppTheme.textLight : const Color(0xFF000000), // Deep high-contrast black in light mode
                      fontSize: 14.5,
                      height: 1.65,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class BiblicalNewsCarouselWidget extends StatefulWidget {
  final bool isTelugu;
  const BiblicalNewsCarouselWidget({super.key, required this.isTelugu});

  @override
  State<BiblicalNewsCarouselWidget> createState() => _BiblicalNewsCarouselWidgetState();
}

class _BiblicalNewsCarouselWidgetState extends State<BiblicalNewsCarouselWidget> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;
  List<ContentArticle> _newsList = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    final rawList = await ContentService.fetchBiblicalNewsRss();
    if (mounted) {
      // Daily Seed Rotation using DateTime.now().day
      final daySeed = DateTime.now().day;
      final rotated = List<ContentArticle>.from(rawList);
      if (rotated.isNotEmpty) {
        final offset = daySeed % rotated.length;
        _newsList = [...rotated.sublist(offset), ...rotated.sublist(0, offset)];
      } else {
        _newsList = rotated;
      }

      setState(() {});
      if (_newsList.length > 1) {
        _startAutoSlide();
      }
    }
  }

  void _startAutoSlide() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_newsList.isEmpty) return;
      _currentPage = (_currentPage + 1) % _newsList.length;
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_newsList.isEmpty) {
      final fallback = ContentService.articles.first;
      return DashboardFeedTab._buildNativeContentCard(context, article: fallback, icon: Icons.newspaper_rounded, badgeColor: AppTheme.shiningRed, isTelugu: widget.isTelugu);
    }

    return Column(
      children: [
        SizedBox(
          height: 255,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: _newsList.length,
            itemBuilder: (context, index) {
              final article = _newsList[index];
              return DashboardFeedTab._buildNativeContentCard(
                context,
                article: article,
                icon: Icons.newspaper_rounded,
                badgeColor: AppTheme.shiningRed,
                isTelugu: widget.isTelugu,
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_newsList.length, (idx) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == idx ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentPage == idx ? AppTheme.goldAccent : AppTheme.goldAccent.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}
