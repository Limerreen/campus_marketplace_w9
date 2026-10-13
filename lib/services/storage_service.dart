import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadListingImage(File imageFile, String sellerId) async {
    // สร้างชื่อไฟล์ที่ไม่ซ้ำกันโดยใช้ timestamp
    final fileName = '${sellerId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('listings').child(fileName);

    // อัปโหลดไฟล์ขึ้น Storage
    final uploadTask = await ref.putFile(imageFile);

    // ดึง Download URL หลังอัปโหลดเสร็จสมบูรณ์
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    return downloadUrl;
  }
}
