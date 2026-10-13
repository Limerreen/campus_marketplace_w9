import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _googleInitialized = false;

  Future<void> _initializeGoogleSignIn() async {
    if (_googleInitialized) return;
    // บน Android จะดึง Web Client ID จาก google-services.json โดยอัตโนมัติ
    await _googleSignIn.initialize();
    _googleInitialized = true;
  }

  // ดึงผู้ใช้ปัจจุบัน
  User? get currentUser => _firebaseAuth.currentUser;

  // Stream สถานะล็อกอิน
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // สมัครสมาชิกด้วย Email/Password (แมปชื่อ signUp ให้ตรงกับ LoginPage)
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // เข้าสู่ระบบด้วย Email/Password (แมปชื่อ signIn ให้ตรงกับ LoginPage)
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // เข้าสู่ระบบด้วย Google (รองรับ google_sign_in v7.x)
  Future<UserCredential> signInWithGoogle() async {
    await _initializeGoogleSignIn();

    final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    final String? idToken = googleAuth.idToken;

    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'missing-google-id-token',
        message: 'ไม่สามารถรับ ID Token จาก Google ได้',
      );
    }

    final OAuthCredential credential = GoogleAuthProvider.credential(
      idToken: idToken,
    );

    return await _firebaseAuth.signInWithCredential(credential);
  }

  // ออกจากระบบ
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}
