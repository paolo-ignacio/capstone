import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadFile({
    required String uid,
    required String chatId,
    required String fileName,
    required Uint8List fileBytes,
    required String contentType,
  }) async {
    try {
      // Create the file path
      final String filePath = 'user_documents/$uid/$chatId/$fileName';
      
      // Create storage reference
      final storageRef = _storage.ref().child(filePath);

      // Set metadata
      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'uploadedBy': uid,
          'chatId': chatId,
          'fileName': fileName,
          'uploadedAt': DateTime.now().toUtc().toString(),
        },
      );

      // Upload file
      await storageRef.putData(fileBytes, metadata);

      // Get download URL
      final downloadUrl = await storageRef.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      throw Exception('Failed to upload file: $e');
    }
  }
}