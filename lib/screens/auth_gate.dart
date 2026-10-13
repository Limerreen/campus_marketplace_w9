import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../repositories/favorites_repository.dart';
import '../repositories/item_repository.dart';
import '../repositories/listing_draft_repository.dart';
import '../screens/login_page.dart';
import '../screens/main_scaffold.dart';

class AuthGate extends StatelessWidget {
  final List<ItemRepository> itemRepositories;
  final FavoritesRepository favoritesRepository;
  final ListingDraftRepository draftRepository;

  const AuthGate({
    super.key,
    required this.itemRepositories,
    required this.favoritesRepository,
    required this.draftRepository,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // สถานะที่ 1: ยังรอผลจาก Stream รอบแรก (ตอนแอปเพิ่งเปิด)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // สถานะที่ 2: ยังไม่ล็อกอิน (data เป็น null)
        if (snapshot.data == null) {
          return const LoginPage();
        }

        // สถานะที่ 3: ล็อกอินแล้ว (มีข้อมูล User)
        return MainScaffold(
          itemRepositories: itemRepositories,
          favoritesRepository: favoritesRepository,
          draftRepository: draftRepository,
        );
      },
    );
  }
}
