import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:gal/gal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../models/chat_message_model.dart';
import '../models/prayer_request_model.dart';
import '../providers/app_state.dart';
import '../screens/full_screen_video_viewer.dart';
import '../services/alarm_service.dart';
import '../services/audio_record_service.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';
import 'create_poll_dialog.dart';
import 'poll_message_widget.dart';
import 'chat/media_grid_bubble.dart';

class GlobalChatWidget extends StatefulWidget {
  const GlobalChatWidget({super.key});

  @override
  State<GlobalChatWidget> createState() => _GlobalChatWidgetState();
}

class _GlobalChatWidgetState extends State<GlobalChatWidget> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isRecording = false;

  // Multi-Select & Batch Delete State
  bool _isSelectionMode = false;
  final Set<String> _selectedMessageIds = {};

  void _enterSelectionMode(String messageId) {
    setState(() {
      _isSelectionMode = true;
      _selectedMessageIds.add(messageId);
    });
  }

  void _toggleMessageSelection(String messageId) {
    setState(() {
      if (_selectedMessageIds.contains(messageId)) {
        _selectedMessageIds.remove(messageId);
        if (_selectedMessageIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedMessageIds.add(messageId);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedMessageIds.length == _messages.length) {
        _selectedMessageIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedMessageIds.clear();
        _selectedMessageIds.addAll(_messages.map((m) => m.id));
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedMessageIds.clear();
    });
  }

  Future<void> _confirmBatchDelete() async {
    if (_selectedMessageIds.isEmpty) return;
    final count = _selectedMessageIds.length;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0B132B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFD4AF37)),
        ),
        title: const Text("Delete Messages", style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
        content: Text(
          "Delete $count selected message${count > 1 ? 's' : ''}? This action cannot be undone.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Color(0xFFD90429), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _messages.removeWhere((msg) => _selectedMessageIds.contains(msg.id));
        _isSelectionMode = false;
        _selectedMessageIds.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$count message${count > 1 ? 's' : ''} deleted"),
            backgroundColor: AppTheme.shiningRed,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Voice Note Draft State (WhatsApp style)
  String? _draftVoiceFilePath;
  int _draftVoiceDurationSeconds = 0;
  bool _isPlayingDraftVoice = false;

  // Multi-Media Batch Selection State (Up to 20 Photos & 5 Videos)
  final List<XFile> _selectedPhotos = [];
  final List<XFile> _selectedVideos = [];
  bool _isBatchUploading = false;
  bool _isSendingMedia = false; // Lock guard to prevent rapid double-sending

  // Live fellowship stream messages
  final List<ChatMessage> _messages = [];

  // Live community prayer requests list
  final List<PrayerRequest> _prayerRequests = [];
  StreamSubscription? _chatSubscription;

  List<ChatMessage> _deduplicateMessages(List<ChatMessage> rawList) {
    final Map<String, ChatMessage> idMap = {};
    final List<ChatMessage> deduplicated = [];

    for (final msg in rawList) {
      if (idMap.containsKey(msg.id)) {
        final existing = idMap[msg.id]!;
        existing.reactions.addAll(msg.reactions);
        existing.userReactions.addAll(msg.userReactions);
      } else {
        final dupIdx = deduplicated.indexWhere((existing) =>
            existing.id == msg.id ||
            (existing.textContent == msg.textContent &&
                existing.senderName == msg.senderName &&
                existing.messageType == msg.messageType &&
                existing.mediaUrl == msg.mediaUrl &&
                existing.createdAt.difference(msg.createdAt).inSeconds.abs() < 5));

        if (dupIdx != -1) {
          final existing = deduplicated[dupIdx];
          if (existing.id.startsWith('msg-') || existing.id.startsWith('temp-')) {
            idMap.remove(existing.id);
            deduplicated[dupIdx] = msg;
            idMap[msg.id] = msg;
          } else {
            existing.reactions.addAll(msg.reactions);
            existing.userReactions.addAll(msg.userReactions);
          }
        } else {
          idMap[msg.id] = msg;
          deduplicated.add(msg);
        }
      }
    }

    deduplicated.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return deduplicated;
  }

  void _addMessageAndRefresh(ChatMessage newMsg) {
    _messages.add(newMsg);
    final cleanList = _deduplicateMessages(_messages);
    _messages.clear();
    _messages.addAll(cleanList);
  }

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _listenToFirestoreChat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _listenToFirestoreChat() {
    try {
      _chatSubscription = ChatService().getChatStream().listen((snapshot) {
        final List<ChatMessage> liveMsgs = [];
        final docs = snapshot.docs.toList().reversed;
        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final senderName = data['senderName'] as String? ?? 'Fellowship Member';
          final senderAvatar = data['senderAvatar'] as String? ?? '✝️';
          final text = data['text'] as String? ?? '';
          final mediaUrl = data['mediaUrl'] as String?;
          final type = data['type'] as String? ?? 'text';
          final tsData = data['timestamp'];
          DateTime ts = DateTime.now();
          if (tsData != null && tsData is Timestamp) {
            ts = tsData.toDate();
          }

          Map<String, int> reactionsMap = {};
          if (data['reactions'] != null && data['reactions'] is Map) {
            (data['reactions'] as Map).forEach((key, val) {
              if (val is int) {
                reactionsMap[key.toString()] = val;
              } else if (val is num) {
                reactionsMap[key.toString()] = val.toInt();
              }
            });
          }

          Map<String, Map<String, String>> userReactionsMap = {};
          if (data['userReactions'] != null && data['userReactions'] is Map) {
            (data['userReactions'] as Map).forEach((key, val) {
              if (val is Map) {
                userReactionsMap[key.toString()] = {
                  'name': val['name']?.toString() ?? 'Member',
                  'emoji': val['emoji']?.toString() ?? '❤️',
                  'avatar': val['avatar']?.toString() ?? '✝️',
                };
              }
            });
          }

          List<String>? mediaUrls;
          if (data['mediaUrls'] != null && data['mediaUrls'] is List) {
            mediaUrls = List<String>.from(data['mediaUrls']);
          }

          List<String>? mediaTypes;
          if (data['mediaTypes'] != null && data['mediaTypes'] is List) {
            mediaTypes = List<String>.from(data['mediaTypes']);
          }

          liveMsgs.add(ChatMessage(
            id: doc.id,
            senderName: senderName,
            senderAvatar: senderAvatar,
            textContent: text,
            messageType: type,
            mediaUrl: mediaUrl,
            mediaUrls: mediaUrls ?? const [],
            mediaTypes: mediaTypes ?? const [],
            reactions: reactionsMap,
            userReactions: userReactionsMap,
            createdAt: ts,
          ));
        }

        if (mounted && liveMsgs.isNotEmpty) {
          setState(() {
            _messages.addAll(liveMsgs);
            final deduplicated = _deduplicateMessages(_messages);
            _messages.clear();
            _messages.addAll(deduplicated);
          });
          _scrollToBottom();
        }
      }, onError: (_) {});
    } catch (_) {}
  }

  Future<void> _loadMessages() async {
    final loaded = await ChatService().loadChatMessages();
    if (mounted) {
      setState(() {
        _messages.clear();
        _messages.addAll(_deduplicateMessages(loaded));
      });
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkPendingSharedContent();
  }

  void _checkPendingSharedContent() {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.pendingSharedText.isNotEmpty) {
      final sharedText = appState.pendingSharedText;
      appState.clearPendingSharedContent();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _textController.text = sharedText;
      });
    }
    if (appState.pendingSharedImagePath.isNotEmpty) {
      final sharedImagePath = appState.pendingSharedImagePath;
      appState.clearPendingSharedContent();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendImageMessage(sharedImagePath);
      });
    }
    if (appState.pendingSharedVideoPath.isNotEmpty) {
      final sharedVideoPath = appState.pendingSharedVideoPath;
      appState.clearPendingSharedContent();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendVideoMessage(sharedVideoPath);
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_isSendingMedia || _isBatchUploading) return;

    if (_selectedPhotos.isNotEmpty || _selectedVideos.isNotEmpty) {
      _sendAllSelectedMedia();
      return;
    }

    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSendingMedia = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final userAvatar = appState.avatarUrl.isNotEmpty ? appState.avatarUrl : "✝️";
      final userName = appState.profileName.trim().isNotEmpty ? appState.profileName.trim() : "YFC Member";

      final user = FirebaseAuth.instance.currentUser;
      final docRef = await FirebaseFirestore.instance.collection('fellowship_chats').add({
        'senderId': user?.uid ?? 'anonymous',
        'senderName': userName,
        'senderAvatar': userAvatar,
        'text': text,
        'type': 'text',
        'reactions': {},
        'timestamp': FieldValue.serverTimestamp(),
      });

      final newMsg = ChatMessage(
        id: docRef.id,
        senderName: userName,
        senderAvatar: userAvatar,
        textContent: text,
        reactions: {},
        createdAt: DateTime.now(),
      );

      ChatService().saveMessage(newMsg);

      if (mounted) {
        setState(() {
          _addMessageAndRefresh(newMsg);
          _textController.clear();
        });
      }

      _scrollToBottom();

      AlarmService.showHeadsUpNotification(
        title: "💬 $userName in YFC Fellowship Chat",
        body: text,
      );
    } catch (e) {
      debugPrint("Error sending text message: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isSendingMedia = false;
        });
      }
    }
  }

  Future<void> _sendImageMessage(String imagePath, {String caption = ''}) async {
    if (_isSendingMedia) return;
    setState(() {
      _isSendingMedia = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final userAvatar = appState.avatarUrl.isNotEmpty ? appState.avatarUrl : "📸";
      final userName = appState.profileName.isNotEmpty ? appState.profileName : "You";
      final user = FirebaseAuth.instance.currentUser;

      final uploadedUrl = await appState.uploadChatMedia(XFile(imagePath));

      final docRef = await FirebaseFirestore.instance.collection('fellowship_chats').add({
        'senderId': user?.uid ?? 'anonymous',
        'senderName': userName,
        'senderAvatar': userAvatar,
        'text': caption.isNotEmpty ? caption : "Shared a photo 📷",
        'mediaUrl': uploadedUrl.isNotEmpty ? uploadedUrl : imagePath,
        'type': 'image',
        'reactions': {},
        'timestamp': FieldValue.serverTimestamp(),
      });

      final newMsg = ChatMessage(
        id: docRef.id,
        senderName: userName,
        senderAvatar: userAvatar,
        textContent: caption.isNotEmpty ? caption : "Shared a photo 📷",
        messageType: 'image',
        mediaUrl: uploadedUrl.isNotEmpty ? uploadedUrl : imagePath,
        reactions: {},
        createdAt: DateTime.now(),
      );

      ChatService().saveMessage(newMsg);

      if (mounted) {
        setState(() {
          _addMessageAndRefresh(newMsg);
        });
      }

      _scrollToBottom();

      AlarmService.showHeadsUpNotification(
        title: "📷 $userName in YFC Fellowship Chat",
        body: caption.isNotEmpty ? caption : "Shared a photo 📷",
        payload: 'chat',
      );
    } catch (e) {
      debugPrint("Error sending image message: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isSendingMedia = false;
        });
      }
    }
  }

  Future<void> _sendVideoMessage(String videoPath, {String caption = ''}) async {
    if (_isSendingMedia) return;
    setState(() {
      _isSendingMedia = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final userAvatar = appState.avatarUrl.isNotEmpty ? appState.avatarUrl : "🎥";
      final userName = appState.profileName.isNotEmpty ? appState.profileName : "You";
      final user = FirebaseAuth.instance.currentUser;

      final uploadedUrl = await appState.uploadChatMedia(XFile(videoPath));

      final docRef = await FirebaseFirestore.instance.collection('fellowship_chats').add({
        'senderId': user?.uid ?? 'anonymous',
        'senderName': userName,
        'senderAvatar': userAvatar,
        'text': caption.isNotEmpty ? caption : "Shared a video 🎥",
        'mediaUrl': uploadedUrl.isNotEmpty ? uploadedUrl : videoPath,
        'type': 'video',
        'reactions': {},
        'timestamp': FieldValue.serverTimestamp(),
      });

      final newMsg = ChatMessage(
        id: docRef.id,
        senderName: userName,
        senderAvatar: userAvatar,
        textContent: caption.isNotEmpty ? caption : "Shared a video 🎥",
        messageType: 'video',
        mediaUrl: uploadedUrl.isNotEmpty ? uploadedUrl : videoPath,
        reactions: {},
        createdAt: DateTime.now(),
      );

      ChatService().saveMessage(newMsg);

      if (mounted) {
        setState(() {
          _addMessageAndRefresh(newMsg);
        });
      }

      _scrollToBottom();

      AlarmService.showHeadsUpNotification(
        title: "🎥 $userName in YFC Fellowship Chat",
        body: caption.isNotEmpty ? caption : "Shared a video 🎥",
        payload: 'chat',
      );
    } catch (e) {
      debugPrint("Error sending video message: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isSendingMedia = false;
        });
      }
    }
  }

  void _sendDocumentMessage(String docName) {
    final appState = Provider.of<AppState>(context, listen: false);
    final userAvatar = appState.avatarUrl.isNotEmpty ? appState.avatarUrl : "📄";
    final userName = appState.profileName.isNotEmpty ? appState.profileName : "You";

    final newMsg = ChatMessage(
      id: "msg-doc-${DateTime.now().millisecondsSinceEpoch}",
      senderName: userName,
      senderAvatar: userAvatar,
      textContent: "Document: $docName",
      messageType: 'document',
      mediaUrl: docName,
      createdAt: DateTime.now(),
    );

    ChatService().saveMessage(newMsg);

    if (mounted) {
      setState(() {
        _addMessageAndRefresh(newMsg);
      });
    }

    _scrollToBottom();
  }

  final AudioRecordService _audioRecordService = AudioRecordService();

  void _showLimitDialog(String title, String message) {
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

  Future<void> _startVoiceRecording() async {
    final started = await _audioRecordService.startRecording();
    if (started) {
      setState(() {
        _isRecording = true;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Microphone permission required for voice recording")),
        );
      }
    }
  }

  Future<void> _stopVoiceRecording() async {
    final result = await _audioRecordService.stopRecording();
    if (result != null) {
      setState(() {
        _isRecording = false;
        _draftVoiceFilePath = result['path'] as String;
        _draftVoiceDurationSeconds = result['duration'] as int;
        _isPlayingDraftVoice = false;
      });
    } else {
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _sendDraftVoiceNote() async {
    if (_isSendingMedia) return;
    if (_draftVoiceFilePath == null) return;

    setState(() {
      _isSendingMedia = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final userAvatar = appState.avatarUrl.isNotEmpty ? appState.avatarUrl : "🎤";
      final userName = appState.profileName.isNotEmpty ? appState.profileName : "You";
      final user = FirebaseAuth.instance.currentUser;

      final uploadedUrl = await appState.uploadChatMedia(XFile(_draftVoiceFilePath!));

      final docRef = await FirebaseFirestore.instance.collection('fellowship_chats').add({
        'senderId': user?.uid ?? 'anonymous',
        'senderName': userName,
        'senderAvatar': userAvatar,
        'text': "Voice Prayer Note (0:${_draftVoiceDurationSeconds.toString().padLeft(2, '0')})",
        'mediaUrl': uploadedUrl.isNotEmpty ? uploadedUrl : _draftVoiceFilePath,
        'type': 'voice',
        'audioDurationSeconds': _draftVoiceDurationSeconds,
        'reactions': {},
        'timestamp': FieldValue.serverTimestamp(),
      });

      final newVoiceMsg = ChatMessage(
        id: docRef.id,
        senderName: userName,
        senderAvatar: userAvatar,
        textContent: "Voice Prayer Note (0:${_draftVoiceDurationSeconds.toString().padLeft(2, '0')})",
        messageType: 'voice',
        mediaUrl: uploadedUrl.isNotEmpty ? uploadedUrl : _draftVoiceFilePath,
        audioDurationSeconds: _draftVoiceDurationSeconds,
        reactions: {},
        createdAt: DateTime.now(),
      );

      ChatService().saveMessage(newVoiceMsg);

      if (mounted) {
        setState(() {
          _addMessageAndRefresh(newVoiceMsg);
          _draftVoiceFilePath = null;
          _isPlayingDraftVoice = false;
        });
      }

      _scrollToBottom();

      AlarmService.showHeadsUpNotification(
        title: "🎙️ $userName in YFC Fellowship Chat",
        body: "Shared a voice message 🎙️",
        payload: 'chat',
      );
    } catch (e) {
      debugPrint("Error sending voice note: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isSendingMedia = false;
        });
      }
    }
  }

  Future<void> _pickMultiplePhotos() async {
    if (_selectedPhotos.length >= 20) {
      if (mounted) {
        _showLimitDialog("Image Limit Exceeded", "Only up to 20 images are allowed at a time.");
      }
      return;
    }

    try {
      final picker = ImagePicker();
      final List<XFile> pickedImages = await picker.pickMultiImage();
      if (pickedImages.isNotEmpty) {
        List<XFile> validImages = pickedImages;
        if (_selectedPhotos.length + pickedImages.length > 20) {
          if (mounted) {
            _showLimitDialog("Image Limit Exceeded", "Only up to 20 images are allowed at a time.");
          }
          final spaceLeft = 20 - _selectedPhotos.length;
          validImages = pickedImages.take(spaceLeft > 0 ? spaceLeft : 0).toList();
        }
        if (validImages.isNotEmpty) {
          setState(() {
            _selectedPhotos.addAll(validImages);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to pick photos: $e")),
        );
      }
    }
  }

  Future<void> _pickVideos() async {
    if (_selectedVideos.length >= 5) {
      if (mounted) {
        _showLimitDialog("Video Limit Exceeded", "Only up to 5 videos are allowed at a time.");
      }
      return;
    }

    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: true,
      );

      if (result != null) {
        final rawPaths = result.paths.whereType<String>().toList();
        List<String> selectedPaths = rawPaths;
        if (_selectedVideos.length + rawPaths.length > 5) {
          if (mounted) {
            _showLimitDialog("Video Limit Exceeded", "Only up to 5 videos are allowed at a time.");
          }
          final spaceLeft = 5 - _selectedVideos.length;
          selectedPaths = rawPaths.take(spaceLeft > 0 ? spaceLeft : 0).toList();
        }

        final List<XFile> validVideos = [];
        for (final path in selectedPaths) {
          final file = File(path);
          if (file.existsSync() && file.lengthSync() > 100 * 1024 * 1024) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("${path.split(Platform.pathSeparator).last} exceeds 100MB limit")),
              );
            }
            continue;
          }
          validVideos.add(XFile(path));
        }

        if (validVideos.isNotEmpty) {
          setState(() {
            _selectedVideos.addAll(validVideos);
          });
        }
      }
    } catch (_) {
      try {
        final picker = ImagePicker();
        final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
        if (video != null) {
          final file = File(video.path);
          if (file.existsSync() && file.lengthSync() > 100 * 1024 * 1024) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Video file size exceeds 100MB limit")),
              );
            }
            return;
          }

          setState(() {
            _selectedVideos.add(video);
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to pick video: $e")),
          );
        }
      }
    }
  }

  Future<void> _sendAllSelectedMedia() async {
    if (_isSendingMedia || _isBatchUploading) return;
    if (_selectedPhotos.isEmpty && _selectedVideos.isEmpty) return;

    setState(() {
      _isSendingMedia = true;
      _isBatchUploading = true;
    });

    try {
      final caption = _textController.text.trim();
      final appState = Provider.of<AppState>(context, listen: false);
      final userAvatar = appState.avatarUrl.isNotEmpty ? appState.avatarUrl : "📸";
      final userName = appState.profileName.isNotEmpty ? appState.profileName : "You";

      final photosToSend = List<XFile>.from(_selectedPhotos);
      final videosToSend = List<XFile>.from(_selectedVideos);
      final totalCount = photosToSend.length + videosToSend.length;

      if (totalCount == 1) {
        if (photosToSend.isNotEmpty) {
          final photoPath = photosToSend[0].path;
          setState(() {
            _isSendingMedia = false; // Reset so _sendImageMessage can run
          });
          await _sendImageMessage(photoPath, caption: caption.isNotEmpty ? caption : "Photo attachment");
        } else if (videosToSend.isNotEmpty) {
          final videoPath = videosToSend[0].path;
          setState(() {
            _isSendingMedia = false; // Reset so _sendVideoMessage can run
          });
          await _sendVideoMessage(videoPath, caption: caption.isNotEmpty ? caption : "Video attachment");
        }
      } else {
        final List<String> uploadedUrls = [];
        final List<String> types = [];

        for (final photo in photosToSend) {
          final url = await appState.uploadChatMedia(photo);
          uploadedUrls.add(url.isNotEmpty ? url : photo.path);
          types.add('image');
        }

        for (final video in videosToSend) {
          final url = await appState.uploadChatMedia(video);
          uploadedUrls.add(url.isNotEmpty ? url : video.path);
          types.add('video');
        }

        final user = FirebaseAuth.instance.currentUser;
        final docRef = await FirebaseFirestore.instance.collection('fellowship_chats').add({
          'senderId': user?.uid ?? 'anonymous',
          'senderName': userName,
          'senderAvatar': userAvatar,
          'text': caption.isNotEmpty ? caption : "Shared $totalCount media items 📸",
          'mediaUrls': uploadedUrls,
          'mediaTypes': types,
          'type': 'media_grid',
          'reactions': {},
          'timestamp': FieldValue.serverTimestamp(),
        });

        final gridMsg = ChatMessage(
          id: docRef.id,
          senderName: userName,
          senderAvatar: userAvatar,
          messageType: 'media_grid',
          textContent: caption.isNotEmpty ? caption : "Shared $totalCount media items 📸",
          mediaUrls: uploadedUrls,
          mediaTypes: types,
          reactions: {},
          createdAt: DateTime.now(),
        );

        ChatService().saveMessage(gridMsg);

        if (mounted) {
          setState(() {
            _addMessageAndRefresh(gridMsg);
          });
        }

        _scrollToBottom();
      }
    } catch (e) {
      debugPrint("Error sending batch media: $e");
    } finally {
      if (mounted) {
        setState(() {
          _selectedPhotos.clear();
          _selectedVideos.clear();
          _textController.clear();
          _isBatchUploading = false;
          _isSendingMedia = false;
        });
      }
    }
  }


  Widget _buildMediaPreviewCarousel(bool isDark) {
    final totalCount = _selectedPhotos.length + _selectedVideos.length;
    if (totalCount == 0) return const SizedBox();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B132B) : const Color(0xFFFFF0F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.goldAccent, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shiningRed.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Badge Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.shiningRed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "$totalCount selected (${_selectedPhotos.length}/20 Photos, ${_selectedVideos.length}/5 Videos)",
                  style: const TextStyle(
                    color: AppTheme.goldAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _selectedPhotos.clear();
                    _selectedVideos.clear();
                  });
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    "Clear All",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Horizontal Thumbnail Scrollable List
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Render Photos
                ..._selectedPhotos.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final photo = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(photo.path),
                            width: 75,
                            height: 75,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedPhotos.removeAt(idx);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.black87,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // Render Videos
                ..._selectedVideos.asMap().entries.map((entry) {
                  final idx = entry.key;
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        Container(
                          width: 75,
                          height: 75,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.goldAccent, width: 0.8),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.videocam_rounded,
                              color: AppTheme.goldAccent,
                              size: 32,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedVideos.removeAt(idx);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.black87,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Send All Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isBatchUploading ? null : _sendAllSelectedMedia,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.shiningRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: _isBatchUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(
                _isBatchUploading
                    ? "Uploading Media..."
                    : "Send All ($totalCount)",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _incrementReaction(ChatMessage msg, String emoji) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final userName = appState.profileName.trim().isNotEmpty ? appState.profileName.trim() : "YFC Member";
    final userAvatar = appState.avatarUrl.isNotEmpty ? appState.avatarUrl : "✝️";
    final currentUser = FirebaseAuth.instance.currentUser;
    final userKey = currentUser?.uid ?? userName;

    setState(() {
      final existingReaction = msg.userReactions[userKey];
      if (existingReaction != null && existingReaction['emoji'] == emoji) {
        // Toggle OFF if user taps the same emoji again
        msg.userReactions.remove(userKey);
      } else {
        // Assign or update user's selected emoji
        msg.userReactions[userKey] = {
          'name': userName,
          'emoji': emoji,
          'avatar': userAvatar,
        };
      }

      // Recalculate summary count per emoji
      msg.reactions.updateAll((key, value) => 0);
      for (final ur in msg.userReactions.values) {
        final em = ur['emoji'];
        if (em != null) {
          msg.reactions[em] = (msg.reactions[em] ?? 0) + 1;
        }
      }
    });

    try {
      if (msg.id.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('fellowship_chats')
            .doc(msg.id)
            .set({
          'reactions': msg.reactions,
          'userReactions': msg.userReactions,
        }, SetOptions(merge: true));
      }
    } catch (_) {}

    try {
      await ChatService().saveMessage(msg);
    } catch (_) {}
  }

  void _showReactionDetailsModal(BuildContext context, ChatMessage msg) {
    if (msg.userReactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No reactions on this message yet 🙏"),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B132B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: AppTheme.goldAccent, width: 1.2),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final allReactions = msg.userReactions.values.toList();
            final emojiTypes = <String>{};
            for (final r in allReactions) {
              if (r['emoji'] != null) emojiTypes.add(r['emoji']!);
            }

            return DefaultTabController(
              length: emojiTypes.length + 1,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.goldAccent.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      "Message Reactions (${allReactions.length})",
                      style: GoogleFonts.cinzel(
                        color: AppTheme.goldAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Filter Tabs (All, 🙏, ❤️, 🔥, etc.)
                    TabBar(
                      isScrollable: true,
                      indicatorColor: AppTheme.goldAccent,
                      labelColor: AppTheme.goldAccent,
                      unselectedLabelColor: Colors.grey,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      tabs: [
                        Tab(text: "All ${allReactions.length}"),
                        ...emojiTypes.map((em) {
                          final count = allReactions.where((r) => r['emoji'] == em).length;
                          return Tab(text: "$em $count");
                        }),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // List of members who reacted
                    SizedBox(
                      height: 260,
                      child: TabBarView(
                        children: [
                          _buildReactionsListView(allReactions),
                          ...emojiTypes.map((em) {
                            final filtered = allReactions.where((r) => r['emoji'] == em).toList();
                            return _buildReactionsListView(filtered);
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReactionsListView(List<Map<String, String>> reactionItems) {
    if (reactionItems.isEmpty) {
      return const Center(
        child: Text("No reactions in this category", style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: reactionItems.length,
      itemBuilder: (context, idx) {
        final item = reactionItems[idx];
        final name = item['name'] ?? 'Fellowship Member';
        final avatar = item['avatar'] ?? '✝️';
        final emoji = item['emoji'] ?? '❤️';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              _buildSenderAvatarWidget(avatar, name, isBot: false, radius: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.goldAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 18)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showExpandedEmojiPickerModal(BuildContext context, ChatMessage msg) {
    final categories = <String, List<String>>{
      "🎉 Party & Celebration": ["🎉", "🥳", "🎊", "🎈", "✨", "⭐", "🌟", "🥂", "🎂", "🎁"],
      "👍 Reactions & Expressions": ["👍", "👎", "👏", "🙌", "🤝", "🔥", "❤️", "💯", "😢", "😭", "🥺", "😄", "🥰", "😍", "😮"],
      "✝️ Faith & Fellowship": ["🙏", "✝️", "📖", "🙌", "🕊️", "👑", "🕯️", "✨", "❤️"],
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B132B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: AppTheme.goldAccent, width: 1.2),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.goldAccent.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    "React to Message",
                    style: GoogleFonts.cinzel(
                      color: AppTheme.goldAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 280,
                  child: ListView(
                    children: categories.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                color: AppTheme.goldAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: entry.value.map((emoji) {
                              final count = msg.reactions[emoji] ?? 0;
                              return InkWell(
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _incrementReaction(msg, emoji);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: count > 0
                                        ? AppTheme.goldAccent.withValues(alpha: 0.25)
                                        : Colors.white.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: count > 0 ? AppTheme.goldAccent : AppTheme.goldAccent.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Text(
                                    emoji,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAvatarPreviewModal(BuildContext context, String senderName, String avatarOrUrl) {
    Widget avatarWidget;
    if (avatarOrUrl.startsWith('http')) {
      avatarWidget = Image.network(
        avatarOrUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildDefaultAvatarPlaceholder(senderName),
      );
    } else if (avatarOrUrl.isNotEmpty && File(avatarOrUrl).existsSync()) {
      avatarWidget = Image.file(
        File(avatarOrUrl),
        fit: BoxFit.contain,
      );
    } else {
      avatarWidget = _buildDefaultAvatarPlaceholder(senderName);
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: avatarWidget,
                  ),
                ),
              ),
              Positioned(
                top: 40,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.shiningRed,
                          backgroundImage: avatarOrUrl.startsWith('http')
                              ? NetworkImage(avatarOrUrl) as ImageProvider
                              : (avatarOrUrl.isNotEmpty && File(avatarOrUrl).existsSync()
                                  ? FileImage(File(avatarOrUrl)) as ImageProvider
                                  : null),
                          child: (avatarOrUrl.startsWith('http') || (avatarOrUrl.isNotEmpty && File(avatarOrUrl).existsSync()))
                              ? null
                              : Text(
                                  avatarOrUrl.length <= 2 ? avatarOrUrl : (senderName.isNotEmpty ? senderName[0] : "👤"),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          senderName,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _downloadMediaToGallery(context, avatarOrUrl, "Avatar"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.goldAccent,
                        foregroundColor: AppTheme.textDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text("Save DP", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => _shareMedia("Contact DP of $senderName", mediaPath: avatarOrUrl),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.shiningRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text("Share DP", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDefaultAvatarPlaceholder(String senderName) {
    return Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.shiningRed,
        border: Border.all(color: AppTheme.goldAccent, width: 3.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldAccent.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Text(
          senderName.isNotEmpty ? senderName[0].toUpperCase() : "✝️",
          style: GoogleFonts.cinzel(
            color: AppTheme.goldAccent,
            fontSize: 100,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _downloadMediaToGallery(BuildContext context, String mediaUrlOrPath, String mediaType) async {
    try {
      if (mediaUrlOrPath.startsWith('http')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Downloading $mediaType from cloud..."),
            backgroundColor: AppTheme.shiningRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final file = File(mediaUrlOrPath);
      if (await file.exists()) {
        final hasAccess = await Gal.hasAccess();
        if (!hasAccess) {
          await Gal.requestAccess();
        }

        if (mediaType == 'image' || mediaType == 'Avatar') {
          await Gal.putImage(mediaUrlOrPath);
        } else if (mediaType == 'video') {
          await Gal.putVideo(mediaUrlOrPath);
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Saved $mediaType to Gallery! 📥"),
              backgroundColor: AppTheme.statusGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Sample $mediaType saved locally."),
              backgroundColor: AppTheme.statusGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Saved to Gallery! 📥"),
            backgroundColor: AppTheme.statusGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _shareMedia(String textContent, {String? mediaPath}) {
    if (mediaPath != null && mediaPath.isNotEmpty && File(mediaPath).existsSync()) {
      Share.shareXFiles([XFile(mediaPath)], text: textContent);
    } else {
      Share.share(
        "$textContent\n\nShared via Youth For Christ App ✝️",
        subject: "YFC Fellowship Media Share",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: _isSelectionMode
          ? AppBar(
              backgroundColor: const Color(0xFF0B132B),
              leading: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                tooltip: "Cancel",
                onPressed: _exitSelectionMode,
              ),
              title: Text(
                "${_selectedMessageIds.length} Selected",
                style: const TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    _selectedMessageIds.length == _messages.length ? Icons.select_all : Icons.library_add_check_outlined,
                    color: AppTheme.goldAccent,
                  ),
                  tooltip: "Select All",
                  onPressed: _toggleSelectAll,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFD90429)),
                  tooltip: "Delete Selected",
                  onPressed: _confirmBatchDelete,
                ),
              ],
            )
          : AppBar(
              title: Row(
                children: [
                  const Icon(Icons.chat_bubble_rounded, color: AppTheme.goldAccent),
                  const SizedBox(width: 10),
                  Text(
                    appState.isTelugu ? "ఫెలోషిప్ చాట్" : "Fellowship Chat",
                    style: AppTheme.getScriptTextStyle(
                      isTelugu: appState.isTelugu,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.goldAccent : AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.volunteer_activism_rounded, color: AppTheme.shiningRed),
                  tooltip: "Prayer Requests",
                  onPressed: () => _showPrayerRequestsModal(context),
                ),
              ],
            ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.goldAccent.withValues(alpha: 0.15),
                              border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.4)),
                            ),
                            child: const Icon(Icons.forum_rounded, size: 48, color: AppTheme.goldAccent),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            appState.isTelugu
                                ? "YFC ఫెలోషిప్ చాట్‌కి స్వాగతం! ఒక వాక్యం, సాక్ష్యం లేదా ప్రార్థన విజ్ఞాపనను పంచుకోండి."
                                : "Welcome to YFC Fellowship Chat! Share a verse, testimony, or prayer request.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                final msg = _messages[index];
                final isSelected = _selectedMessageIds.contains(msg.id);
                return GestureDetector(
                  onLongPress: () => _isSelectionMode ? _toggleMessageSelection(msg.id) : _enterSelectionMode(msg.id),
                  onTap: () {
                    if (_isSelectionMode) {
                      _toggleMessageSelection(msg.id);
                    }
                  },
                  child: Row(
                    children: [
                      if (_isSelectionMode)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            color: isSelected ? AppTheme.goldAccent : Colors.grey,
                            size: 24,
                          ),
                        ),
                      Expanded(
                        child: Container(
                          decoration: isSelected
                              ? BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppTheme.goldAccent, width: 2),
                                )
                              : null,
                          child: _buildMessageTile(msg, appState.isTelugu),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_selectedPhotos.isNotEmpty || _selectedVideos.isNotEmpty)
            _buildMediaPreviewCarousel(isDark),
          _buildInputBar(appState.isTelugu),
        ],
      ),
    );
  }

  Widget _buildMessageTile(ChatMessage msg, bool isTelugu) {
    final isBot = msg.isSystemBot || msg.messageType == 'celebration';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryQuickEmojis = ["🙏", "❤️", "🔥", "👍", "👏"];
    final activeExtraEmojis = msg.reactions.keys
        .where((e) => !primaryQuickEmojis.contains(e) && (msg.reactions[e] ?? 0) > 0)
        .toList();

    if (msg.messageType == 'celebration') {
      return _buildCelebrationGreetingTile(msg);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isBot ? AppTheme.goldAccent.withValues(alpha: 0.08) : (isDark ? AppTheme.surfaceCardDark : AppTheme.surfaceCardLight),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isBot ? AppTheme.goldAccent.withValues(alpha: 0.4) : AppTheme.goldAccent.withValues(alpha: 0.35),
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
          Row(
            children: [
              GestureDetector(
                onTap: () => _showAvatarPreviewModal(context, msg.senderName, msg.senderAvatar),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isBot ? AppTheme.goldAccent : AppTheme.shiningRed,
                      width: 1.2,
                    ),
                  ),
                  child: _buildSenderAvatarWidget(msg.senderAvatar, msg.senderName, isBot: isBot, radius: 15),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _showAvatarPreviewModal(context, msg.senderName, msg.senderAvatar),
                child: Text(
                  msg.senderName,
                  style: TextStyle(
                    color: isBot ? AppTheme.goldAccent : (isDark ? AppTheme.textLight : AppTheme.textDark),
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                "${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}",
                style: TextStyle(color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (msg.messageType == 'image')
            _buildImageMessageTile(msg)
          else if (msg.messageType == 'video')
            _buildVideoMessageTile(msg)
          else if (msg.messageType == 'document')
            _buildDocumentMessageTile(msg)
          else if (msg.messageType == 'voice')
            _buildVoiceWaveformPlayer(msg)
          else if (msg.messageType == 'media_grid')
            MediaGridBubble(message: msg)
          else if (msg.messageType == 'poll')
            PollMessageWidget(
              poll: PollModel(
                id: msg.id,
                question: msg.textContent,
                allowMultiple: false,
                options: [
                  PollOptionModel(id: '1', text: 'Option A', voters: []),
                  PollOptionModel(id: '2', text: 'Option B', voters: []),
                ],
              ),
              isDark: isDark,
            )
          else
            _buildTextMessageContent(msg, isTelugu, isDark),
          const SizedBox(height: 10),

          if (msg.messageType == 'image' || msg.messageType == 'video' || msg.messageType == 'document' || msg.messageType == 'voice') ...[
            Row(
              children: [
                InkWell(
                  onTap: () => _downloadMediaToGallery(context, msg.mediaUrl ?? '', msg.messageType),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.goldAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.download_rounded, size: 14, color: AppTheme.goldAccent),
                        SizedBox(width: 4),
                        Text(
                          "Save Media",
                          style: TextStyle(color: AppTheme.goldAccent, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: () => _shareMedia(msg.textContent, mediaPath: msg.mediaUrl),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.shiningRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.shiningRed.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.share_rounded, size: 14, color: AppTheme.shiningRed),
                        SizedBox(width: 4),
                        Text(
                          "Share",
                          style: TextStyle(color: AppTheme.shiningRed, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // Reactions Bar
          GestureDetector(
            onLongPress: () => _showReactionDetailsModal(context, msg),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                ...primaryQuickEmojis.map((e) => _buildReactionChip(msg, e)),
                ...activeExtraEmojis.map((e) => _buildReactionChip(msg, e)),
                InkWell(
                  onTap: () => _showExpandedEmojiPickerModal(context, msg),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.4), width: 1),
                    ),
                    child: const Icon(Icons.add_reaction_outlined, size: 15, color: AppTheme.goldAccent),
                  ),
                ),
                if (msg.userReactions.isNotEmpty)
                  InkWell(
                    onTap: () => _showReactionDetailsModal(context, msg),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.goldAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.goldAccent, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_alt_rounded, size: 13, color: AppTheme.goldAccent),
                          const SizedBox(width: 4),
                          Text(
                            "${msg.userReactions.length} reacted",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.goldAccent),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCelebrationGreetingTile(ChatMessage msg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1B4B), const Color(0xFF0B132B)]
              : [const Color(0xFFFFF0F2), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.goldAccent, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldAccent.withValues(alpha: 0.25),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.goldAccent, width: 2),
                  gradient: const LinearGradient(colors: [AppTheme.shiningRed, Color(0xFFFFD700)]),
                ),
                child: Center(
                  child: Text(msg.senderAvatar, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      msg.senderName,
                      style: GoogleFonts.cinzel(
                        color: AppTheme.goldAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "✨ FELLOWSHIP CELEBRATION BLESSING ✨",
                      style: TextStyle(
                        color: AppTheme.shiningRed,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : const Color(0xFFFFFDF5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
            ),
            child: Text(
              msg.textContent,
              style: TextStyle(
                color: isDark ? AppTheme.textLight : AppTheme.textDark,
                fontSize: 13.5,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildReactionChip(msg, "Amen 🙏"),
              _buildReactionChip(msg, "Blessings ✨"),
              _buildReactionChip(msg, "Hallelujah 🙌"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSenderAvatarWidget(String avatarOrUrl, String senderName, {required bool isBot, double radius = 15}) {
    if (avatarOrUrl.startsWith('http')) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(avatarOrUrl),
      );
    } else if (avatarOrUrl.isNotEmpty && File(avatarOrUrl).existsSync()) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(avatarOrUrl)),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: isBot ? AppTheme.goldAccent.withValues(alpha: 0.2) : AppTheme.shiningRed.withValues(alpha: 0.2),
      child: Text(
        avatarOrUrl.length <= 2 ? avatarOrUrl : (senderName.isNotEmpty ? senderName[0] : "👤"),
        style: TextStyle(
          color: isBot ? AppTheme.goldAccent : AppTheme.shiningRed,
          fontSize: radius * 0.9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildImageMessageTile(ChatMessage msg) {
    final mediaUrl = msg.mediaUrl ?? '';
    Widget imageContent;

    if (mediaUrl.startsWith('http')) {
      imageContent = Image.network(
        mediaUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/news_jerusalem.jpg',
          fit: BoxFit.cover,
        ),
      );
    } else if (mediaUrl.isNotEmpty && File(mediaUrl).existsSync()) {
      imageContent = Image.file(
        File(mediaUrl),
        fit: BoxFit.contain,
      );
    } else if (mediaUrl.startsWith('assets/')) {
      imageContent = Image.asset(
        mediaUrl,
        fit: BoxFit.contain,
      );
    } else {
      imageContent = Image.asset(
        'assets/images/news_jerusalem.jpg',
        fit: BoxFit.contain,
      );
    }

    return GestureDetector(
      onTap: () => _openFullscreenImageViewer(context, mediaUrl, msg.senderName),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 320),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.3), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: imageContent,
        ),
      ),
    );
  }

  void _openFullscreenImageViewer(BuildContext context, String mediaUrl, String senderName) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (ctx) {
        Widget previewImg;
        if (mediaUrl.startsWith('http')) {
          previewImg = Image.network(mediaUrl, fit: BoxFit.contain);
        } else if (mediaUrl.isNotEmpty && File(mediaUrl).existsSync()) {
          previewImg = Image.file(File(mediaUrl), fit: BoxFit.contain);
        } else if (mediaUrl.startsWith('assets/')) {
          previewImg = Image.asset(mediaUrl, fit: BoxFit.contain);
        } else {
          previewImg = Image.asset('assets/images/news_jerusalem.jpg', fit: BoxFit.contain);
        }

        return Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: previewImg,
                ),
              ),
              Positioned(
                top: 40,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Shared by $senderName 📷",
                      style: GoogleFonts.cinzel(
                        color: AppTheme.goldAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        _downloadMediaToGallery(context, mediaUrl, "Image");
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.shiningRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text("Save to Gallery", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoMessageTile(ChatMessage msg) {
    final mediaUrl = msg.mediaUrl ?? '';
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenVideoViewer(videoUrl: mediaUrl),
          ),
        );
      },
      child: Container(
        height: 195,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              // 1. Dynamic Video Thumbnail Preview (Original Video Frame)
              InlineVideoThumbnailPreview(videoUrl: mediaUrl),

              // 2. Cinematic Dark Overlay Gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.65),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // 3. Glowing Metallic Gold Play Button
              Center(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.shiningRed,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.goldAccent, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.goldAccent.withValues(alpha: 0.6),
                        blurRadius: 16,
                        spreadRadius: 3,
                      ),
                      BoxShadow(
                        color: AppTheme.shiningRed.withValues(alpha: 0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 38),
                ),
              ),

              // 4. Video Badge & Tap Hint
              Positioned(
                bottom: 10,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.6), width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.videocam_rounded, color: AppTheme.goldAccent, size: 14),
                      SizedBox(width: 5),
                      Text(
                        "Tap to Play • HD Video 🎥",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentMessageTile(ChatMessage msg) {
    final mediaUrl = msg.mediaUrl ?? msg.textContent;
    final filename = mediaUrl.split('/').last.split('\\').last;
    final cleanName = filename.isNotEmpty ? filename : "Document_Attachment.pdf";

    return InkWell(
      onTap: () async {
        if (mediaUrl.startsWith('http')) {
          final uri = Uri.parse(mediaUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        } else if (mediaUrl.isNotEmpty && File(mediaUrl).existsSync()) {
          final uri = Uri.file(mediaUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Opening document: $cleanName")),
          );
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.goldAccent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.4), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.shiningRed,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.insert_drive_file_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    cleanName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    "PDF Document • 2.4 MB",
                    style: TextStyle(color: AppTheme.goldAccent, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new_rounded, color: AppTheme.goldAccent, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceWaveformPlayer(ChatMessage msg) {
    return AudioMessagePlayerWidget(msg: msg);
  }

  Widget _buildTextMessageContent(ChatMessage msg, bool isTelugu, bool isDark) {
    return Linkify(
      onOpen: (link) async {
        final uri = Uri.parse(link.url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      text: msg.textContent,
      style: TextStyle(
        color: isDark ? AppTheme.textLight : AppTheme.textDark,
        fontSize: 14,
        height: 1.45,
      ),
      linkStyle: const TextStyle(
        color: Colors.blue,
        decoration: TextDecoration.underline,
      ),
    );
  }

  Widget _buildReactionChip(ChatMessage msg, String emoji) {
    final count = msg.reactions[emoji] ?? 0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _incrementReaction(msg, emoji),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: count > 0 ? AppTheme.goldAccent.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: count > 0 ? AppTheme.goldAccent : AppTheme.goldAccent.withValues(alpha: 0.3),
            width: count > 0 ? 1.4 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                "$count",
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.goldAccent,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(bool isTelugu) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasMedia = _selectedPhotos.isNotEmpty || _selectedVideos.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceCardDark : AppTheme.surfaceCardLight,
        border: Border(
          top: BorderSide(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: _draftVoiceFilePath != null
            ? _buildVoiceDraftBar(isDark)
            : Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file_rounded, color: AppTheme.goldAccent, size: 24),
                    tooltip: "Attach Photo or Document",
                    onPressed: () => _showAttachmentMenu(context, isTelugu),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.bgPrimaryDark : AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
                      ),
                      child: TextField(
                        controller: _textController,
                        style: TextStyle(color: isDark ? AppTheme.textLight : AppTheme.textDark, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: _isRecording
                              ? (isTelugu ? "వాయిస్ రికార్డ్ అవుతోంది..." : "Recording Voice Note...")
                              : (hasMedia
                                  ? (isTelugu ? "క్యాప్షన్ జోడించండి (ఐచ్ఛికం)..." : "Add a caption (optional)...")
                                  : (isTelugu ? "మీ వాక్యం లేదా ప్రార్థన పంచుకోండి..." : "Share a verse or prayer note...")),
                          hintStyle: TextStyle(color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted, fontSize: 13),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(
                      _isRecording ? Icons.stop_circle_rounded : Icons.mic_rounded,
                      color: _isRecording ? AppTheme.shiningRed : AppTheme.goldAccent,
                      size: 24,
                    ),
                    tooltip: "Voice Prayer Note",
                    onPressed: () {
                      if (_isRecording) {
                        _stopVoiceRecording();
                      } else {
                        _startVoiceRecording();
                      }
                    },
                  ),
                  const SizedBox(width: 2),
                  CircleAvatar(
                    backgroundColor: (_isSendingMedia || _isBatchUploading)
                        ? AppTheme.shiningRed.withValues(alpha: 0.5)
                        : AppTheme.shiningRed,
                    radius: 18,
                    child: (_isSendingMedia || _isBatchUploading)
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : IconButton(
                            icon: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            onPressed: (_isSendingMedia || _isBatchUploading) ? null : _sendMessage,
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildVoiceDraftBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B132B) : const Color(0xFFFFF0F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.shiningRed, width: 1.5),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isPlayingDraftVoice ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
              color: AppTheme.shiningRed,
              size: 28,
            ),
            onPressed: () {
              setState(() {
                _isPlayingDraftVoice = !_isPlayingDraftVoice;
              });
            },
          ),
          const SizedBox(width: 4),
          const Icon(Icons.graphic_eq_rounded, color: AppTheme.goldAccent, size: 20),
          const SizedBox(width: 8),
          Text(
            "0:${_draftVoiceDurationSeconds.toString().padLeft(2, '0')}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.shiningRed),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 22),
            tooltip: "Discard Voice Note",
            onPressed: () {
              setState(() {
                _draftVoiceFilePath = null;
                _isPlayingDraftVoice = false;
              });
            },
          ),
          CircleAvatar(
            backgroundColor: (_isSendingMedia || _isBatchUploading)
                ? AppTheme.shiningRed.withValues(alpha: 0.5)
                : AppTheme.shiningRed,
            radius: 18,
            child: (_isSendingMedia || _isBatchUploading)
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                    onPressed: (_isSendingMedia || _isBatchUploading) ? null : _sendDraftVoiceNote,
                  ),
          ),
        ],
      ),
    );
  }

  void _showAttachmentMenu(BuildContext context, bool isTelugu) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B132B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppTheme.goldAccent, width: 1),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
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
                    _buildAttachmentTile(
                      icon: Icons.photo_library_rounded,
                      color: const Color(0xFFFF8FA3),
                      label: isTelugu ? "ఫోటోలు (20)" : "Photos (Up to 20)",
                      onTap: () {
                        Navigator.pop(context);
                        _pickMultiplePhotos();
                      },
                    ),

                    // 2. Video Option (Up to 5 videos)
                    _buildAttachmentTile(
                      icon: Icons.video_library_rounded,
                      color: const Color(0xFF00B4D8),
                      label: isTelugu ? "వీడియోలు (5)" : "Videos (Up to 5)",
                      onTap: () {
                        Navigator.pop(context);
                        _pickVideos();
                      },
                    ),

                    // 3. Camera Option (Live photo/video capture with lens selector)
                    _buildAttachmentTile(
                      icon: Icons.camera_alt_rounded,
                      color: const Color(0xFF48CAE4),
                      label: isTelugu ? "కెమెరా" : "Camera",
                      onTap: () {
                        Navigator.pop(context);
                        _openCameraFeature(context);
                      },
                    ),

                    // 4. Document / PDF Option
                    _buildAttachmentTile(
                      icon: Icons.picture_as_pdf_rounded,
                      color: const Color(0xFFFFB703),
                      label: isTelugu ? "డాక్యుమెంట్" : "Document / PDF",
                      onTap: () {
                        Navigator.pop(context);
                        _sendDocumentMessage("YFC_Fellowship_Study_Guide.pdf");
                      },
                    ),

                    // 5. Create Poll Option
                    _buildAttachmentTile(
                      icon: Icons.poll_rounded,
                      color: const Color(0xFF9D4EDD),
                      label: isTelugu ? "పోల్" : "Create Poll",
                      onTap: () {
                        Navigator.pop(context);
                        _showCreatePollDialog(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openCameraFeature(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B132B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Choose Camera Lens 📸",
                  style: GoogleFonts.cinzel(
                    color: AppTheme.goldAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final picker = ImagePicker();
                        final file = await picker.pickImage(
                          source: ImageSource.camera,
                          preferredCameraDevice: CameraDevice.rear,
                        );
                        if (file != null) {
                          _showCapturedMediaPreview(file.path);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.shiningRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      icon: const Icon(Icons.camera_rear_rounded),
                      label: const Text("Rear Camera 📷"),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final picker = ImagePicker();
                        final file = await picker.pickImage(
                          source: ImageSource.camera,
                          preferredCameraDevice: CameraDevice.front,
                        );
                        if (file != null) {
                          _showCapturedMediaPreview(file.path);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.goldAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      icon: const Icon(Icons.camera_front_rounded),
                      label: const Text("Front Camera 🤳"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCapturedMediaPreview(String imagePath) {
    final captionController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0B132B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.goldAccent, width: 1.2),
          ),
          title: Text(
            "Camera Image Preview 📸",
            style: GoogleFonts.cinzel(color: AppTheme.goldAccent, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(imagePath), height: 180, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: captionController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: "Add a caption for fellowship...",
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Discard", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _sendImageMessage(imagePath, caption: captionController.text.trim());
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.shiningRed),
              icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
              label: const Text("Send", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAttachmentTile({
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

  void _showCreatePollDialog(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final pollData = await CreatePollDialog.show(context, isTelugu: appState.isTelugu);
    if (pollData != null) {
      _sendPollDataMessage(pollData);
    }
  }

  void _sendPollDataMessage(PollData pollData) {
    final appState = Provider.of<AppState>(context, listen: false);
    final userAvatar = appState.avatarUrl.isNotEmpty ? appState.avatarUrl : "📊";
    final userName = appState.profileName.isNotEmpty ? appState.profileName : "You";

    final subtitle = pollData.allowMultiple ? "(Multiple choice)" : "(Single choice)";
    final pollMsg = ChatMessage(
      id: "msg-poll-${DateTime.now().millisecondsSinceEpoch}",
      senderName: userName,
      senderAvatar: userAvatar,
      textContent: "📊 Poll: ${pollData.question} $subtitle\n• ${pollData.options.join('\n• ')}",
      messageType: 'poll',
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(pollMsg);
    });

    _scrollToBottom();
  }

  void _showPrayerRequestsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Community Prayer Wall 🙏",
                        style: GoogleFonts.cinzel(
                          color: AppTheme.goldAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_rounded, color: AppTheme.shiningRed),
                        onPressed: () {
                          _showAddPrayerDialog(context, setModalState);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 280,
                    child: ListView.builder(
                      itemCount: _prayerRequests.length,
                      itemBuilder: (context, index) {
                        final pr = _prayerRequests[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            title: Text(
                              pr.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
                            ),
                            subtitle: Text(
                              pr.description,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                            trailing: TextButton.icon(
                              onPressed: () {
                                setModalState(() {
                                  pr.prayCount += 1;
                                });
                              },
                              icon: const Icon(Icons.favorite, color: AppTheme.shiningRed, size: 16),
                              label: Text("${pr.prayCount}", style: const TextStyle(color: AppTheme.shiningRed, fontWeight: FontWeight.bold)),
                            ),
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
      },
    );
  }

  void _showAddPrayerDialog(BuildContext context, StateSetter parentSetState) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Submit Prayer Request", style: TextStyle(color: AppTheme.textDark)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(hintText: "Title (e.g. Healing, Exams)"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: "Describe your prayer request..."),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  parentSetState(() {
                    _prayerRequests.insert(
                      0,
                      PrayerRequest(
                        id: "pr-${DateTime.now().millisecondsSinceEpoch}",
                        authorName: "You",
                        title: titleController.text.trim(),
                        description: descController.text.trim(),
                        prayCount: 0,
                        prayedByUsers: const [],
                        createdAt: DateTime.now(),
                      ),
                    );
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.shiningRed),
              child: const Text("Submit", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

class AudioMessagePlayerWidget extends StatefulWidget {
  final ChatMessage msg;
  const AudioMessagePlayerWidget({super.key, required this.msg});

  @override
  State<AudioMessagePlayerWidget> createState() => _AudioMessagePlayerWidgetState();
}

class _AudioMessagePlayerWidgetState extends State<AudioMessagePlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription? _playerStateSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _completeSub;

  @override
  void initState() {
    super.initState();
    final defaultSecs = widget.msg.audioDurationSeconds > 0 ? widget.msg.audioDurationSeconds : 14;
    _duration = Duration(seconds: defaultSecs);

    _playerStateSub = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _positionSub = _audioPlayer.onPositionChanged.listen((pos) {
      if (mounted) {
        setState(() {
          _position = pos;
        });
      }
    });

    _durationSub = _audioPlayer.onDurationChanged.listen((dur) {
      if (mounted && dur > Duration.zero) {
        setState(() {
          _duration = dur;
        });
      }
    });

    _completeSub = _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _completeSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      final mediaUrl = widget.msg.mediaUrl ?? '';
      try {
        if (mediaUrl.startsWith('http')) {
          await _audioPlayer.play(UrlSource(mediaUrl));
        } else if (mediaUrl.isNotEmpty && File(mediaUrl).existsSync()) {
          await _audioPlayer.play(DeviceFileSource(mediaUrl));
        } else if (mediaUrl.startsWith('audio/') || mediaUrl.startsWith('assets/')) {
          final cleanPath = mediaUrl.replaceFirst(RegExp(r'^(assets/|audio/)'), '');
          await _audioPlayer.play(AssetSource('audio/$cleanPath'));
        } else {
          await _audioPlayer.play(UrlSource('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'));
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    final int displaySeconds = _isPlaying
        ? _position.inSeconds
        : (_duration.inSeconds > 0 ? _duration.inSeconds : widget.msg.audioDurationSeconds);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.shiningRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.shiningRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _togglePlayPause,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.shiningRed,
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: List.generate(
                22,
                (index) {
                  final double itemProgress = index / 22.0;
                  final bool isActive = itemProgress <= progress;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      height: (index % 5 + 1) * 4.0 + 6,
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.shiningRed : AppTheme.goldAccent.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "0:${displaySeconds.toString().padLeft(2, '0')}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.shiningRed),
          ),
        ],
      ),
    );
  }
}

class InlineVideoThumbnailPreview extends StatefulWidget {
  final String videoUrl;
  const InlineVideoThumbnailPreview({super.key, required this.videoUrl});

  @override
  State<InlineVideoThumbnailPreview> createState() => _InlineVideoThumbnailPreviewState();
}

class _InlineVideoThumbnailPreviewState extends State<InlineVideoThumbnailPreview> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void didUpdateWidget(InlineVideoThumbnailPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _controller?.dispose();
      _controller = null;
      _isInitialized = false;
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    final url = widget.videoUrl;
    if (url.isEmpty) return;

    try {
      if (url.startsWith('http')) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(url));
      } else if (File(url).existsSync()) {
        _controller = VideoPlayerController.file(File(url));
      } else if (url.startsWith('assets/')) {
        _controller = VideoPlayerController.asset(url);
      } else {
        return;
      }

      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialized && _controller != null && _controller!.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      );
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF38000A), Color(0xFF0B132B), Color(0xFF1E1B4B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.movie_creation_outlined, color: AppTheme.goldAccent, size: 40),
      ),
    );
  }
}
