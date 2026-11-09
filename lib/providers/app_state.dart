import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/cloudinary_service.dart';
import '../services/member_service.dart';

class AppState extends ChangeNotifier {
  // Theme Mode State (Light vs Celestial Navy Dark)
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Universal Language Toggle (EN / TE)
  bool _isTelugu = false;
  bool get isTelugu => _isTelugu;

  // Active Bottom Navigation Index
  int _currentNavIndex = 0;
  int get currentNavIndex => _currentNavIndex;

  // User Profile State
  bool _isRegistered = false;
  final String _activeUserId = "usr-yfc-101";
  String _activeUserName = "YFC Member";
  String _phoneNumber = "";
  String _dateOfBirth = "";
  String _maritalStatus = "Single"; // Single / Married
  String _anniversaryDate = "";
  String _preferredLanguage = "EN";
  String _avatarUrl = "";
  String _role = "member";

  bool get isRegistered => _isRegistered;
  String get activeUserId => _activeUserId;
  String get activeUserName => _activeUserName;
  String get profileName => _activeUserName;
  String get phoneNumber => _phoneNumber;
  String get dateOfBirth => _dateOfBirth;
  String get maritalStatus => _maritalStatus;
  String get anniversaryDate => _anniversaryDate;
  String get preferredLanguage => _preferredLanguage;
  String get avatarUrl => _avatarUrl;
  String get role => _role;
  static const List<String> authorizedAdminNumbers = [
    '6304300354',
    '9502223426',
    '+916304300354',
    '+919502223426',
  ];

