import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/berean_ai_service.dart';
import '../theme/app_theme.dart';
import 'floating_bubbles_background.dart';

class BereanChatMessage {
  String text;
  final bool isUser;
  List<String>? citations;
  final String? teluguText;
  bool isError;
  bool isGenerating;

  BereanChatMessage({
    required this.text,
    required this.isUser,
    this.citations,
    this.teluguText,
    this.isError = false,
    this.isGenerating = false,
  });
}

typedef BereanScreen = BereanAiWidget;

class BereanAiWidget extends StatefulWidget {
  final String? initialQuery;
  final String? preferredLanguage;

  const BereanAiWidget({
    super.key,
    this.initialQuery,
    this.preferredLanguage,
  });

  @override
  State<BereanAiWidget> createState() => _BereanAiWidgetState();
}

class _BereanAiWidgetState extends State<BereanAiWidget> {
  final TextEditingController _queryController = TextEditingController();
  final List<BereanChatMessage> _chatHistory = [];
  bool _isLoading = false;
  String _lastFailedQuery = "";
  String _lastUserQuery = "";
  String _selectedLanguage = 'Bilingual'; // Default to Bilingual / ఉభయ భాషలు

  @override
  void initState() {
    super.initState();
    if (widget.preferredLanguage != null && widget.preferredLanguage!.isNotEmpty) {
      _selectedLanguage = widget.preferredLanguage!;
    }
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _askBerean(widget.initialQuery!);
        }
      });
    }
  }

  void _askBerean(String query) {
    if (query.trim().isEmpty) return;

    final userQuery = query.trim();
    final activeMessage = BereanChatMessage(text: '', isUser: false, isGenerating: true);

    setState(() {
      _lastFailedQuery = userQuery;
      _lastUserQuery = userQuery;
      _chatHistory.add(BereanChatMessage(text: userQuery, isUser: true));
      _chatHistory.add(activeMessage);
      _isLoading = true;
      _queryController.clear();
    });

    BereanAIService.streamAnswer(
      userQuestion: userQuery,
      language: _selectedLanguage,
    ).listen(
      (chunk) {
        if (mounted) {
          setState(() {
            activeMessage.text += chunk;
          });
        }
      },
      onDone: () {
        if (mounted) {
          setState(() {
            activeMessage.isGenerating = false;
            _isLoading = false;
          });
        }
      },
      onError: (_) {
        if (mounted) {
          setState(() {
            activeMessage.isGenerating = false;
            _isLoading = false;
          });
        }
      },
    );
  }

  void _regenerateInSelectedLanguage({bool replaceLast = true}) {
    if (_lastUserQuery.isEmpty || _isLoading) return;

    final activeMessage = BereanChatMessage(text: '', isUser: false, isGenerating: true);

    setState(() {
      _isLoading = true;
      if (replaceLast && _chatHistory.isNotEmpty && !_chatHistory.last.isUser) {
        _chatHistory[_chatHistory.length - 1] = activeMessage;
      } else {
        _chatHistory.add(activeMessage);
      }
    });

    BereanAIService.streamAnswer(
      userQuestion: _lastUserQuery,
      language: _selectedLanguage,
    ).listen(
      (chunk) {
        if (mounted) {
          setState(() {
            activeMessage.text += chunk;
          });
        }
      },
      onDone: () {
        if (mounted) {
          setState(() {
            activeMessage.isGenerating = false;
            _isLoading = false;
          });
        }
      },
      onError: (_) {
        if (mounted) {
          setState(() {
            activeMessage.isGenerating = false;
            _isLoading = false;
          });
        }
      },
    );
  }

  void _clearChat() {
    setState(() {
      _chatHistory.clear();
      _lastUserQuery = "";
      _lastFailedQuery = "";
      _queryController.clear();
    });
  }

  void _retryLastQuery() {
    if (_lastFailedQuery.isNotEmpty) {
      _askBerean(_lastFailedQuery);
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Berean AI response copied to clipboard!"),
        backgroundColor: AppTheme.shiningRed,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildLanguageSelectorPill(bool isDark) {
    final modes = [
      {'key': 'English', 'label': 'English'},
      {'key': 'Telugu', 'label': 'తెలుగు (Telugu)'},
      {'key': 'Bilingual', 'label': 'Bilingual / ఉభయ భాషలు'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceCardDark : AppTheme.surfaceCardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Row(
        children: modes.map((mode) {
          final isSelected = _selectedLanguage == mode['key'];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                final newLang = mode['key']!;
                if (_selectedLanguage != newLang) {
                  setState(() => _selectedLanguage = newLang);
                  if (_lastUserQuery.isNotEmpty && !_isLoading) {
                    _regenerateInSelectedLanguage(replaceLast: true);
                  }
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.shiningRed : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  mode['label']!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? AppTheme.textLight : AppTheme.textDark),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSuggestedQueries(bool isDark, bool isTelugu) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isTelugu ? "సూచించబడిన బైబిల్ ప్రశ్నలు:" : "Suggested Biblical Queries:",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.textLight : const Color(0xFF0B132B),
            ),
          ),
          const SizedBox(height: 12),
          _buildSuggestedCard(
            icon: "✨",
            text: "What is Berean AI & How to use it?",
            onTap: () => _askBerean("What is Berean AI and how can it help my biblical study?"),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildSuggestedCard(
            icon: "💡",
            text: "Explain today's study passage",
            onTap: () => _askBerean("Explain today's scripture study passage in depth."),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildSuggestedCard(
            icon: "🕊️",
            text: "Verses for peace and anxiety (తెలుగు & English)",
            onTap: () => _askBerean("Share key scriptures for peace and overcoming anxiety with Telugu and English references."),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildSuggestedCard(
            icon: "📖",
            text: "Who were the Bereans in Acts 17?",
            onTap: () => _askBerean("Who were the Bereans in Acts 17 and why are they praised?"),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedCard({
    required String icon,
    required String text,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceCardDark : const Color(0xFFFFFDF5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.45), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: isDark ? AppTheme.textLight : const Color(0xFF0B132B),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.goldAccent),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isTelugu = appState.isTelugu;
    final isDark = appState.isDarkMode;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            if (Navigator.canPop(context))
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.goldAccent),
                onPressed: () => Navigator.pop(context),
              ),
            const Icon(Icons.auto_awesome_rounded, color: AppTheme.goldAccent, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isTelugu ? "బేరయ స్క్రిప్చరల్ AI బోట్" : "Berean Scriptural AI Bot",
                style: AppTheme.getScriptTextStyle(
                  isTelugu: isTelugu,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.textLight : const Color(0xFF0B132B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.shiningRed),
              tooltip: isTelugu ? "చాట్ ఖాళీ చేయండి" : "Clear Chat",
              onPressed: _clearChat,
            ),
          ],
        ),
      ),
      body: FloatingBubblesBackground(
        child: Column(
          children: [
            _buildLanguageSelectorPill(isDark),
            // Scrollable Conversation Stream / Suggested Queries
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    if (_chatHistory.isEmpty)
                      _buildSuggestedQueries(isDark, isTelugu)
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _chatHistory.length,
                        itemBuilder: (context, index) {
                          final msg = _chatHistory[index];
                          return _buildChatBubble(msg, isTelugu);
                        },
                      ),
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surfaceCardDark : Colors.white,
                border: Border(top: BorderSide(color: AppTheme.goldAccent.withValues(alpha: 0.3))),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _queryController,
                        style: TextStyle(color: isDark ? AppTheme.textLight : AppTheme.textDark),
                        decoration: InputDecoration(
                          hintText: isTelugu ? "వాక్యాన్ని గురించి విచారించండి..." : "Ask a biblical question...",
                          hintStyle: TextStyle(color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted),
                          filled: true,
                          fillColor: isDark ? AppTheme.bgPrimaryDark : const Color(0xFFFFF5F6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
                          ),
                        ),
                        onSubmitted: _askBerean,
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: AppTheme.shiningRed,
                      radius: 20,
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                        onPressed: () => _askBerean(_queryController.text),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(BereanChatMessage msg, bool isTelugu) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        decoration: BoxDecoration(
          color: msg.isUser
              ? AppTheme.shiningRed.withValues(alpha: 0.12)
              : (isDark ? AppTheme.surfaceCardDark : AppTheme.surfaceCardLight),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: msg.isError
                ? Colors.red
                : (msg.isUser
                    ? AppTheme.shiningRed.withValues(alpha: 0.4)
                    : AppTheme.goldAccent.withValues(alpha: 0.35)),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shiningRed.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!msg.isUser)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppTheme.goldAccent, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        "Berean AI",
                        style: GoogleFonts.cinzel(color: AppTheme.goldAccent, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (msg.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 15, color: AppTheme.goldAccent),
                          tooltip: "Copy Response",
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                          onPressed: () => _copyToClipboard(msg.text),
                        ),
                      if (_lastUserQuery.isNotEmpty && !_isLoading)
                        GestureDetector(
                          onTap: () => _regenerateInSelectedLanguage(replaceLast: true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            margin: const EdgeInsets.only(left: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.goldAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.g_translate_rounded, size: 12, color: AppTheme.goldAccent),
                                SizedBox(width: 4),
                                Text(
                                  "Translate",
                                  style: TextStyle(color: AppTheme.goldAccent, fontSize: 10.5, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            if (!msg.isUser) const SizedBox(height: 6),

            // Text Response / Inline Generation Spinner
            if (msg.isGenerating && msg.text.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.shiningRed),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isTelugu ? "ఆలోచిస్తోంది..." : "Searching Scriptures...",
                      style: TextStyle(
                        color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              )
            else
              SelectableText(
                msg.text,
                style: GoogleFonts.inter(
                  color: isDark ? AppTheme.textLight : AppTheme.textDark,
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: msg.isUser ? FontWeight.w600 : FontWeight.normal,
                ),
              ),

            // Telugu Response
            if (msg.teluguText != null && msg.teluguText!.isNotEmpty) ...[
              const SizedBox(height: 8),
              SelectableText(
                msg.teluguText!,
                style: GoogleFonts.notoSansTelugu(
                  color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ],

            // Retry Button for error state
            if (msg.isError) ...[
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _retryLastQuery,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.shiningRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(isTelugu ? "మళ్లీ ప్రయత్నించండి" : "Retry Query"),
              ),
            ],

            // Verse Citations Pills
            if (msg.citations != null && msg.citations!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: msg.citations!.map((c) {
                  return Chip(
                    backgroundColor: isDark ? AppTheme.bgPrimaryDark : Colors.white,
                    side: BorderSide(color: AppTheme.goldAccent.withValues(alpha: 0.4)),
                    label: Text(
                      "📖 $c",
                      style: const TextStyle(color: AppTheme.shiningRed, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
