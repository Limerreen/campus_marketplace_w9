import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../models/item.dart';
import '../repositories/item_repository_firestore.dart';
import '../repositories/listing_draft_repository.dart';

class MyDraftsPage extends StatefulWidget {
  final ListingDraftRepository repository;

  const MyDraftsPage({super.key, required this.repository});

  @override
  State<MyDraftsPage> createState() => _MyDraftsPageState();
}

class _MyDraftsPageState extends State<MyDraftsPage> {
  late Future<List<ListingDraftRow>> _draftsFuture;
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  void _loadDrafts() {
    _draftsFuture = widget.repository.getAllDrafts();
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;

    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute น.';
  }

  Future<void> _deleteDraft(ListingDraftRow draft) async {
    try {
      await widget.repository.deleteDraft(draft.id);

      if (!mounted) return;

      setState(() {
        _loadDrafts();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ลบร่าง "${draft.title}" แล้ว'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ไม่สามารถลบร่างได้: $e')));
    }
  }

  // ฟังก์ชันสำหรับ "โพสต์ขายจริง"
  Future<void> _publishDraft(ListingDraftRow draft) async {
    final priceController = TextEditingController();

    // 1. แสดง Dialog ถามราคาสินค้า
    final double? price = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ระบุราคาขายสำหรับ "${draft.title}"'),
        content: TextField(
          controller: priceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'ราคา (บาท)',
            hintText: 'เช่น 250.0',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              final parsed = double.tryParse(priceController.text);
              if (parsed != null && parsed > 0) {
                Navigator.pop(context, parsed);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('กรุณากรอกราคาเป็นตัวเลขที่มากกว่า 0'),
                  ),
                );
              }
            },
            child: const Text('ยืนยันโพสต์'),
          ),
        ],
      ),
    );

    if (price == null) return; // ถ้ายกเลิก

    setState(() => _isPublishing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('ไม่พบข้อมูลการเข้าสู่ระบบ');

      // 2. กำหนด URL รูปภาพ (ใช้ URL รูปตัวอย่างเพื่อข้าม Firebase Storage)
      String imageUrl = 'https://picsum.photos/200';

      // 3. สร้าง Item และเขียนลง Firestore
      final newItem = Item(
        id: '',
        title: draft.title,
        price: price,
        description: draft.description ?? '',
        category: draft.category ?? '',
        imageUrl: imageUrl,
        sellerId: user.uid,
      );

      await ItemRepositoryFirestore().postItem(newItem);

      // 4. ลบร่างออกจาก Local Database (Drift)
      await widget.repository.deleteDraft(draft.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('โพสต์ "${draft.title}" ขายจริงเรียบร้อยแล้ว!'),
          ),
        );
        setState(() {
          _loadDrafts(); // Refresh รายการร่าง
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text('ร่างประกาศของฉัน')),
          body: FutureBuilder<List<ListingDraftRow>>(
            future: _draftsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'เกิดข้อผิดพลาด: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final drafts = snapshot.data ?? [];

              if (drafts.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'ยังไม่มีร่างประกาศ',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'ร่างประกาศที่บันทึกไว้จะแสดงที่นี่',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: drafts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final draft = drafts[index];

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              child: Icon(Icons.description_outlined),
                            ),
                            title: Text(
                              draft.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('หมวดหมู่: ${draft.category ?? "-"}'),
                                  const SizedBox(height: 4),
                                  Text(
                                    'แก้ไขล่าสุด: ${_formatDateTime(draft.updatedAt)}',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.cloud_upload, size: 18),
                                label: const Text('โพสต์จริง'),
                                onPressed: () => _publishDraft(draft),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                tooltip: 'ลบร่าง',
                                onPressed: () => _deleteDraft(draft),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        if (_isPublishing)
          Container(
            color: Colors.black45,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'กำลังโพสต์สินค้าลง Firestore...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
