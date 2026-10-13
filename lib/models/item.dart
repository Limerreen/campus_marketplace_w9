import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final String id;
  final String title;
  final double price;
  final String description;
  final String category;
  final String imageUrl;
  final String? sellerId; // 👈 เพิ่ม field sellerId (nullable)

  const Item({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.imageUrl,
    this.sellerId,
  });

  // สำหรับแปลงข้อมูลจาก API (Fake Store API)
  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      imageUrl: json['image'] as String? ?? '',
      sellerId: null,
    );
  }

  // สำหรับแปลงข้อมูลจาก Firebase Firestore
  factory Item.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Item(
      id: doc.id,
      title: data['title'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      sellerId: data['sellerId'] as String?,
    );
  }

  // สำหรับส่งข้อมูลขึ้น Firebase Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'price': price,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'sellerId': sellerId,
    };
  }
}
