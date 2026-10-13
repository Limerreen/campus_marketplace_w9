import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/item.dart';
import 'item_repository.dart';

class ItemRepositoryApi implements ItemRepository {
  static const _baseUrl = 'https://fakestoreapi.com/products';

  @override
  Future<List<Item>> getItems() async {
    final uri = Uri.parse(_baseUrl);

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        return data
            .map((e) => Item.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      throw Exception(
        'ไม่สามารถโหลดรายการสินค้าได้ (สถานะ ${response.statusCode})',
      );
    } on TimeoutException {
      return _mockItems;
    } on http.ClientException {
      return _mockItems;
    } catch (e) {
      return _mockItems;
    }
  }

  // สินค้าสำรอง กรณี Fake Store API ใช้งานไม่ได้
  static const List<Item> _mockItems = [
    Item(
      id: '101',
      title: 'เสื้อยืด Campus',
      price: 199.0,
      description: 'เสื้อยืดสำหรับนักศึกษา',
      category: 'เสื้อผ้า',
      imageUrl: 'https://via.placeholder.com/150',
    ),
    Item(
      id: '102',
      title: 'กระเป๋าสะพาย',
      price: 299.0,
      description: 'กระเป๋าสำหรับใช้งานทั่วไป',
      category: 'เครื่องแต่งกาย',
      imageUrl: 'https://via.placeholder.com/150',
    ),
    Item(
      id: '103',
      title: 'หูฟังไร้สาย',
      price: 599.0,
      description: 'หูฟัง Bluetooth',
      category: 'อิเล็กทรอนิกส์',
      imageUrl: 'https://via.placeholder.com/150',
    ),
  ];
}
