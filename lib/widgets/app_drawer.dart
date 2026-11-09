import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../screens/about_yfc_screen.dart';
import '../screens/admin_study_screen.dart';
import '../screens/members_directory_screen.dart';
import '../screens/notifications_screen.dart';
import '../widgets/share_modal_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class AppDrawer extends StatelessWidget {
  final void Function(String value)? onMenuSelected;

  const AppDrawer({
    super.key,
    this.onMenuSelected,
  });

  void _handleMenuSelection(BuildContext context, String value, AppState appState) {
    Navigator.of(context).pop(); // Close drawer first

    if (onMenuSelected != null) {
      onMenuSelected!(value);
      return;
    }

    final isTelugu = appState.isTelugu;

    switch (value) {
      case "PROFILE":
        appState.setNavIndex(4); // Navigates to Profile tab
        break;
      case "ABOUT_YFC":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AboutYfcScreen()),
        );
        break;
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
      case "ALARM":
        appState.setNavIndex(0); // Standard Home
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isTelugu ? "ప్రార్థన అలారం ప్రారంభించబడింది" : "Prayer Alarm Set Successfully"),
            backgroundColor: AppTheme.shiningRed,
          ),
        );
        break;
      case "SHARE":
        ShareModalWidget.show(context);
        break;
      case "SUPPORT":
        launchUrl(Uri.parse(AppState.whatsappSupportUrl), mode: LaunchMode.externalApplication);
        break;
      case "ADMIN_STUDY":
        if (appState.isAdmin) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminStudyScreen()),
          );
        }
        break;
      case "SETTINGS":
        appState.setNavIndex(4); // Settings inside Profile
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = appState.isDarkMode;
    final isTelugu = appState.isTelugu;
    final isAdmin = appState.isAdmin;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: Column(
        children: [
          // Drawer Header
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [AppTheme.shiningRed, const Color(0xFF8B0000)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            currentAccountPicture: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD4AF37), width: 2),
              ),
              child: ClipOval(
                child: _buildDrawerAvatar(appState),
              ),
            ),
            accountName: Row(
              children: [
                Flexible(
                  child: Text(
                    appState.profileName.isNotEmpty ? appState.profileName : "YFC Fellowship",
                    style: GoogleFonts.cinzel(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isAdmin
                        ? const Color(0xFFD4AF37).withValues(alpha: 0.25)
                        : Colors.white24,
                    borderRadius: BorderRadius.circular(6),
                    border: isAdmin ? Border.all(color: const Color(0xFFD4AF37), width: 1) : null,
                  ),
                  child: Text(
                    isAdmin ? "ADMIN" : "Member",
                    style: TextStyle(
                      color: isAdmin ? const Color(0xFFD4AF37) : Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            accountEmail: Text(
              appState.phoneNumber.isNotEmpty ? appState.phoneNumber : "Youth For Christ",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12.5,
              ),
            ),
          ),

          // Navigation List Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.person_rounded,
                  title: isTelugu ? "ప్రొఫైల్" : "PROFILE",
                  color: AppTheme.goldAccent,
                  onTap: () => _handleMenuSelection(context, "PROFILE", appState),
                  isDark: isDark,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.public_rounded,
                  title: isTelugu ? "YFC గురించి" : "ABOUT YFC",
                  color: AppTheme.goldAccent,
                  onTap: () => _handleMenuSelection(context, "ABOUT_YFC", appState),
                  isDark: isDark,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.people_rounded,
                  title: isTelugu ? "సభ్యులు" : "MEMBERS DIRECTORY",
                  color: AppTheme.goldAccent,
                  onTap: () => _handleMenuSelection(context, "MEMBERS", appState),
                  isDark: isDark,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.notifications_active_outlined,
                  title: isTelugu ? "నోటిఫికేషన్లు" : "NOTIFICATIONS",
                  color: AppTheme.goldAccent,
                  onTap: () => _handleMenuSelection(context, "NOTIFICATIONS", appState),
                  isDark: isDark,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.alarm_rounded,
                  title: isTelugu ? "అలారం" : "ALARM",
                  color: AppTheme.shiningRed,
                  onTap: () => _handleMenuSelection(context, "ALARM", appState),
                  isDark: isDark,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.share_rounded,
                  title: isTelugu ? "షేర్ చేయండి" : "SHARE APP",
                  color: AppTheme.goldAccent,
                  onTap: () => _handleMenuSelection(context, "SHARE", appState),
                  isDark: isDark,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.headset_mic_rounded,
                  title: isTelugu ? "సపోర్ట్" : "SUPPORT",
                  color: const Color(0xFF2ECC71),
                  onTap: () => _handleMenuSelection(context, "SUPPORT", appState),
                  isDark: isDark,
                ),

                // STRICT ADMIN MENU ITEM
                if (isAdmin)
                  _buildDrawerItem(
                    context,
                    icon: Icons.admin_panel_settings_rounded,
                    title: isTelugu ? "పాస్టర్ అడ్మిన్" : "ADMIN: MANAGE STUDY",
                    color: AppTheme.shiningRed,
                    onTap: () => _handleMenuSelection(context, "ADMIN_STUDY", appState),
                    isDark: isDark,
                  ),

                const Divider(height: 24, thickness: 1, indent: 16, endIndent: 16),

                _buildDrawerItem(
                  context,
                  icon: Icons.settings_rounded,
                  title: isTelugu ? "సెట్టింగ్‌లు" : "SETTINGS",
                  color: AppTheme.goldAccent,
                  onTap: () => _handleMenuSelection(context, "SETTINGS", appState),
                  isDark: isDark,
                ),

                const Divider(height: 16, thickness: 1, indent: 16, endIndent: 16),

                _buildDrawerItem(
                  context,
                  icon: Icons.logout_rounded,
                  title: isTelugu ? "లాగ్ అవుట్" : "LOG OUT",
                  color: const Color(0xFFD90429),
                  onTap: () async {
                    Navigator.pop(context); // Close drawer
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF0B132B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFFD4AF37)),
                        ),
                        title: const Text("Log Out", style: TextStyle(color: Color(0xFFD4AF37))),
                        content: const Text("Are you sure you want to log out of YFC Fellowship?", style: TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text("Log Out", style: TextStyle(color: Color(0xFFD90429))),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await appState.logout();
                    }
                  },
                  isDark: isDark,
                ),
              ],
            ),
          ),

          // Drawer Footer Version Label
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "YFC Fellowship App v1.0.0",
              style: TextStyle(
                color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? AppTheme.textLight : AppTheme.textDark,
          fontWeight: FontWeight.w600,
          fontSize: 13.5,
        ),
      ),
      onTap: onTap,
      dense: true,
      horizontalTitleGap: 8,
    );
  }

  Widget _buildDrawerAvatar(AppState appState) {
    final avatarUrl = appState.avatarUrl;
    if (avatarUrl.isNotEmpty) {
      ImageProvider imageProvider;
      if (avatarUrl.startsWith('http')) {
        imageProvider = NetworkImage(avatarUrl);
      } else {
        imageProvider = FileImage(File(avatarUrl));
      }
      return CircleAvatar(
        radius: 36,
        backgroundColor: AppTheme.shiningRed,
        backgroundImage: imageProvider,
      );
    }
    final name = appState.profileName.isNotEmpty ? appState.profileName : "YFC Member";
    final initial = name.isNotEmpty ? name[0].toUpperCase() : "Y";

    return CircleAvatar(
      radius: 36,
      backgroundColor: AppTheme.shiningRed,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
    );
  }
}
