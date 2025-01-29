import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads an image to Firebase Storage and returns the download URL.
  static Future<String> uploadImage(
    String folder,
    String fileName,
    Uint8List bytes,
  ) async {
    try {
      // Validate file size (max 5MB)
      if (bytes.length > 5 * 1024 * 1024) {
        throw Exception('File size exceeds 5MB limit');
      }

      // Generate timestamp for unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Clean filename and create path
      final cleanFileName = fileName.replaceAll(RegExp(r'[^\w\s-]'), '');
      final path = '$folder/${cleanFileName}_$timestamp.jpg';
      
      // Create storage reference
      final ref = _storage.ref().child(path);

      // Set metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'timestamp': timestamp.toString(),
          'originalName': fileName,
        },
      );

      // Create upload task with retry logic
      int retryCount = 0;
      const maxRetries = 3;
      UploadTask? uploadTask;
      String? downloadUrl;

      while (retryCount < maxRetries && downloadUrl == null) {
        try {
          if (retryCount > 0) {
            debugPrint('Retrying upload (attempt ${retryCount + 1}/$maxRetries)');
            await Future.delayed(Duration(seconds: retryCount * 2)); // Exponential backoff
          }

          uploadTask = ref.putData(bytes, metadata);

          // Monitor upload progress
          uploadTask.snapshotEvents.listen(
            (TaskSnapshot snapshot) {
              final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
              debugPrint('Upload progress: ${progress.toStringAsFixed(2)}%');
            },
            onError: (e) {
              debugPrint('Error during upload: $e');
            },
            cancelOnError: true,
          );

          // Wait for upload to complete
          await uploadTask;
          
          // Get download URL
          downloadUrl = await ref.getDownloadURL();
          break; // Success, exit retry loop
        } catch (e) {
          debugPrint('Upload attempt ${retryCount + 1} failed: $e');
          if (uploadTask != null) {
            uploadTask.cancel();
          }
          retryCount++;
          if (retryCount >= maxRetries) {
            rethrow; // All retries failed
          }
        }
      }

      if (downloadUrl == null) {
        throw Exception('Failed to get download URL after $maxRetries attempts');
      }

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Uploads a file to Firebase Storage and returns the download URL.
  static Future<String> uploadFile(dynamic file, String path) async {
    try {
      final ref = _storage.ref().child(path);
      UploadTask uploadTask;

      if (kIsWeb) {
        if (file is XFile) {
          final bytes = await file.readAsBytes();
          uploadTask = ref.putData(
            bytes,
            SettableMetadata(contentType: 'image/jpeg'),
          );
        } else {
          throw Exception('Unsupported file type for web');
        }
      } else {
        if (file is File) {
          uploadTask = ref.putFile(file);
        } else if (file is XFile) {
          final bytes = await file.readAsBytes();
          uploadTask = ref.putData(bytes);
        } else {
          throw Exception('Unsupported file type');
        }
      }

      try {
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        return downloadUrl;
      } catch (e) {
        debugPrint('Error in upload: $e');
        rethrow;
      }
    } catch (e) {
      debugPrint('Error in uploadFile: $e');
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Deletes a file from Firebase Storage.
  /// Throws an exception if the deletion fails.
  static Future<void> deleteFile(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting file: $e');
      throw Exception('Failed to delete file: $e');
    }
  }
}
