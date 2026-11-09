import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChatMediaController extends ChangeNotifier {
  final List<XFile> _selectedPhotos = [];
  final List<XFile> _selectedVideos = [];
  final List<PlatformFile> _selectedDocuments = [];
  bool _isUploading = false;

  List<XFile> get selectedPhotos => List.unmodifiable(_selectedPhotos);
  List<XFile> get selectedVideos => List.unmodifiable(_selectedVideos);
  List<PlatformFile> get selectedDocuments => List.unmodifiable(_selectedDocuments);
  bool get isUploading => _isUploading;
  int get totalMediaCount => _selectedPhotos.length + _selectedVideos.length + _selectedDocuments.length;

  Future<void> pickPhotos(BuildContext context) async {
    if (_selectedPhotos.length >= 20) {
      if (context.mounted) {
        _showLimitDialog(context, "Image Limit Exceeded", "Only up to 20 images are allowed at a time.");
      }
      return;
    }

    try {
      final picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        List<XFile> validImages = images;
        if (_selectedPhotos.length + images.length > 20) {
          if (context.mounted) {
            _showLimitDialog(context, "Image Limit Exceeded", "Only up to 20 images are allowed at a time.");
          }
          final spaceLeft = 20 - _selectedPhotos.length;
          validImages = images.take(spaceLeft > 0 ? spaceLeft : 0).toList();
        }
        if (validImages.isNotEmpty) {
          _selectedPhotos.addAll(validImages);
          notifyListeners();
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Photo picking error: $e")),
        );
      }
    }
  }

  Future<void> pickVideos(BuildContext context) async {
    if (_selectedVideos.length >= 5) {
      if (context.mounted) {
        _showLimitDialog(context, "Video Limit Exceeded", "Only up to 5 videos are allowed at a time.");
      }
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        List<PlatformFile> selectedFiles = result.files;
        if (_selectedVideos.length + selectedFiles.length > 5) {
          if (context.mounted) {
            _showLimitDialog(context, "Video Limit Exceeded", "Only up to 5 videos are allowed at a time.");
          }
          final spaceLeft = 5 - _selectedVideos.length;
          selectedFiles = selectedFiles.take(spaceLeft > 0 ? spaceLeft : 0).toList();
        }

        for (final file in selectedFiles) {
          if (file.path != null) {
            final ioFile = File(file.path!);
            if (ioFile.existsSync() && ioFile.lengthSync() > 100 * 1024 * 1024) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${file.name} exceeds 100MB limit")),
                );
              }
              continue;
            }
            _selectedVideos.add(XFile(file.path!));
          }
        }
        notifyListeners();
      }
    } catch (_) {
      try {
        final picker = ImagePicker();
        final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
        if (video != null) {
          _selectedVideos.add(video);
          notifyListeners();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Video picking error: $e")),
          );
        }
      }
    }
  }

  void _showLimitDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0B132B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFD4AF37), width: 1),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK", style: TextStyle(color: Color(0xFFD90429), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> pickDocuments(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'xlsx', 'txt', 'pptx'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        _selectedDocuments.addAll(result.files);
        notifyListeners();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Document selection error: $e")),
        );
      }
    }
  }

  void removePhotoAt(int index) {
    if (index >= 0 && index < _selectedPhotos.length) {
      _selectedPhotos.removeAt(index);
      notifyListeners();
    }
  }

  void removeVideoAt(int index) {
    if (index >= 0 && index < _selectedVideos.length) {
      _selectedVideos.removeAt(index);
      notifyListeners();
    }
  }

  void removeDocumentAt(int index) {
    if (index >= 0 && index < _selectedDocuments.length) {
      _selectedDocuments.removeAt(index);
      notifyListeners();
    }
  }

  void clearAll() {
    _selectedPhotos.clear();
    _selectedVideos.clear();
    _selectedDocuments.clear();
    _isUploading = false;
    notifyListeners();
  }

  void setUploading(bool uploading) {
    _isUploading = uploading;
    notifyListeners();
  }
}
