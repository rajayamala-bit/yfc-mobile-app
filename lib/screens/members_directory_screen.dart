import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_state.dart';
import '../services/member_service.dart';
import '../theme/app_theme.dart';

class MemberModel {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String avatarUrl;
  final String role;

  MemberModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.avatarUrl,
    this.role = "Member",
  });
}

class MembersDirectoryScreen extends StatefulWidget {
  const MembersDirectoryScreen({super.key});

  @override
  State<MembersDirectoryScreen> createState() => _MembersDirectoryScreenState();
}

class _MembersDirectoryScreenState extends State<MembersDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<MemberModel> _allMembers = [];
  List<MemberModel> _filteredMembers = [];
  bool _isLoading = true;
  StreamSubscription? _membersSubscription;

  @override
  void initState() {
    super.initState();
    _listenToMembersFirestore();
    _searchController.addListener(_onSearchChanged);
  }

  void _listenToMembersFirestore() {
    try {
      _membersSubscription = FirebaseFirestore.instance.collection('members').snapshots().listen((snapshot) {
        final List<MemberModel> fetched = [];
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final name = data['name'] as String? ?? data['full_name'] as String? ?? 'YFC Member';
          final phone = data['phone'] as String? ?? data['phone_number'] as String? ?? '';
          final avatar = data['avatar_url'] as String? ?? 
                         data['avatarUrl'] as String? ?? 
                         data['photoUrl'] as String? ?? 
                         data['photo_url'] as String? ?? '';
          final role = data['role'] as String? ?? 'Member';

          fetched.add(MemberModel(
            id: doc.id,
            fullName: name,
            phoneNumber: phone,
            avatarUrl: avatar,
            role: role,
          ));
        }

        if (mounted) {
          setState(() {
            _allMembers = fetched;
            _filteredMembers = List.from(_allMembers);
            _isLoading = false;
          });
        }
      }, onError: (_) {
        _fetchMembersLocal();
      });
    } catch (_) {
      _fetchMembersLocal();
    }
  }

  Future<void> _fetchMembersLocal() async {
    setState(() => _isLoading = true);
    try {
      final fetched = await MemberService().fetchAllMembers();
      _allMembers = fetched;
    } catch (_) {
      _allMembers = [];
    } finally {
      if (mounted) {
        setState(() {
          _filteredMembers = List.from(_allMembers);
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _membersSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMembers = List.from(_allMembers);
      } else {
        _filteredMembers = _allMembers.where((m) {
          return m.fullName.toLowerCase().contains(query) ||
                 m.phoneNumber.toLowerCase().contains(query) ||
                 m.role.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _openWhatsApp(String phone, String name) async {
    final digitsOnly = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final targetNumber = digitsOnly.startsWith('91') ? digitsOnly : '91$digitsOnly';
    final encodedMsg = Uri.encodeComponent("Hi $name, greetings from YFC Fellowship!");
    final url = "https://wa.me/$targetNumber?text=$encodedMsg";
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      final callUri = Uri.parse("tel:$targetNumber");
      if (await canLaunchUrl(callUri)) {
        await launchUrl(callUri);
      }
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse("tel:$cleanPhone");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildAvatar(MemberModel member) {
    if (member.avatarUrl.isNotEmpty && member.avatarUrl.startsWith('http')) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: AppTheme.shiningRed,
        backgroundImage: NetworkImage(member.avatarUrl),
      );
    }
    final initials = member.fullName.trim().split(RegExp(r'\s+'));
    final initialStr = initials.length >= 2
        ? "${initials[0][0]}${initials[1][0]}".toUpperCase()
        : (member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : "Y");

    return CircleAvatar(
      radius: 24,
      backgroundColor: AppTheme.shiningRed,
      child: Text(
        initialStr,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = appState.isDarkMode;
    final isTelugu = appState.isTelugu;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgPrimaryDark : AppTheme.bgPrimaryLight,
      appBar: AppBar(
        title: Text(
          isTelugu ? "సభ్యుల డైరెక్టరీ" : "YFC Members Directory",
          style: GoogleFonts.cinzel(
            color: AppTheme.goldAccent,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppTheme.bgPrimaryDark : AppTheme.bgPrimaryLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.goldAccent),
      ),
      body: Column(
        children: [
          // Filter & Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                color: isDark ? AppTheme.textLight : AppTheme.textDark,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: isTelugu ? "పేరు లేదా ఫోన్ నంబర్‌తో శోధించండి..." : "Search members by name or phone...",
                hintStyle: TextStyle(
                  color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.goldAccent),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AppTheme.textMuted),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppTheme.surfaceCardDark : AppTheme.surfaceCardLight,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.goldAccent.withValues(alpha: 0.35)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.goldAccent.withValues(alpha: 0.35)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.shiningRed, width: 1.5),
                ),
              ),
            ),
          ),

          // Member List View
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.shiningRed),
                    ),
                  )
                : _filteredMembers.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.people_outline_rounded, size: 48, color: AppTheme.goldAccent),
                              const SizedBox(height: 12),
                              Text(
                                isTelugu
                                    ? "ఇంకా నమోదు చేసుకున్న సభ్యులు ఎవరూ లేరు. YFC ఫెలోషిప్‌లో చేరడానికి సభ్యులను ఆహ్వానించండి."
                                    : "No registered members yet. Invite members to join YFC Fellowship.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _filteredMembers.length,
                        itemBuilder: (context, index) {
                          final member = _filteredMembers[index];
                          final cleanPhoneDigits = member.phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
                          final last10 = cleanPhoneDigits.length >= 10
                              ? cleanPhoneDigits.substring(cleanPhoneDigits.length - 10)
                              : cleanPhoneDigits;
                          final isAdmin = last10 == '6304300354' || last10 == '9502223426';

                          return InkWell(
                            onTap: () {
                              if (appState.isAdmin) {
                                _showAdminRoleDialog(context, member);
                              }
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.surfaceCardDark : AppTheme.surfaceCardLight,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: AppTheme.goldAccent.withValues(alpha: 0.35),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.shiningRed.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppTheme.goldAccent, width: 1.5),
                                    ),
                                    child: _buildAvatar(member),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          member.fullName,
                                          style: TextStyle(
                                            color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          member.phoneNumber.isNotEmpty ? member.phoneNumber : "YFC Member",
                                          style: TextStyle(
                                            color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 5),

                                        // Admin vs Member Role Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isAdmin
                                                ? const Color(0xFFD4AF37).withValues(alpha: 0.18)
                                                : const Color(0xFF666666).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(8),
                                            border: isAdmin ? Border.all(color: const Color(0xFFD4AF37), width: 1.2) : null,
                                          ),
                                          child: Text(
                                            isAdmin ? "ADMIN" : "Member",
                                            style: TextStyle(
                                              color: isAdmin ? const Color(0xFFD4AF37) : (isDark ? AppTheme.textMutedDark : const Color(0xFF666666)),
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: isAdmin ? 0.8 : 0,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Dynamic WhatsApp & Direct Phone Action Buttons
                                  Row(
                                    children: [
                                       IconButton(
                                         icon: SvgPicture.string(
                                           '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 448 512" fill="#25D366"><path d="M380.9 97.1C339 55.1 283.2 32 223.9 32c-122.4 0-222 99.6-222 222 0 39.1 10.2 77.3 29.6 111L0 480l117.7-30.9c32.4 17.7 68.9 27 106.1 27h.1c122.3 0 224.1-99.6 224.1-222 0-59.3-25.2-115-67.1-157zm-157 341.6c-33.2 0-65.7-8.9-94-25.7l-6.7-4-69.8 18.3 18.6-68.1-4.4-7c-18.5-29.4-28.2-63.3-28.2-98.2 0-101.7 82.8-184.5 184.6-184.5 49.3 0 95.6 19.2 130.4 54.1 34.8 34.9 56.2 81.2 56.1 130.5 0 101.8-84.9 184.6-186.6 184.6zm101.2-138.2c-5.5-2.8-32.8-16.2-37.9-18-5.1-1.9-8.8-2.8-12.5 2.8-3.7 5.6-14.3 18-17.6 21.8-3.2 3.7-6.5 4.2-12 1.4-32.6-16.3-54-29.1-75.5-66-5.7-9.8 5.7-9.1 16.3-30.3 1.8-3.7.9-6.9-.5-9.7-1.4-2.8-12.5-30.1-17.1-41.2-4.5-10.8-9.1-9.3-12.5-9.5-3.2-.2-6.9-.2-10.6-.2-3.7 0-9.7 1.4-14.8 6.9-5.1 5.6-19.4 19-19.4 46.3 0 27.3 19.9 53.7 22.6 57.4 2.8 3.7 39.1 59.7 94.8 83.8 35.2 15.2 49 16.5 66.6 13.9 10.7-1.6 32.8-13.4 37.4-26.4 4.6-13 4.6-24.1 3.2-26.4-1.3-2.5-5-3.9-10.5-6.6z"/></svg>',
                                           width: 24,
                                           height: 24,
                                         ),
                                         tooltip: "WhatsApp Chat",
                                         onPressed: () => _openWhatsApp(member.phoneNumber, member.fullName),
                                       ),
                                      IconButton(
                                        icon: const Icon(Icons.phone_rounded, color: AppTheme.goldAccent, size: 22),
                                        tooltip: "Direct Phone Call",
                                        onPressed: () => _makePhoneCall(member.phoneNumber),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showAdminRoleDialog(BuildContext context, MemberModel member) {
    final isCurrentlyAdmin = member.role.toLowerCase() == 'admin' || member.role.toLowerCase().contains('leader');
    final targetRole = isCurrentlyAdmin ? 'member' : 'admin';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E2C),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Manage Member Role",
                style: GoogleFonts.cinzel(
                  color: AppTheme.goldAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                member.fullName,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                "Current Role: ${member.role}",
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCurrentlyAdmin ? Colors.orange : AppTheme.shiningRed,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(isCurrentlyAdmin ? Icons.remove_moderator_rounded : Icons.admin_panel_settings_rounded, color: Colors.white),
                  label: Text(
                    isCurrentlyAdmin ? "Demote to Member" : "Promote to Admin",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      final supabase = Supabase.instance.client;
                      await supabase.from('profiles').update({'role': targetRole}).eq('phone', member.phoneNumber);
                    } catch (_) {}

                    setState(() {
                      final idx = _allMembers.indexWhere((m) => m.id == member.id);
                      if (idx != -1) {
                        _allMembers[idx] = MemberModel(
                          id: member.id,
                          fullName: member.fullName,
                          phoneNumber: member.phoneNumber,
                          avatarUrl: member.avatarUrl,
                          role: targetRole == 'admin' ? 'Admin' : 'Member',
                        );
                        _onSearchChanged();
                      }
                    });

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("${member.fullName} is now an ${targetRole.toUpperCase()}"),
                          backgroundColor: AppTheme.statusGreen,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
