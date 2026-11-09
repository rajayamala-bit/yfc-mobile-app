import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../theme/app_theme.dart';

class FullScreenVideoViewer extends StatefulWidget {
  final String videoUrl;

  const FullScreenVideoViewer({
    super.key,
    required this.videoUrl,
  });

  @override
  State<FullScreenVideoViewer> createState() => _FullScreenVideoViewerState();
}

class _FullScreenVideoViewerState extends State<FullScreenVideoViewer> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final url = widget.videoUrl.trim();
      if (url.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = "Invalid or empty video URL";
          });
        }
        return;
      }

      if (url.startsWith('http://') || url.startsWith('https://')) {
        _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url));
      } else if (url.startsWith('assets/')) {
        _videoPlayerController = VideoPlayerController.asset(url);
      } else if (File(url).existsSync()) {
        _videoPlayerController = VideoPlayerController.file(File(url));
      } else {
        _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url));
      }

      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio > 0
            ? _videoPlayerController!.value.aspectRatio
            : 16 / 9,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppTheme.shiningRed,
          handleColor: AppTheme.goldAccent,
          bufferedColor: AppTheme.goldAccent.withValues(alpha: 0.35),
          backgroundColor: Colors.white24,
        ),
        placeholder: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.shiningRed),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppTheme.shiningRed, size: 48),
                const SizedBox(height: 12),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Unable to play video: $e";
        });
      }
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Center video or loading/error indicator
            Center(
              child: _isLoading
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.shiningRed),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Loading video...",
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    )
                  : _errorMessage != null
                      ? Container(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.videocam_off_rounded, color: AppTheme.goldAccent, size: 56),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : _chewieController != null &&
                              _chewieController!.videoPlayerController.value.isInitialized
                          ? Chewie(controller: _chewieController!)
                          : const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.shiningRed),
                            ),
            ),

            // Top exit button overlay
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.5)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                  tooltip: "Close Video",
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
