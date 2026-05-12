import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

final storageServiceProvider =
    Provider<StorageService>((ref) => StorageService());

/// ⚙️ CLOUDINARY CONFIGURATION
/// 1. Sign up free at https://cloudinary.com (no credit card)
/// 2. From your dashboard, copy your Cloud Name
/// 3. Go to Settings → Upload → Add upload preset → set to "Unsigned" → Save
/// 4. Replace the values below with your own
class CloudinaryConfig {
  static const String cloudName = 'dewgai40c'; // e.g. 'abc123xyz'
  static const String uploadPreset = 'campusconnect_unsigned'; // e.g. 'campusconnect_unsigned'
  static String get uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
}

class StorageService {
  final ImagePicker _picker = ImagePicker();

  // ─── Image Picking ───────────────────────────────────────────────────────

  Future<File?> pickImage({bool fromCamera = false}) async {
    final xFile = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (xFile == null) return null;
    return File(xFile.path);
  }

  Future<List<File>> pickMultipleImages({int max = 6}) async {
    final xFiles = await _picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    return xFiles.take(max).map((x) => File(x.path)).toList();
  }

  // ─── Core Upload via Cloudinary REST API ────────────────────────────────

  Future<String> _uploadToCloudinary(File file, {String? folder}) async {
    final uri = Uri.parse(CloudinaryConfig.uploadUrl);

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    if (folder != null) {
      request.fields['folder'] = folder;
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return data['secure_url'] as String;
    } else {
      final error = json.decode(response.body);
      throw Exception('Cloudinary upload failed: ${error['error']['message']}');
    }
  }

  // ─── Upload Methods ──────────────────────────────────────────────────────

  Future<String> uploadAvatar(String uid, File file) async {
    return _uploadToCloudinary(file, folder: 'campus_connect/avatars/$uid');
  }

  Future<String> uploadPortfolioImage(String uid, File file) async {
    return _uploadToCloudinary(file, folder: 'campus_connect/portfolio/$uid');
  }

  Future<List<String>> uploadPortfolioImages(
      String uid, List<File> files) async {
    final futures = files.map((f) => uploadPortfolioImage(uid, f));
    return Future.wait(futures);
  }

  Future<String> uploadGigAttachment(String gigId, File file) async {
    return _uploadToCloudinary(file, folder: 'campus_connect/gigs/$gigId');
  }

  Future<String> uploadChatImage(String chatId, File file) async {
    return _uploadToCloudinary(file, folder: 'campus_connect/chats/$chatId');
  }

  // ─── Delete (no-op without paid Cloudinary plan) ────────────────────────

  Future<void> deleteByUrl(String url) async {
    // Deletion requires Cloudinary's Admin API (still free tier eligible).
    // For now, images are kept — Cloudinary's free plan gives 25 GB.
  }
}
