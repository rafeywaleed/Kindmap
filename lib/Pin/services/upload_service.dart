import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class UploadService {
  static Future<String> uploadImage({
    required String imagePath,
    required bool isWeb,
  }) async {
    try {
      final path =
          'Images/${DateTime.now().millisecondsSinceEpoch}${isWeb ? '.png' : '.' + imagePath.split('.').last}';
      final storageRef = FirebaseStorage.instance.ref().child(path);
      late UploadTask uploadTask;

      if (isWeb) {
        // Web file upload
        final data = await File(imagePath).readAsBytes();
        uploadTask = storageRef.putData(data);
      } else {
        // Android file upload
        uploadTask = storageRef.putFile(File(imagePath));
      }

      final snapshot = await uploadTask.whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}
