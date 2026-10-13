import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item.dart';
import 'item_repository.dart';

class ItemRepositoryFirestore implements ItemRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // อ่านเอกสารทั้งหมดใน Collection 'items' ครั้งเดียว
  @override
  Future<List<Item>> getItems() async {
    final snapshot = await _firestore.collection('items').get();
    return snapshot.docs.map((doc) => Item.fromFirestore(doc)).toList();
  }

  // เขียนเอกสารใหม่ลง Collection 'items'
  Future<void> postItem(Item item) async {
    await _firestore.collection('items').add(item.toFirestore());
  }

  // ฟังการเปลี่ยนแปลงเอกสารที่ sellerId ตรงกันแบบ Real-time
  Stream<List<Item>> watchMyListings(String sellerId) {
    return _firestore
        .collection('items')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Item.fromFirestore(doc)).toList(),
        );
  }
}
