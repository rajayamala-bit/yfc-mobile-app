import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'chat_media_controller.dart';

class ChatAttachmentSheet extends StatelessWidget {
  final bool isTelugu;
  final ChatMediaController mediaController;
  final VoidCallback? onCameraSelected;
  final VoidCallback? onPollSelected;

  const ChatAttachmentSheet({
    super.key,
    required this.isTelugu,
    required this.mediaController,
    this.onCameraSelected,
    this.onPollSelected,
  });

  static void show(
    BuildContext context, {
    required bool isTelugu,
    required ChatMediaController mediaController,
    VoidCallback? onCameraSelected,
    VoidCallback? onPollSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B132B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: AppTheme.goldAccent, width: 1.2),
      ),
      builder: (context) => ChatAttachmentSheet(
        isTelugu: isTelugu,
        mediaController: mediaController,
        onCameraSelected: onCameraSelected,
        onPollSelected: onPollSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.goldAccent.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isTelugu ? "అటాచ్‌మెంట్ ఎంచుకోండి" : "Select Attachment",
              style: GoogleFonts.cinzel(
                color: AppTheme.goldAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 18,
              runSpacing: 18,
              alignment: WrapAlignment.center,
              children: [
                // 1. Photo Option (Up to 20 photos)
                _buildTile(
                  icon: Icons.photo_library_rounded,
                  color: const Color(0xFFFF8FA3),
                  label: isTelugu ? "ఫోటోలు (20)" : "Photos (Up to 20)",
                  onTap: () {
                    Navigator.pop(context);
                    mediaController.pickPhotos(context);
                  },
                ),

                // 2. Video Option (Up to 5 videos)
                _buildTile(
                  icon: Icons.video_library_rounded,
                  color: const Color(0xFF00B4D8),
                  label: isTelugu ? "వీడియోలు (5)" : "Videos (Up to 5)",
                  onTap: () {
                    Navigator.pop(context);
                    mediaController.pickVideos(context);
                  },
                ),

                // 3. Document / PDF Option
                _buildTile(
                  icon: Icons.picture_as_pdf_rounded,
                  color: const Color(0xFFFFB703),
                  label: isTelugu ? "డాక్యుమెంట్" : "Document / PDF",
                  onTap: () {
                    Navigator.pop(context);
                    mediaController.pickDocuments(context);
                  },
                ),

                // 4. Camera Option
                _buildTile(
                  icon: Icons.camera_alt_rounded,
                  color: const Color(0xFF48CAE4),
                  label: isTelugu ? "కెమెరా" : "Camera",
                  onTap: () {
                    Navigator.pop(context);
                    if (onCameraSelected != null) onCameraSelected!();
                  },
                ),

                // 5. Create Poll Option
                _buildTile(
                  icon: Icons.poll_rounded,
                  color: const Color(0xFF9D4EDD),
                  label: isTelugu ? "పోల్" : "Create Poll",
                  onTap: () {
                    Navigator.pop(context);
                    if (onPollSelected != null) onPollSelected!();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: color.withValues(alpha: 0.18),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Colors.white),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
