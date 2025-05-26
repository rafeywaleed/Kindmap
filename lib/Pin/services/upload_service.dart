import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class UploadService {
  static Future<String> uploadImage({
    required String imagePath,
  }) async {
    try {
      final path =
          'Images/${DateTime.now().millisecondsSinceEpoch}.${imagePath.split('.').last}';
      final storageRef = FirebaseStorage.instance.ref().child(path);

      // Android file upload only
      final uploadTask = storageRef.putFile(File(imagePath));

      final snapshot = await uploadTask.whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}
