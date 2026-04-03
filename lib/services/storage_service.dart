import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  Future<String> uploadProfilePhoto(String userId, File file) async {
    final ext = file.path.split('.').last;
    final ref = _storage.ref().child('profiles/$userId/photo.$ext');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<String> uploadPortfolioItem(String userId, File file) async {
    final fileName = '${_uuid.v4()}.${file.path.split('.').last}';
    final ref = _storage.ref().child('portfolios/$userId/$fileName');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<String> uploadJobAttachment(String jobId, File file) async {
    final fileName = '${_uuid.v4()}.${file.path.split('.').last}';
    final ref = _storage.ref().child('job_attachments/$jobId/$fileName');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<String> uploadChatMedia(String chatRoomId, File file) async {
    final fileName = '${_uuid.v4()}.${file.path.split('.').last}';
    final ref = _storage.ref().child('chat_media/$chatRoomId/$fileName');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {
      // File may not exist; ignore.
    }
  }
}
