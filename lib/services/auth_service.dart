// lib/services/auth_service.dart
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// stream perubahan status login (kalau mau dipakai di tempat lain)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// REGISTER USER BARU + upload foto ke Firebase Storage + simpan profil di Firestore
  ///
  /// return:
  ///   - `null`  -> sukses
  ///   - `String` -> pesan error untuk ditampilkan ke user
  Future<String?> registerUser(
    String name,
    String email,
    String password,
    Uint8List? photoBytes,
  ) async {
    try {
      // 1. Buat akun di Firebase Auth
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;

      // 2. Upload foto ke Storage (kalau ada)
      String photoUrl = "";
      if (photoBytes != null) {
        // batasi ukuran, misal maksimal 2 MB
        if (photoBytes.lengthInBytes > 2 * 1024 * 1024) {
          return "Ukuran foto terlalu besar (maksimal 2 MB).";
        }

        final ref = _storage.ref().child('profile_photos').child('$uid.jpg');

        await ref.putData(
          photoBytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        photoUrl = await ref.getDownloadURL();
      }

      // 3. Simpan data user di Firestore (koleksi `users`)
      await _db.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'photoUrl': photoUrl, // URL dari Firebase Storage
        'role': 'user', // biar cocok sama AuthGate-mu
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null; // sukses
    } on FirebaseAuthException catch (e) {
      // error spesifik dari Firebase Auth
      if (e.code == 'email-already-in-use') {
        return "Email sudah terdaftar, silakan login.";
      } else if (e.code == 'invalid-email') {
        return "Format email tidak valid.";
      } else if (e.code == 'weak-password') {
        return "Password terlalu lemah (minimal 6 karakter).";
      }

      return e.message ?? "Terjadi kesalahan saat registrasi.";
    } catch (e, st) {
      debugPrint("Register error: $e");
      debugPrintStack(stackTrace: st);
      return "Terjadi kesalahan, coba lagi.";
    }
  }

  /// LOGIN
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // sukses
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return "Akun tidak ditemukan.";
      } else if (e.code == 'wrong-password') {
        return "Password salah.";
      }
      return e.message ?? "Gagal login.";
    } catch (e) {
      debugPrint("Login error: $e");
      return "Terjadi kesalahan, coba lagi.";
    }
  }

  /// LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }
}
