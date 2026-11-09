import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class PollVoter {
  final String userId;
  final String userName;
  final String avatarUrl;

  PollVoter({
    required this.userId,
    required this.userName,
    required this.avatarUrl,
  });
}

class PollOptionModel {
  final String id;
  final String text;
  final List<PollVoter> voters;

  PollOptionModel({
    required this.id,
    required this.text,
    required this.voters,
  });
}

class PollModel {
  final String id;
  final String question;
  final bool allowMultiple;
  final List<PollOptionModel> options;

  PollModel({
    required this.id,
    required this.question,
    required this.allowMultiple,
    required this.options,
  });
}

class PollMessageWidget extends StatefulWidget {
  final PollModel poll;
  final bool isDark;

  const PollMessageWidget({
    super.key,
    required this.poll,
    required this.isDark,
  });

  @override
  State<PollMessageWidget> createState() => _PollMessageWidgetState();
}

class _PollMessageWidgetState extends State<PollMessageWidget> {
  late PollModel _poll;

  @override
  void initState() {
    super.initState();
    _poll = widget.poll;
  }

  int get _totalVotes {
    int total = 0;
    for (final opt in _poll.options) {
      total += opt.voters.length;
    }
    return total;
  }

  bool _hasUserVotedForOption(PollOptionModel option, String userId) {
    return option.voters.any((v) => v.userId == userId || v.userName == userId);
  }

  void _toggleVote(PollOptionModel targetOption) {
    final appState = Provider.of<AppState>(context, listen: false);
    final currentUserId = appState.profileName.isNotEmpty ? appState.profileName : "You";
    final currentUserAvatar = appState.avatarUrl.isNotEmpty ? appState.avatarUrl : "👤";

    setState(() {
      final isAlreadyVoted = _hasUserVotedForOption(targetOption, currentUserId);

      if (!_poll.allowMultiple) {
        // Single choice: deselect all other options
        for (final opt in _poll.options) {
          opt.voters.removeWhere((v) => v.userId == currentUserId || v.userName == currentUserId);
        }
        if (!isAlreadyVoted) {
          targetOption.voters.add(
            PollVoter(
              userId: currentUserId,
              userName: currentUserId,
              avatarUrl: currentUserAvatar,
            ),
          );
        }
      } else {
        // Multiple choice
        if (isAlreadyVoted) {
          targetOption.voters.removeWhere((v) => v.userId == currentUserId || v.userName == currentUserId);
        } else {
          targetOption.voters.add(
            PollVoter(
              userId: currentUserId,
              userName: currentUserId,
              avatarUrl: currentUserAvatar,
            ),
          );
        }
      }
    });
  }

  void _showViewVotesModal(BuildContext context) {
    final isDark = widget.isDark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0B132B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 14),

              Row(
                children: [
                  const Icon(Icons.poll_rounded, color: Color(0xFF9D4EDD), size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _poll.question,
                      style: GoogleFonts.cinzel(
                        color: AppTheme.goldAccent,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "Total Votes: $_totalVotes",
                style: TextStyle(
                  color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),

              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _poll.options.length,
                  itemBuilder: (context, optIdx) {
                    final opt = _poll.options[optIdx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF141C2E) : const Color(0xFFF5F6FA),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                opt.text,
                                style: TextStyle(
                                  color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                              Text(
                                "${opt.voters.length} votes",
                                style: const TextStyle(
                                  color: AppTheme.shiningRed,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          if (opt.voters.isEmpty)
                            const Text(
                              "No votes yet",
                              style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: opt.voters.map((voter) {
                                return Chip(
                                  backgroundColor: AppTheme.goldAccent.withValues(alpha: 0.15),
                                  side: BorderSide(color: AppTheme.goldAccent.withValues(alpha: 0.4)),
                                  avatar: CircleAvatar(
                                    backgroundColor: AppTheme.shiningRed,
                                    child: Text(
                                      voter.avatarUrl.isNotEmpty && voter.avatarUrl.length <= 2
                                          ? voter.avatarUrl
                                          : (voter.userName.isNotEmpty ? voter.userName[0].toUpperCase() : "👤"),
                                      style: const TextStyle(fontSize: 10, color: Colors.white),
                                    ),
                                  ),
                                  label: Text(
                                    voter.userName,
                                    style: TextStyle(
                                      color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currentUserId = appState.profileName.isNotEmpty ? appState.profileName : "You";
    final isDark = widget.isDark;

    return Container(
      width: 290,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B132B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF9D4EDD).withValues(alpha: 0.6),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9D4EDD).withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poll Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("📊", style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _poll.question,
                      style: GoogleFonts.cinzel(
                        color: AppTheme.goldAccent,
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _poll.allowMultiple ? "Select multiple" : "Select 1",
                      style: TextStyle(
                        color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Poll Option List Items
          ..._poll.options.map((opt) {
            final isVoted = _hasUserVotedForOption(opt, currentUserId);
            final voteCount = opt.voters.length;
            final pct = _totalVotes > 0 ? (voteCount / _totalVotes) : 0.0;
            final pctInt = (pct * 100).round();

            return GestureDetector(
              onTap: () => _toggleVote(opt),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                height: 44,
                child: Stack(
                  children: [
                    // Background Animated Progress Fill
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF161E36) : const Color(0xFFF3F4F8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isVoted ? const Color(0xFF25D366) : AppTheme.goldAccent.withValues(alpha: 0.25),
                          width: isVoted ? 1.6 : 1.0,
                        ),
                      ),
                    ),

                    // Progress Fill Bar
                    FractionallySizedBox(
                      widthFactor: pct.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isVoted
                              ? const Color(0xFF25D366).withValues(alpha: 0.25)
                              : const Color(0xFF9D4EDD).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    // Content Row: Choice Icon, Title & Percentage Vote Label
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          Icon(
                            _poll.allowMultiple
                                ? (isVoted ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded)
                                : (isVoted ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded),
                            color: isVoted ? const Color(0xFF25D366) : AppTheme.goldAccent,
                            size: 19,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              opt.text,
                              style: TextStyle(
                                color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                fontSize: 13,
                                fontWeight: isVoted ? FontWeight.bold : FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "$voteCount ($pctInt%)",
                            style: TextStyle(
                              color: isVoted ? const Color(0xFF25D366) : (isDark ? AppTheme.textMutedDark : AppTheme.textMuted),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 6),

          // View Votes Link Button
          GestureDetector(
            onTap: () => _showViewVotesModal(context),
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  "View votes ($_totalVotes)",
                  style: const TextStyle(
                    color: Color(0xFF9D4EDD),
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
