import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/members_directory_screen.dart';
import 'app_database.dart';
import 'firebase_service.dart';

class MemberService {
  static final MemberService _instance = MemberService._internal();
  factory MemberService() => _instance;
  MemberService._internal();

  static const List<String> adminNumbers = [
    '6304300354',
    '9502223426',
  ];

  static bool isAuthorizedAdmin(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 10) {
      final last10 = digits.substring(digits.length - 10);
      return adminNumbers.contains(last10);
    }
    return false;
  }

  // E) Centralized Member Directory Sync
  Future<void> registerMemberProfile({
    required String name,
    required String phone,
    String? role,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final assignedRole = isAuthorizedAdmin(phone) ? 'ADMIN' : (role ?? 'Member');

    await FirebaseFirestore.instance.collection('members').doc(user.uid).set({
      'uid': user.uid,
      'name': name,
      'phone': phone,
      'role': assignedRole,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await saveMemberProfile(
      fullName: name,
      phoneNumber: phone,
      dateOfBirth: '',
      maritalStatus: 'Single',
      preferredLanguage: 'EN',
    );
  }

  // Save registered member to SQLite local DB, Supabase, and Firestore
  Future<void> saveMemberProfile({
    required String fullName,
    required String phoneNumber,
    required String dateOfBirth,
    required String maritalStatus,
    String anniversaryDate = "",
    required String preferredLanguage,
    String avatarUrl = "",
  }) async {
    final role = isAuthorizedAdmin(phoneNumber) ? 'Admin' : 'Member';
    final nowIso = DateTime.now().toIso8601String();
    final memberId = 'mem_${DateTime.now().millisecondsSinceEpoch}';

    // 1. Insert/Update into Local SQLite DB
    try {
      final db = await AppDatabase().database;
      await db.insert(
        'members',
        {
          'id': memberId,
          'full_name': fullName,
          'phone_number': phoneNumber,
          'date_of_birth': dateOfBirth,
          'marital_status': maritalStatus,
          'anniversary_date': anniversaryDate,
          'preferred_language': preferredLanguage,
          'avatar_url': avatarUrl,
          'role': role,
          'registered_at': nowIso,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}

    // 2. Insert/Update into Firebase Cloud Firestore
    try {
      await FirebaseService().saveMemberProfile(
        fullName: fullName,
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth,
        maritalStatus: maritalStatus,
        anniversaryDate: anniversaryDate,
        preferredLanguage: preferredLanguage,
        avatarUrl: avatarUrl,
        role: role,
      );
    } catch (_) {}

    // 3. Insert/Update into Supabase `profiles` table if available
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('profiles').upsert({
        'full_name': fullName,
        'phone_number': phoneNumber,
        'date_of_birth': dateOfBirth,
        'marital_status': maritalStatus,
        'anniversary_date': anniversaryDate,
        'preferred_language': preferredLanguage,
        'avatar_url': avatarUrl,
        'role': role,
        'updated_at': nowIso,
      });
    } catch (_) {}
  }

  // Fetch all registered members from Supabase / SQLite
  Future<List<MemberModel>> fetchAllMembers() async {
    final List<MemberModel> membersList = [];
    final Set<String> addedPhones = {};

    // 1. Try Supabase remote profiles table
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.from('profiles').select().order('full_name', ascending: true);
      for (final row in response) {
        final name = row['full_name'] as String? ?? 'YFC Member';
        final phone = row['phone_number'] as String? ?? '';
        final avatar = row['avatar_url'] as String? ?? '';
        final role = isAuthorizedAdmin(phone) ? 'Admin' : (row['role'] as String? ?? 'Member');
        final id = row['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString();

        if (phone.isNotEmpty && !addedPhones.contains(phone)) {
          addedPhones.add(phone);
          membersList.add(MemberModel(
            id: id,
            fullName: name,
            phoneNumber: phone,
            avatarUrl: avatar,
            role: role,
          ));
        }
      }
    } catch (_) {}

    // 2. Load local SQLite database members
    try {
      final db = await AppDatabase().database;
      final rows = await db.query('members', orderBy: 'full_name ASC');
      for (final row in rows) {
        final phone = row['phone_number'] as String? ?? '';
        if (phone.isNotEmpty && !addedPhones.contains(phone)) {
          addedPhones.add(phone);
          membersList.add(MemberModel(
            id: row['id'] as String? ?? '',
            fullName: row['full_name'] as String? ?? 'YFC Member',
            phoneNumber: phone,
            avatarUrl: row['avatar_url'] as String? ?? '',
            role: isAuthorizedAdmin(phone) ? 'Admin' : (row['role'] as String? ?? 'Member'),
          ));
        }
      }
    } catch (_) {}

    return membersList;
  }
}
