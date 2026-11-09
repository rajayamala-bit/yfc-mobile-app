class ChatMessage {
  final String id;
  final String senderName;
  final String senderAvatar;
  final String messageType; // 'text', 'voice', 'image', 'video', 'document', 'media_grid', 'poll', 'celebration'
  final String textContent;
  final String? mediaUrl;
  final List<String> mediaUrls;
  final List<String> mediaTypes;
  final int audioDurationSeconds;
  final Map<String, int> reactions;
  final Map<String, Map<String, String>> userReactions; // key: userId or userName -> {'name': '...', 'emoji': '...', 'avatar': '...'}
  final bool isSystemBot;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderName,
    required this.senderAvatar,
    this.messageType = 'text',
    required this.textContent,
    this.mediaUrl,
    this.mediaUrls = const [],
    this.mediaTypes = const [],
    this.audioDurationSeconds = 0,
    Map<String, int>? reactions,
    Map<String, Map<String, String>>? userReactions,
    this.isSystemBot = false,
    required this.createdAt,
  })  : reactions = reactions ?? {'🙏': 0, '❤️': 0, '🔥': 0, '📖': 0, '👏': 0},
        userReactions = userReactions ?? {};

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    Map<String, int> parsedReactions = {
      '🙏': 0, '❤️': 0, '🔥': 0, '✝️': 0, '📖': 0, '👏': 0
    };
    if (json['reactions'] != null && json['reactions'] is Map) {
      (json['reactions'] as Map).forEach((key, value) {
        parsedReactions[key.toString()] = (value as num).toInt();
      });
    }

    Map<String, Map<String, String>> parsedUserReactions = {};
    if (json['userReactions'] != null && json['userReactions'] is Map) {
      (json['userReactions'] as Map).forEach((key, value) {
        if (value is Map) {
          parsedUserReactions[key.toString()] = {
            'name': value['name']?.toString() ?? 'Member',
            'emoji': value['emoji']?.toString() ?? '❤️',
            'avatar': value['avatar']?.toString() ?? '✝️',
          };
        }
      });
    }

    return ChatMessage(
      id: json['id'] ?? '',
      senderName: json['sender_name'] ?? 'YFC Member',
      senderAvatar: json['sender_avatar'] ?? '',
      messageType: json['message_type'] ?? 'text',
      textContent: json['text_content'] ?? '',
      mediaUrl: json['media_url'],
      mediaUrls: json['media_urls'] != null ? List<String>.from(json['media_urls']) : [],
      mediaTypes: json['media_types'] != null ? List<String>.from(json['media_types']) : [],
      audioDurationSeconds: json['audio_duration_seconds'] ?? 0,
      reactions: parsedReactions,
      userReactions: parsedUserReactions,
      isSystemBot: json['is_system_bot'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'message_type': messageType,
      'text_content': textContent,
      'media_url': mediaUrl,
      'media_urls': mediaUrls,
      'media_types': mediaTypes,
      'audio_duration_seconds': audioDurationSeconds,
      'reactions': reactions,
      'userReactions': userReactions,
      'is_system_bot': isSystemBot,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
