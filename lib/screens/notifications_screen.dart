import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class NotificationItem {
  final String id;
  final String titleEn;
  final String titleTe;
  final String descriptionEn;
  final String descriptionTe;
  final DateTime timestamp;
  final String type; // 'announcement', 'quiz', 'chat', 'update', 'prayer'
  bool isRead;

  NotificationItem({
    required this.id,
    required this.titleEn,
    required this.titleTe,
    required this.descriptionEn,
    required this.descriptionTe,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: 'notif-1',
      titleEn: 'Youth Fellowship Gathering Tonight! 🎥',
      titleTe: 'ఈ రాత్రి యూత్ ఫెలోషిప్ కూటం! 🎥',
      descriptionEn: 'Join us live on Google Meet at 9:00 PM for worship & Bible study.',
      descriptionTe: 'ఆరాధన మరియు బైబిల్ అధ్యయనం కోసం రాత్రి 9:00 గంటలకు గూగుల్ మీట్‌లో చేరండి.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      type: 'announcement',
    ),
    NotificationItem(
      id: 'notif-2',
      titleEn: 'Daily Bible Quiz is Live! 📖',
      titleTe: 'నేటి బైబిల్ క్విజ్ అందుబాటులో ఉంది! 📖',
      descriptionEn: 'Test your knowledge on Genesis & Old Testament history today.',
      descriptionTe: 'ఆదికాండము మరియు పాతనిబంధన చరిత్రపై మీ జ్ఞానాన్ని పరీక్షించుకోండి.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      type: 'quiz',
    ),
    NotificationItem(
      id: 'notif-3',
      titleEn: 'New Chat Mention 💬',
      titleTe: 'కొత్త చాట్ ప్రస్తావన 💬',
      descriptionEn: 'Grace V. mentioned you in Fellowship Chat: "Looking forward to study!"',
      descriptionTe: 'గ్రేస్ V. ఫెలోషిప్ చాట్‌లో మిమ్మల్ని ప్రస్తావించారు.',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      type: 'chat',
    ),
    NotificationItem(
      id: 'notif-4',
      titleEn: 'Prayer Alert: College Exams 🎓',
      titleTe: 'ప్రార్థన విజ్ఞప్తి: కళాశాల పరీక్షలు 🎓',
      descriptionEn: 'Sister Mary requested fellowship prayers for upcoming engineering exams.',
      descriptionTe: 'సిస్టర్ మేరీ ఇంజనీరింగ్ పరీక్షల కోసం ప్రార్థనలు కోరారు.',
      timestamp: DateTime.now().subtract(const Duration(hours: 8)),
      type: 'prayer',
    ),
    NotificationItem(
      id: 'notif-5',
      titleEn: 'YFC Feature Update ✨',
      titleTe: 'YFC యాప్ కొత్త అప్‌డేట్ ✨',
      descriptionEn: 'Full-screen video player & offline Bible study tools are now available.',
      descriptionTe: 'పూర్తి స్క్రీన్ వీడియో ప్లేయర్ మరియు బైబిల్ పరికరాలు ఇప్పుడు అందుబాటులో ఉన్నాయి.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      type: 'update',
      isRead: true,
    ),
  ];

  void _clearAll() {
    setState(() {
      _notifications.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("All notifications cleared!"),
        backgroundColor: AppTheme.shiningRed,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _toggleReadState(NotificationItem item) {
    setState(() {
      item.isRead = !item.isRead;
    });
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'announcement':
        return Icons.campaign_rounded;
      case 'quiz':
        return Icons.quiz_rounded;
      case 'chat':
        return Icons.chat_bubble_outline_rounded;
      case 'prayer':
        return Icons.volunteer_activism_rounded;
      case 'update':
      default:
        return Icons.notifications_active_outlined;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'announcement':
        return AppTheme.shiningRed;
      case 'quiz':
        return AppTheme.goldAccent;
      case 'chat':
        return const Color(0xFF2ECC71);
      case 'prayer':
        return Colors.purpleAccent;
      case 'update':
      default:
        return Colors.blueAccent;
    }
  }

  String _formatTime(DateTime time, bool isTelugu) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return isTelugu ? "${diff.inMinutes} నిమిషాల క్రితం" : "${diff.inMinutes} mins ago";
    } else if (diff.inHours < 24) {
      return isTelugu ? "${diff.inHours} గంటల క్రితం" : "${diff.inHours} hrs ago";
    } else {
      return isTelugu ? "${diff.inDays} రోజుల క్రితం" : "${diff.inDays} days ago";
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isTelugu = appState.isTelugu;
    final isDark = appState.isDarkMode;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: Text(
          isTelugu ? "నోటిఫికేషన్లు" : "Notifications",
          style: GoogleFonts.cinzel(
            color: isDark ? AppTheme.goldAccent : AppTheme.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton.icon(
              onPressed: _clearAll,
              icon: const Icon(Icons.clear_all_rounded, color: AppTheme.shiningRed, size: 20),
              label: Text(
                isTelugu ? "అన్నీ తీసివేయి" : "Clear All",
                style: const TextStyle(
                  color: AppTheme.shiningRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: AppTheme.goldAccent.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isTelugu ? "నోటిఫికేషన్లు లేవు" : "No Notifications Yet",
                    style: GoogleFonts.cinzel(
                      color: isDark ? AppTheme.textLight : AppTheme.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isTelugu ? "మీరు కొత్త అప్‌డేట్‌లు అందుకున్నప్పుడు ఇక్కడ కనిపిస్తాయి." : "You're all caught up! Check back later.",
                    style: TextStyle(
                      color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final item = _notifications[index];
                final icon = _getIconForType(item.type);
                final iconColor = _getColorForType(item.type);

                return GestureDetector(
                  onTap: () => _toggleReadState(item),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: item.isRead
                          ? (isDark ? AppTheme.surfaceCardDark.withValues(alpha: 0.6) : Colors.white)
                          : (isDark ? AppTheme.surfaceCardDark : const Color(0xFFFFF0F2)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: item.isRead
                            ? AppTheme.goldAccent.withValues(alpha: 0.2)
                            : AppTheme.goldAccent.withValues(alpha: 0.6),
                        width: item.isRead ? 1.0 : 1.5,
                      ),
                      boxShadow: [
                        if (!item.isRead)
                          BoxShadow(
                            color: AppTheme.shiningRed.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type Icon
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(color: iconColor.withValues(alpha: 0.4)),
                          ),
                          child: Icon(icon, color: iconColor, size: 22),
                        ),
                        const SizedBox(width: 14),

                        // Notification Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      isTelugu ? item.titleTe : item.titleEn,
                                      style: TextStyle(
                                        color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                        fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  if (!item.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppTheme.shiningRed,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isTelugu ? item.descriptionTe : item.descriptionEn,
                                style: TextStyle(
                                  color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                                  fontSize: 12.5,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatTime(item.timestamp, isTelugu),
                                style: TextStyle(
                                  color: AppTheme.goldAccent.withValues(alpha: 0.8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
