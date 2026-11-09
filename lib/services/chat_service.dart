import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message_model.dart';
import 'app_database.dart';
import 'member_service.dart';
import 'firebase_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  // C) Real-Time Fellowship Chat Sync
  Stream<QuerySnapshot> getChatStream() {
    return FirebaseFirestore.instance
        .collection('fellowship_chats')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }

  // D) Send message to Firestore
  Future<void> sendMessage({
    required String senderName,
    required String text,
    String? mediaUrl,
    String? type,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final msgId = 'msg_${DateTime.now().millisecondsSinceEpoch}';

    await FirebaseFirestore.instance.collection('fellowship_chats').add({
      'senderId': user?.uid ?? 'anonymous',
      'senderName': senderName,
      'text': text,
      'mediaUrl': mediaUrl,
      'type': type ?? 'text',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Also persist locally to SQLite
    final newMsg = ChatMessage(
      id: msgId,
      senderName: senderName,
      senderAvatar: "✝️",
      textContent: text,
      messageType: type ?? 'text',
      mediaUrl: mediaUrl,
      createdAt: DateTime.now(),
    );
    await saveMessage(newMsg);
  }

  // Load chat messages from local SQLite / Supabase and inject dynamic birthday & anniversary blessings
  Future<List<ChatMessage>> loadChatMessages() async {
    final List<ChatMessage> messages = [];
    final Set<String> loadedIds = {};

    // 1. Trigger dynamic birthday and anniversary bot blessings for registered members matching today's date
    await triggerDynamicBlessings();

    // 2. Fetch messages from local SQLite database
    try {
      final db = await AppDatabase().database;
      final rows = await db.query('chat_messages', orderBy: 'created_at ASC');
      for (final row in rows) {
        final id = row['id'] as String;
        if (!loadedIds.contains(id)) {
          loadedIds.add(id);
          Map<String, int> reactionsMap = {};
          if (row['reactions'] != null && (row['reactions'] as String).isNotEmpty) {
            try {
              final Map<String, dynamic> parsed = jsonDecode(row['reactions'] as String);
              reactionsMap = parsed.map((k, v) => MapEntry(k, (v as num).toInt()));
            } catch (_) {}
          }
          messages.add(ChatMessage(
            id: id,
            senderName: row['sender_name'] as String? ?? 'Fellowship Member',
            senderAvatar: row['sender_avatar'] as String? ?? '',
            textContent: row['text_content'] as String? ?? '',
            messageType: row['message_type'] as String? ?? 'text',
            mediaUrl: row['media_url'] as String?,
            audioDurationSeconds: row['audio_duration'] as int? ?? 0,
            reactions: reactionsMap,
            createdAt: DateTime.parse(row['created_at'] as String),
          ));
        }
      }
    } catch (_) {}

    // 3. Optionally fetch messages from Supabase real-time table
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.from('chat_messages').select().order('created_at', ascending: true).limit(50);
      for (final row in response) {
        final id = row['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString();
        if (!loadedIds.contains(id)) {
          loadedIds.add(id);
          messages.add(ChatMessage(
            id: id,
            senderName: row['sender_name'] as String? ?? 'Fellowship Member',
            senderAvatar: row['sender_avatar'] as String? ?? '',
            textContent: row['text_content'] as String? ?? '',
            messageType: row['message_type'] as String? ?? 'text',
            mediaUrl: row['media_url'] as String?,
            audioDurationSeconds: (row['audio_duration'] as num?)?.toInt() ?? 0,
            createdAt: DateTime.parse(row['created_at'] as String? ?? DateTime.now().toIso8601String()),
          ));
        }
      }
    } catch (_) {}

    return messages;
  }

  // Save new chat message to SQLite, Firestore, and Supabase
  Future<void> saveMessage(ChatMessage msg) async {
    try {
      final db = await AppDatabase().database;
      await db.insert('chat_messages', {
        'id': msg.id,
        'sender_name': msg.senderName,
        'sender_avatar': msg.senderAvatar,
        'text_content': msg.textContent,
        'message_type': msg.messageType,
        'media_url': msg.mediaUrl,
        'audio_duration': msg.audioDurationSeconds,
        'reactions': jsonEncode(msg.reactions),
        'created_at': msg.createdAt.toIso8601String(),
      });
    } catch (_) {}

    try {
      await FirebaseService().sendChatMessage(msg);
    } catch (_) {}

    try {
      final supabase = Supabase.instance.client;
      await supabase.from('chat_messages').insert({
        'id': msg.id,
        'sender_name': msg.senderName,
        'sender_avatar': msg.senderAvatar,
        'text_content': msg.textContent,
        'message_type': msg.messageType,
        'media_url': msg.mediaUrl,
        'audio_duration': msg.audioDurationSeconds,
        'created_at': msg.createdAt.toIso8601String(),
      });
    } catch (_) {}
  }

  // Check registered members for birthday or anniversary matching today's date
  Future<void> triggerDynamicBlessings() async {
    final now = DateTime.now();
    final todayMonthDay = DateFormat('MM-dd').format(now);
    final todayYearStr = DateFormat('yyyy-MM-dd').format(now);

    final members = await MemberService().fetchAllMembers();

    for (final member in members) {
      // 1. Check Birthday
      if (member.phoneNumber.isNotEmpty) {
        // Query member details from local DB to get DOB & anniversary
        try {
          final db = await AppDatabase().database;
          final rows = await db.query('members', where: 'phone_number = ?', whereArgs: [member.phoneNumber]);
          if (rows.isNotEmpty) {
            final row = rows.first;
            final dobStr = row['date_of_birth'] as String? ?? '';
            final annivStr = row['anniversary_date'] as String? ?? '';
            final maritalStatus = row['marital_status'] as String? ?? 'Single';

            // Check Birthday match
            if (dobStr.isNotEmpty) {
              try {
                final dobDate = DateTime.parse(dobStr);
                final dobMonthDay = DateFormat('MM-dd').format(dobDate);
                if (dobMonthDay == todayMonthDay) {
                  final bdayMsgId = 'bot_bday_${member.phoneNumber}_$todayYearStr';
                  // Check if bot message already created today
                  final existing = await db.query('chat_messages', where: 'id = ?', whereArgs: [bdayMsgId]);
                  if (existing.isEmpty) {
                    final bdayMsg = ChatMessage(
                      id: bdayMsgId,
                      senderName: "YFC Fellowship Bot 🎂",
                      senderAvatar: "🎂",
                      textContent: "🎉 Happy Birthday, ${member.fullName}!\n\n\"The LORD bless thee, and keep thee: The LORD make his face shine upon thee, and be gracious unto thee: The LORD lift up his countenance upon thee, and give thee peace.\" (Numbers 6:24-26)",
                      messageType: 'celebration',
                      createdAt: DateTime.now(),
                      reactions: {"🙏": 1, "✨": 1},
                    );
                    await saveMessage(bdayMsg);
                  }
                }
              } catch (_) {}
            }

            // Check Wedding Anniversary match
            if (maritalStatus == 'Married' && annivStr.isNotEmpty) {
              try {
                final annivDate = DateTime.parse(annivStr);
                final annivMonthDay = DateFormat('MM-dd').format(annivDate);
                if (annivMonthDay == todayMonthDay) {
                  final annivMsgId = 'bot_anniv_${member.phoneNumber}_$todayYearStr';
                  final existing = await db.query('chat_messages', where: 'id = ?', whereArgs: [annivMsgId]);
                  if (existing.isEmpty) {
                    final annivMsg = ChatMessage(
                      id: annivMsgId,
                      senderName: "YFC Fellowship Bot 💍",
                      senderAvatar: "💍",
                      textContent: "💐 Happy Wedding Anniversary, ${member.fullName} & Family!\n\n\"Thy wife shall be as a fruitful vine by the sides of thine house: thy children like olive plants round about thy table.\" (Psalm 128:3)",
                      messageType: 'celebration',
                      createdAt: DateTime.now(),
                      reactions: {"❤️": 1, "💐": 1},
                    );
                    await saveMessage(annivMsg);
                  }
                }
              } catch (_) {}
            }
          }
        } catch (_) {}
      }
    }
  }
}