  bool get isAdmin {
    String supabaseUserPhone = '';
    try {
      supabaseUserPhone = Supabase.instance.client.auth.currentUser?.phone ?? '';
    } catch (_) {}
    final combinedPhone = _phoneNumber.isNotEmpty ? _phoneNumber : supabaseUserPhone;
    final digits = combinedPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 10) {
      final last10 = digits.substring(digits.length - 10);
      return last10 == '6304300354' || last10 == '9502223426';
    }
    return false;
  }

  void setUserRole(String newRole) {
    _role = newRole;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (_) {}
    _isRegistered = false;
    _activeUserName = "YFC Member";
    _phoneNumber = "";
    _avatarUrl = "";
    _role = "member";
    notifyListeners();
  }

  // Fellowship Google Meet & Support Links
  static const String googleMeetUrl = "https://meet.google.com/vtu-qgxk-zrv";
  static const String whatsappSupportUrl = "https://wa.me/919154300354?text=Hi%20YFC%20Support,%20I%20need%20assistance";

  // Countdown Timer State
  Timer? _countdownTimer;
  Duration _timeUntilNextFellowship = Duration.zero;
  String _nextFellowshipTitle = "Morning Prayer (5:00 AM)";

  Duration get timeUntilNextFellowship => _timeUntilNextFellowship;
  String get nextFellowshipTitle => _nextFellowshipTitle;

  String get nextFellowshipMainTitle {
    final now = DateTime.now();
    final morningToday = DateTime(now.year, now.month, now.day, 5, 0, 0);
    final eveningToday = DateTime(now.year, now.month, now.day, 21, 0, 0);
    if (now.isBefore(morningToday)) {
      return _isTelugu ? "ఉదయకాల ప్రార్థన" : "Morning Prayer";
    } else if (now.isBefore(eveningToday)) {
      return _isTelugu ? "సాయంత్రం బైబిల్ అధ్యయనం" : "Evening Bible Study";
    } else {
      return _isTelugu ? "ఉదయకాల ప్రార్థన" : "Morning Prayer";
    }
  }

  String get nextFellowshipTimeSubtext {
    final now = DateTime.now();
    final morningToday = DateTime(now.year, now.month, now.day, 5, 0, 0);
    final eveningToday = DateTime(now.year, now.month, now.day, 21, 0, 0);
    if (now.isBefore(morningToday)) {
      return "(5:00 AM)";
    } else if (now.isBefore(eveningToday)) {
      return "(9:00 PM)";
    } else {
      return "(5:00 AM)";
    }
  }

  AppState() {
    _startCountdownTimer();
    loadSavedPreferences();
  }

  // Load preferences from SharedPreferences
  Future<void> loadSavedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Theme Mode
      final savedTheme = prefs.getString('yfc_theme_mode') ?? 'dark';
      _themeMode = savedTheme == 'light' ? ThemeMode.light : ThemeMode.dark;

      // Registration Profile
      final savedPhone = prefs.getString('user_phone') ?? "";
      final isReg = prefs.getBool('is_registered') ?? false;

      if (savedPhone.trim().isEmpty) {
        _isRegistered = false;
        _phoneNumber = "";
        _activeUserName = "YFC Member";
      } else {
        _isRegistered = isReg;
        _phoneNumber = savedPhone;
        _activeUserName = prefs.getString('user_full_name') ?? "YFC Member";
      }

      _dateOfBirth = prefs.getString('user_dob') ?? "";
      _maritalStatus = prefs.getString('user_marital_status') ?? "Single";
      _anniversaryDate = prefs.getString('user_anniversary_date') ?? "";
      _preferredLanguage = prefs.getString('user_language') ?? "EN";
      _avatarUrl = prefs.getString('user_avatar_url') ?? "";
      _isTelugu = _preferredLanguage == "TE";

      notifyListeners();
    } catch (_) {}
  }

  // Update Avatar URL directly
  Future<void> updateAvatarUrl(String url) async {
    // Only proceed if it is a valid public network URL (never sandbox /data/... path)
    if (!url.startsWith('http')) return;

    _avatarUrl = url;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_avatar_url', url);

      // 1. Direct write to Firestore members collection using phone number as document ID
      if (_phoneNumber.isNotEmpty) {
        try {
          final docRef = FirebaseFirestore.instance.collection('members').doc(_phoneNumber);
          await docRef.set({
            'avatar_url': url,
            'avatarUrl': url,
            'updated_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('[AppState] Firestore avatar sync error: $e');
        }
      }

      // 2. Write to Supabase profiles table
      try {
        final supabase = Supabase.instance.client;
        await supabase.from('profiles').upsert({
          'phone_number': _phoneNumber,
          'avatar_url': url,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('[AppState] Supabase avatar sync error: $e');
      }
    } catch (_) {}
  }

  // Crop Image before upload
  Future<XFile?> cropProfilePhoto(XFile imageFile) async {
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Photo',
            toolbarColor: const Color(0xFFD90429),
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: const Color(0xFFD4AF37),
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
            ],
          ),
          IOSUiSettings(
            title: 'Crop Profile Photo',
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
            ],
          ),
        ],
      );
      if (cropped != null) {
        return XFile(cropped.path);
      }
      return imageFile;
    } catch (_) {
      return imageFile;
    }
  }

  // Pick, Crop & Upload Profile Image to Cloudinary
  Future<String?> uploadProfileImage(XFile originalFile) async {
    try {
      final imageFile = await cropProfilePhoto(originalFile) ?? originalFile;
      final file = File(imageFile.path);

      // Upload directly to Cloudinary (returns public https:// URL)
      final uploadedUrl = await CloudinaryService.uploadImage(file);

      // Never fall back to local sandbox path
      if (uploadedUrl != null && uploadedUrl.startsWith('http')) {
        await updateAvatarUrl(uploadedUrl);
        return uploadedUrl;
      }
      return null;
    } catch (e) {
      debugPrint('[AppState] uploadProfileImage error: $e');
      return null;
    }
  }

  // Pending external shared content state
  String _pendingSharedText = "";
  String _pendingSharedImagePath = "";
  String _pendingSharedVideoPath = "";

  String get pendingSharedText => _pendingSharedText;
  String get pendingSharedImagePath => _pendingSharedImagePath;
  String get pendingSharedVideoPath => _pendingSharedVideoPath;

  void setPendingSharedContent({String text = "", String imagePath = "", String videoPath = ""}) {
    _pendingSharedText = text;
    _pendingSharedImagePath = imagePath;
    _pendingSharedVideoPath = videoPath;
    _currentNavIndex = 1; // Auto switch to Chat tab (index 1)
    notifyListeners();
  }

  void clearPendingSharedContent() {
    _pendingSharedText = "";
    _pendingSharedImagePath = "";
    _pendingSharedVideoPath = "";
    notifyListeners();
  }

  // Upload Chat Photo to Supabase Storage `chat-media` bucket
  Future<String> uploadChatMedia(XFile originalFile) async {
    String finalUrl = originalFile.path;
    try {
      final bytes = await originalFile.readAsBytes();
      final fileExt = originalFile.name.contains('.') ? originalFile.name.split('.').last : 'jpg';
      final fileName = 'chat_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'media/$fileName';

      try {
        final supabase = Supabase.instance.client;
        await supabase.storage.from('chat-media').uploadBinary(
          filePath,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
        finalUrl = supabase.storage.from('chat-media').getPublicUrl(filePath);
      } catch (_) {
        // Fallback to local image path if offline / Supabase bucket not initialized
      }
    } catch (_) {}
    return finalUrl;
  }

  // Theme Toggle
  Future<void> toggleThemeMode() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('yfc_theme_mode', _themeMode == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {}
  }

  // Language Toggle
  void toggleLanguage() {
    _isTelugu = !_isTelugu;
    _preferredLanguage = _isTelugu ? "TE" : "EN";
    notifyListeners();

    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('user_language', _preferredLanguage);
      prefs.setString('app_language', _preferredLanguage);
    }).catchError((_) {});
  }

  int _selectedBibleBookId = 1;
  int _selectedBibleChapter = 1;

  int get selectedBibleBookId => _selectedBibleBookId;
  int get selectedBibleChapter => _selectedBibleChapter;

  void openBibleToPassage(int bookId, int chapter) {
    _selectedBibleBookId = bookId;
    _selectedBibleChapter = chapter;
    _currentNavIndex = 2; // Auto switch to Bible Reader tab (index 2)
    notifyListeners();
  }

  void updateBiblePassage(int bookId, int chapter) {
    _selectedBibleBookId = bookId;
    _selectedBibleChapter = chapter;
    notifyListeners();
  }

  void setNavIndex(int index) {
    _currentNavIndex = index;
    notifyListeners();
  }

  // Save User Profile on Registration
  Future<bool> registerUserProfile({
    required String fullName,
    required String phoneNumber,
    required String dateOfBirth,
    required String maritalStatus,
    String anniversaryDate = "",
    required String preferredLanguage,
  }) async {
    try {
      _activeUserName = fullName;
      _phoneNumber = phoneNumber;
      _dateOfBirth = dateOfBirth;
      _maritalStatus = maritalStatus;
      _anniversaryDate = anniversaryDate;
      _preferredLanguage = preferredLanguage;
      _isTelugu = preferredLanguage == "TE";
      _isRegistered = true;

      notifyListeners();

      // Save locally to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_registered', true);
      await prefs.setString('user_full_name', fullName);
      await prefs.setString('user_phone', phoneNumber);
      await prefs.setString('user_dob', dateOfBirth);
      await prefs.setString('user_marital_status', maritalStatus);
      await prefs.setString('user_anniversary_date', anniversaryDate);
      await prefs.setString('user_language', preferredLanguage);

      // Save via MemberService (Local SQLite + Supabase)
      await MemberService().saveMemberProfile(
        fullName: fullName,
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth,
        maritalStatus: maritalStatus,
        anniversaryDate: anniversaryDate,
        preferredLanguage: preferredLanguage,
        avatarUrl: _avatarUrl,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  // Countdown Calculation
  void _startCountdownTimer() {
    _calculateNextFellowshipTime();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateNextFellowshipTime();
      notifyListeners();
    });
  }

  void _calculateNextFellowshipTime() {
    final now = DateTime.now();
    
    final morningToday = DateTime(now.year, now.month, now.day, 5, 0, 0);
    final eveningToday = DateTime(now.year, now.month, now.day, 21, 0, 0);

    DateTime target;
    if (now.isBefore(morningToday)) {
      target = morningToday;
      _nextFellowshipTitle = _isTelugu ? "ఉదయకాల ప్రార్థన (5:00 AM)" : "Morning Prayer (5:00 AM)";
    } else if (now.isBefore(eveningToday)) {
      target = eveningToday;
      _nextFellowshipTitle = _isTelugu ? "సాయంత్రం బైబిల్ అధ్యయనం (9:00 PM)" : "Evening Bible Study (9:00 PM)";
    } else {
      target = DateTime(now.year, now.month, now.day + 1, 5, 0, 0);
      _nextFellowshipTitle = _isTelugu ? "ఉదయకాల ప్రార్థన (5:00 AM)" : "Morning Prayer (5:00 AM)";
    }

    _timeUntilNextFellowship = target.difference(now);
  }

  String get formattedCountdownTime {
    final hours = _timeUntilNextFellowship.inHours.toString().padLeft(2, '0');
    final minutes = (_timeUntilNextFellowship.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_timeUntilNextFellowship.inSeconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
