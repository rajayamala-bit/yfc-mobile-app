import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/chat_message_model.dart';
import '../../screens/full_screen_video_viewer.dart';
import '../../theme/app_theme.dart';

class MediaGridBubble extends StatelessWidget {
  final ChatMessage message;
  final Function(String url, String type)? onItemTap;

  const MediaGridBubble({
    super.key,
    required this.message,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final urls = message.mediaUrls;
    final totalCount = urls.length;

    if (totalCount == 0) return const SizedBox();

    if (totalCount == 1) {
      return Container(
        constraints: const BoxConstraints(maxHeight: 320),
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: _buildGridSubItem(context, 0),
        ),
      );
    }

    if (totalCount == 2) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 180,
          child: Row(
            children: [
              Expanded(child: _buildGridSubItem(context, 0)),
              const SizedBox(width: 4),
              Expanded(child: _buildGridSubItem(context, 1)),
            ],
          ),
        ),
      );
    }

    if (totalCount == 3) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 210,
          child: Row(
            children: [
              Expanded(
                flex: 6, // 60% width
                child: _buildGridSubItem(context, 0),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 4, // 40% width
                child: Column(
                  children: [
                    Expanded(child: _buildGridSubItem(context, 1)),
                    const SizedBox(height: 4),
                    Expanded(child: _buildGridSubItem(context, 2)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 4 or more items (2x2 Grid with +N overlay on 4th item)
    final remainingCount = totalCount - 3;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 220,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildGridSubItem(context, 0)),
                  const SizedBox(width: 4),
                  Expanded(child: _buildGridSubItem(context, 1)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildGridSubItem(context, 2)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildGridSubItem(context, 3),
                        if (totalCount > 4)
                          GestureDetector(
                            onTap: () => _openFullscreenGallery(context, 3),
                            child: Container(
                              color: Colors.black54,
                              child: Center(
                                child: Text(
                                  "+$remainingCount",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridSubItem(BuildContext context, int index) {
    final urls = message.mediaUrls;
    final types = message.mediaTypes;
    final url = index < urls.length ? urls[index] : '';
    final type = index < types.length ? types[index] : 'image';
    final isVideo = type == 'video';

    Widget mediaWidget;
    if (isVideo) {
      mediaWidget = Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(Icons.movie_rounded, color: Colors.white24, size: 48),
        ),
      );
    } else if (url.startsWith('http')) {
      mediaWidget = Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset('assets/images/news_jerusalem.jpg', fit: BoxFit.cover),
      );
    } else if (url.isNotEmpty && File(url).existsSync()) {
      mediaWidget = Image.file(File(url), fit: BoxFit.cover);
    } else if (url.startsWith('assets/')) {
      mediaWidget = Image.asset(url, fit: BoxFit.cover);
    } else {
      mediaWidget = Image.asset('assets/images/news_jerusalem.jpg', fit: BoxFit.cover);
    }

    return GestureDetector(
      onTap: () {
        if (isVideo) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FullScreenVideoViewer(videoUrl: url),
            ),
          );
        } else if (onItemTap != null) {
          onItemTap!(url, type);
        } else {
          _openFullscreenGallery(context, index);
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          mediaWidget,
          if (isVideo) ...[
            Container(color: Colors.black26),
            const Center(
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.black54,
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
            Positioned(
              bottom: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam_rounded, color: AppTheme.goldAccent, size: 10),
                    SizedBox(width: 4),
                    Text(
                      "01:30 • HD",
                      style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openFullscreenGallery(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullscreenGalleryViewer(
          mediaUrls: message.mediaUrls,
          mediaTypes: message.mediaTypes,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

class FullscreenGalleryViewer extends StatefulWidget {
  final List<String> mediaUrls;
  final List<String> mediaTypes;
  final int initialIndex;

  const FullscreenGalleryViewer({
    super.key,
    required this.mediaUrls,
    required this.mediaTypes,
    this.initialIndex = 0,
  });

  @override
  State<FullscreenGalleryViewer> createState() => _FullscreenGalleryViewerState();
}

class _FullscreenGalleryViewerState extends State<FullscreenGalleryViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // PageView Gallery
            PageView.builder(
              controller: _pageController,
              itemCount: widget.mediaUrls.length,
              onPageChanged: (idx) {
                setState(() {
                  _currentIndex = idx;
                });
              },
              itemBuilder: (context, index) {
                final url = widget.mediaUrls[index];
                final type = index < widget.mediaTypes.length ? widget.mediaTypes[index] : 'image';
                final isVideo = type == 'video';

                if (isVideo) {
                  return FullScreenVideoViewer(videoUrl: url);
                }

                Widget imgWidget;
                if (url.startsWith('http')) {
                  imgWidget = Image.network(url, fit: BoxFit.contain);
                } else if (url.isNotEmpty && File(url).existsSync()) {
                  imgWidget = Image.file(File(url), fit: BoxFit.contain);
                } else if (url.startsWith('assets/')) {
                  imgWidget = Image.asset(url, fit: BoxFit.contain);
                } else {
                  imgWidget = Image.asset('assets/images/news_jerusalem.jpg', fit: BoxFit.contain);
                }

                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(child: imgWidget),
                );
              },
            ),

            // Header Top Bar
            Positioned(
              top: 10,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${_currentIndex + 1} of ${widget.mediaUrls.length}",
                    style: GoogleFonts.cinzel(
                      color: AppTheme.goldAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
