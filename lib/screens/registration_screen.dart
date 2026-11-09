import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'home_dashboard.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  DateTime _dob = DateTime.now().subtract(const Duration(days: 365 * 22));
  DateTime? _anniversaryDate;
  String _maritalStatus = "Single"; // Single or Married
  String _preferredLanguage = "EN"; // EN or TE
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDOB(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dob,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.shiningRed,
              onPrimary: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dob) {
      setState(() {
        _dob = picked;
      });
    }
  }

  Future<void> _selectAnniversaryDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _anniversaryDate ?? DateTime.now().subtract(const Duration(days: 365 * 2)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.goldAccent,
              onPrimary: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _anniversaryDate = picked;
      });
    }
  }

  void _submitRegistration() async {
    final appState = Provider.of<AppState>(context, listen: false);

    // 1. Mandatory Profile Picture Check
    if (appState.avatarUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile picture is mandatory. Please tap the camera icon to select your photo."),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    // 2. Mandatory Marriage Anniversary Date Check
    if (_maritalStatus == "Married" && _anniversaryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Marriage Anniversary Date is strictly mandatory for married members."),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final success = await appState.registerUserProfile(
      fullName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      dateOfBirth: DateFormat('yyyy-MM-dd').format(_dob),
      maritalStatus: _maritalStatus,
      anniversaryDate: _anniversaryDate != null ? DateFormat('yyyy-MM-dd').format(_anniversaryDate!) : "",
      preferredLanguage: _preferredLanguage,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeDashboard()),
      );
    } else {
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registration saved locally. Welcome to YFC!"),
          backgroundColor: AppTheme.statusGreen,
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeDashboard()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.surfaceCardDark : AppTheme.surfaceCardLight;
    final textColor = isDark ? AppTheme.textLight : AppTheme.textDark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgPrimaryDark : AppTheme.bgPrimaryLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                
                // Header Logo Banner
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.goldAccent.withAlpha(35),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.goldAccent.withAlpha(80)),
                      ),
                      child: const Icon(Icons.church_rounded, color: AppTheme.goldAccent, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "YFC FELLOWSHIP",
                            style: GoogleFonts.cinzel(
                              color: AppTheme.goldAccent,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            "First-Time Member Registration",
                            style: TextStyle(
                              color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Avatar / DP Picker Component
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      final appState = Provider.of<AppState>(context, listen: false);
                      final picker = ImagePicker();
                      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        await appState.uploadProfileImage(pickedFile);
                        setState(() {});
                      }
                    },
                    child: Builder(builder: (context) {
                      final appState = Provider.of<AppState>(context);
                      final avatarUrl = appState.avatarUrl;
                      ImageProvider? imageProvider;
                      if (avatarUrl.isNotEmpty) {
                        if (avatarUrl.startsWith('http')) {
                          imageProvider = NetworkImage(avatarUrl);
                        } else {
                          imageProvider = FileImage(File(avatarUrl));
                        }
                      }

                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.goldAccent, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.goldAccent.withAlpha(60),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 44,
                              backgroundColor: AppTheme.shiningRed,
                              backgroundImage: imageProvider,
                              child: imageProvider == null
                                  ? const Icon(Icons.person_rounded, size: 48, color: Colors.white)
                                  : null,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppTheme.goldAccent,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 18, color: AppTheme.textDark),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  "Welcome to the Family! ✝️",
                  style: GoogleFonts.cinzel(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Please complete your profile to receive automated birthday & anniversary fellowship prayers.",
                  style: TextStyle(color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted, fontSize: 13),
                ),

                const SizedBox(height: 28),

                // Form Container Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.goldAccent.withAlpha(60)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isDark ? 50 : 15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full Name Field
                      Text(
                        "Full Name *",
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: "Enter your full name",
                          hintStyle: TextStyle(color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted),
                          prefixIcon: const Icon(Icons.person_outline_rounded, color: AppTheme.goldAccent),
                          filled: true,
                          fillColor: isDark ? AppTheme.bgPrimaryDark : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.goldAccent.withAlpha(50)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Full Name is required";
                          }
                          if (value.trim().length < 3) {
                            return "Full Name must be at least 3 characters";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      // Phone Number Field
                      Text(
                        "Phone Number *",
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: "Enter 10-digit mobile number",
                          hintStyle: TextStyle(color: isDark ? AppTheme.textMutedDark : AppTheme.textMuted),
                          prefixIcon: const Icon(Icons.phone_android_rounded, color: AppTheme.goldAccent),
                          filled: true,
                          fillColor: isDark ? AppTheme.bgPrimaryDark : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.goldAccent.withAlpha(50)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Phone number is required";
                          }
                          final clean = value.replaceAll(RegExp(r'\D'), '');
                          if (clean.length < 10) {
                            return "Please enter a valid 10-digit mobile number";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      // Date of Birth Picker Tile
                      Text(
                        "Date of Birth 🎂 *",
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => _selectDOB(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.bgPrimaryDark : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.goldAccent.withAlpha(60)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.cake_rounded, color: AppTheme.goldAccent, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    DateFormat('dd MMMM yyyy').format(_dob),
                                    style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                ],
                              ),
                              const Icon(Icons.calendar_month_rounded, color: AppTheme.goldAccent, size: 18),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Marital Status Segment
                      Text(
                        "Marital Status *",
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text("Single")),
                              selected: _maritalStatus == "Single",
                              selectedColor: AppTheme.shiningRed,
                              labelStyle: TextStyle(
                                color: _maritalStatus == "Single" ? Colors.white : textColor,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _maritalStatus = "Single";
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text("Married 💍")),
                              selected: _maritalStatus == "Married",
                              selectedColor: AppTheme.shiningRed,
                              labelStyle: TextStyle(
                                color: _maritalStatus == "Married" ? Colors.white : textColor,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _maritalStatus = "Married";
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),

                      // Conditional Anniversary Date Picker
                      if (_maritalStatus == "Married") ...[
                        const SizedBox(height: 18),
                        Text(
                          "Wedding Anniversary Date 💒 *",
                          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () => _selectAnniversaryDate(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.bgPrimaryDark : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.goldAccent.withAlpha(60)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.favorite_rounded, color: AppTheme.shiningRed, size: 20),
                                    const SizedBox(width: 10),
                                    Text(
                                      _anniversaryDate != null
                                          ? DateFormat('dd MMMM yyyy').format(_anniversaryDate!)
                                          : "Select Anniversary Date",
                                      style: TextStyle(
                                        color: _anniversaryDate != null ? textColor : AppTheme.textMuted,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const Icon(Icons.calendar_month_rounded, color: AppTheme.goldAccent, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),

                      // Preferred Language Segment
                      Text(
                        "Preferred App Language",
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text("English 🇬🇧")),
                              selected: _preferredLanguage == "EN",
                              selectedColor: AppTheme.goldAccent,
                              labelStyle: TextStyle(
                                color: _preferredLanguage == "EN" ? Colors.white : textColor,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _preferredLanguage = "EN";
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text("తెలుగు 🇮🇳")),
                              selected: _preferredLanguage == "TE",
                              selectedColor: AppTheme.goldAccent,
                              labelStyle: TextStyle(
                                color: _preferredLanguage == "TE" ? Colors.white : textColor,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _preferredLanguage = "TE";
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.shiningRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _preferredLanguage == "TE" ? "సమర్పించండి ✝️" : "Complete Registration ✝️",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
