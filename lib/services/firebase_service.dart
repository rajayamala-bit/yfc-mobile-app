import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_message_model.dart';
import '../screens/members_directory_screen.dart';
import 'notification_service.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  String? get currentUid => _auth.currentUser?.uid;

  // Initialize Anonymous Authentication in Background (Zero-login architecture)
  Future<User?> initAnonymousAuth() async {
    try {
      if (_auth.currentUser != null) {
        debugPrint("[FirebaseService] Existing anonymous user: ${_auth.currentUser?.uid}");
        return _auth.currentUser;
      }
      final userCredential = await _auth.signInAnonymously();
      debugPrint("[FirebaseService] Signed in anonymously with UID: ${userCredential.user?.uid}");
      return userCredential.user;
    } catch (e) {
      debugPrint("[FirebaseService] Anonymous sign-in error: $e");
      return null;
    }
  }

  // --- Real-time Firestore Chat Sync ---

  // Stream real-time chat messages from Firestore `chat_messages` collection
  Stream<List<ChatMessage>> streamChatMessages() {
    return _firestore
        .collection('chat_messages')
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null) {
            final msgUid = data['uid'] as String? ?? '';
            final senderName = data['sender_name'] as String? ?? 'Fellowship Member';
            final textContent = data['text_content'] as String? ?? 'Sent a message';
            if (msgUid.isNotEmpty && msgUid != currentUid) {
              try {
                NotificationService.showNotification(
                  title: senderName,
                  body: textContent,
                );
              } catch (_) {}
            }
          }
        }
      }
      return snapshot.docs.map((doc) {
        final data = doc.data();
        Map<String, int> reactionsMap = {};
        if (data['reactions'] != null && data['reactions'] is Map) {
          final Map mapData = data['reactions'] as Map;
          reactionsMap = mapData.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
        }

        DateTime createdAt = DateTime.now();
        if (data['created_at'] != null) {
          if (data['created_at'] is Timestamp) {
            createdAt = (data['created_at'] as Timestamp).toDate();
          } else if (data['created_at'] is String) {
            createdAt = DateTime.tryParse(data['created_at'] as String) ?? DateTime.now();
          }
        }

        return ChatMessage(
          id: doc.id,
          senderName: data['sender_name'] as String? ?? 'Fellowship Member',
          senderAvatar: data['sender_avatar'] as String? ?? '',
          textContent: data['text_content'] as String? ?? '',
          messageType: data['message_type'] as String? ?? 'text',
          mediaUrl: data['media_url'] as String?,
          audioDurationSeconds: (data['audio_duration'] as num?)?.toInt() ?? 0,
          reactions: reactionsMap,
          createdAt: createdAt,
        );
      }).toList();
    });
  }

  // Send message to Firestore `chat_messages` collection
  Future<void> sendChatMessage(ChatMessage msg) async {
    try {
      await _firestore.collection('chat_messages').doc(msg.id).set({
        'id': msg.id,
        'sender_name': msg.senderName,
        'sender_avatar': msg.senderAvatar,
        'text_content': msg.textContent,
        'message_type': msg.messageType,
        'media_url': msg.mediaUrl,
        'audio_duration': msg.audioDurationSeconds,
        'reactions': msg.reactions,
        'created_at': FieldValue.serverTimestamp(),
        'uid': currentUid,
      });
    } catch (e) {
      debugPrint("[FirebaseService] Error sending Firestore message: $e");
    }
  }

  // --- Real-time Firestore Members Sync ---

  // Save registered profile to Firestore `members` collection
  Future<void> saveMemberProfile({
    required String fullName,
    required String phoneNumber,
    required String dateOfBirth,
    required String maritalStatus,
    String anniversaryDate = "",
    required String preferredLanguage,
    String avatarUrl = "",
    required String role,
  }) async {
    try {
      final docId = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
      await _firestore.collection('members').doc(docId.isNotEmpty ? docId : currentUid).set({
        'full_name': fullName,
        'phone_number': phoneNumber,
        'date_of_birth': dateOfBirth,
        'marital_status': maritalStatus,
        'anniversary_date': anniversaryDate,
        'preferred_language': preferredLanguage,
        'avatar_url': avatarUrl,
        'role': role,
        'uid': currentUid,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("[FirebaseService] Error saving member profile to Firestore: $e");
    }
  }

  // Stream real-time members list from Firestore `members` collection
  Stream<List<MemberModel>> streamMembers() {
    return _firestore
        .collection('members')
        .orderBy('full_name', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return MemberModel(
          id: doc.id,
          fullName: data['full_name'] as String? ?? 'YFC Member',
          phoneNumber: data['phone_number'] as String? ?? '',
          avatarUrl: data['avatar_url'] as String? ?? '',
          role: data['role'] as String? ?? 'Member',
        );
      }).toList();
    });
  }
}
