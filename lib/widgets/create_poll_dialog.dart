import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class PollData {
  final String question;
  final List<String> options;
  final bool allowMultiple;

  PollData({
    required this.question,
    required this.options,
    required this.allowMultiple,
  });
}

class CreatePollDialog extends StatefulWidget {
  final bool isTelugu;

  const CreatePollDialog({
    super.key,
    required this.isTelugu,
  });

  static Future<PollData?> show(BuildContext context, {required bool isTelugu}) {
    return showDialog<PollData>(
      context: context,
      builder: (context) => CreatePollDialog(isTelugu: isTelugu),
    );
  }

  @override
  State<CreatePollDialog> createState() => _CreatePollDialogState();
}

class _CreatePollDialogState extends State<CreatePollDialog> {
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _allowMultiple = false;

  @override
  void dispose() {
    _questionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length < 10) {
      setState(() {
        _optionControllers.add(TextEditingController());
      });
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        final controller = _optionControllers.removeAt(index);
        controller.dispose();
      });
    }
  }

  void _submit() {
    final qText = _questionController.text.trim();
    final validOptions = _optionControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (qText.isNotEmpty && validOptions.length >= 2) {
      Navigator.pop(
        context,
        PollData(
          question: qText,
          options: validOptions,
          allowMultiple: _allowMultiple,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF0B132B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.goldAccent, width: 1.2),
      ),
      title: Row(
        children: [
          const Icon(Icons.poll_rounded, color: Color(0xFF9D4EDD)),
          const SizedBox(width: 8),
          Text(
            widget.isTelugu ? "ఫెలోషిప్ పోల్ సృష్టించండి" : "Create Fellowship Poll",
            style: GoogleFonts.cinzel(
              color: AppTheme.goldAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _questionController,
                style: TextStyle(color: isDark ? AppTheme.textLight : AppTheme.textDark, fontSize: 14),
                decoration: InputDecoration(
                  labelText: widget.isTelugu ? "పోల్ ప్రశ్న" : "Poll Question",
                  hintText: widget.isTelugu ? "ఉదా: తదుపరి బైబిల్ అధ్యయనం ఏమిటి?" : "e.g. Which Bible study topic next?",
                  hintStyle: TextStyle(color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted, fontSize: 12),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                widget.isTelugu ? "ఎంపికలు (కనీసం 2, గరిష్టం 10)" : "Options (Min 2, Max 10)",
                style: const TextStyle(
                  color: AppTheme.goldAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              ...List.generate(_optionControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _optionControllers[index],
                          style: TextStyle(color: isDark ? AppTheme.textLight : AppTheme.textDark, fontSize: 13.5),
                          decoration: InputDecoration(
                            labelText: widget.isTelugu ? "ఎంపిక ${index + 1}" : "Option ${index + 1}",
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                      if (_optionControllers.length > 2)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent, size: 20),
                          onPressed: () => _removeOption(index),
                          tooltip: widget.isTelugu ? "ఎంపికను తొలగించండి" : "Remove Option",
                        ),
                    ],
                  ),
                );
              }),

              if (_optionControllers.length < 10)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _addOption,
                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.goldAccent, size: 18),
                    label: Text(
                      widget.isTelugu ? "మరొక ఎంపికను జోడించండి (+)" : "Add Option (+)",
                      style: const TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                  ),
                ),

              const SizedBox(height: 10),
              const Divider(color: Colors.white24),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  widget.isTelugu ? "బహుళ సమాధానాలను అనుమతించు" : "Allow multiple answers",
                  style: TextStyle(
                    color: isDark ? AppTheme.textLight : AppTheme.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  _allowMultiple
                      ? (widget.isTelugu ? "సభ్యులు అనేక రకాలను ఎంచుకోవచ్చు" : "Select multiple options")
                      : (widget.isTelugu ? "ఒక ఎంపిక మాత్రమే అనుమతించబడుతుంది" : "Single choice only"),
                  style: TextStyle(
                    color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
                activeThumbColor: AppTheme.shiningRed,
                value: _allowMultiple,
                onChanged: (val) {
                  setState(() {
                    _allowMultiple = val;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.isTelugu ? "రద్దు చేయి" : "Cancel"),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.shiningRed,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(widget.isTelugu ? "పోల్ సృష్టించండి" : "Create Poll"),
        ),
      ],
    );
  }
}
