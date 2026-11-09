import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // Cloudinary credentials
  static const String cloudName = 'nfwc0c1e';
  static const String uploadPreset = 'yfc_profile_pics';

  static Future<String?> uploadImage(File imageFile) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(responseBody);
        return data['secure_url'] as String?;
      } else {
        debugPrint('Cloudinary upload error: $responseBody');
        return null;
      }
    } catch (e) {
      debugPrint('Exception during Cloudinary upload: $e');
      return null;
    }
  }
}