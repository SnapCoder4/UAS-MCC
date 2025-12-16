import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // <-- Storage
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  DateTime? _birthDate;
  String? _gender; // "L" / "P"

  bool _loading = false;
  String? _errorMsg;

  Uint8List? imageBytes; // dipakai upload ke Storage
  File? imageFile; // hanya kepakai di Android/iOS buat preview

  final _formKey = GlobalKey<FormState>();

  // untuk icon show / hide password
  bool _showPass = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }

  // pilih foto: mobile pakai image_picker, web pakai file_picker
  Future<void> _pickImage() async {
    try {
      if (Theme.of(context).platform == TargetPlatform.android ||
          Theme.of(context).platform == TargetPlatform.iOS) {
        final picker = ImagePicker();
        final XFile? picked = await picker.pickImage(
          source: ImageSource.gallery,
        );
        if (picked != null) {
          imageFile = File(picked.path);
          imageBytes = await picked.readAsBytes();
          setState(() {});
        }
      } else {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: true,
        );
        if (result != null) {
          imageBytes = result.files.first.bytes;
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _pickBirthDate() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        DateTime temp = _birthDate ?? DateTime(2004, 1, 1);
        return Container(
          height: 250,
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() => _birthDate = temp);
                      Navigator.pop(context);
                    },
                    child: const Text("Pilih"),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: temp,
                  maximumDate: DateTime.now(),
                  onDateTimeChanged: (d) {
                    temp = d;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_birthDate == null) {
      setState(() => _errorMsg = "Tanggal lahir wajib dipilih");
      return;
    }
    if (_gender == null) {
      setState(() => _errorMsg = "Jenis kelamin wajib dipilih");
      return;
    }

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      // 1. buat akun di Firebase Auth
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );

      final uid = cred.user!.uid;

      // 2. upload foto ke Firebase Storage (kalau user pilih foto)
      String photoUrl = "";
      if (imageBytes != null) {
        // batasi ukuran, misal maksimal 2 MB
        if (imageBytes!.lengthInBytes > 2 * 1024 * 1024) {
          setState(() {
            _loading = false;
            _errorMsg = "Ukuran foto terlalu besar (maksimal 2 MB).";
          });
          return;
        }

        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_photos')
            .child('$uid.jpg');

        await ref.putData(
          imageBytes!,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        photoUrl = await ref.getDownloadURL();
      }

      // 3. simpan profil di Firestore
      //    NOTE: nama field masih "photoBase64" supaya kompatibel
      //    tapi isinya SEKARANG URL foto, bukan string base64 lagi.
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        "email": emailCtrl.text.trim(),
        "name": nameCtrl.text.trim(),
        "gender": _gender,
        "birthDate": _birthDate!.toIso8601String(),
        "photoBase64": photoUrl, // <--- sekarang berisi URL, aman & kecil
        "role": "user",
        "createdAt": Timestamp.now(),
      });

      if (!mounted) return;

      // 4. logout dulu lalu kembali ke login
      await FirebaseAuth.instance.signOut();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Akun berhasil dibuat"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(12),
        ),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      debugPrint("FirebaseAuthException: ${e.code} - ${e.message}");

      String msg = "Registrasi gagal.";

      if (e.code == 'email-already-in-use') {
        msg = "Email sudah terdaftar, silakan login.";
      } else if (e.code == 'invalid-email') {
        msg = "Format email tidak valid.";
      } else if (e.code == 'weak-password') {
        msg = "Password terlalu lemah (minimal 6 karakter).";
      } else {
        msg = e.message ?? "Terjadi kesalahan saat registrasi.";
      }

      setState(() => _errorMsg = msg);
    } catch (e, st) {
      debugPrint("Error register: $e");
      debugPrintStack(stackTrace: st);
      setState(() => _errorMsg = "Terjadi kesalahan, coba lagi.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final blue = const Color(0xFF2563EB);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Registrasi"),
        backgroundColor: blue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (_errorMsg != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMsg!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Foto
                    Center(
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(60),
                            child: Container(
                              width: 120,
                              height: 120,
                              color: Colors.grey[200],
                              child: imageBytes != null
                                  ? Image.memory(imageBytes!, fit: BoxFit.cover)
                                  : imageFile != null
                                  ? Image.file(imageFile!, fit: BoxFit.cover)
                                  : const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.grey,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image),
                            label: const Text("Pilih Foto"),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: "Nama",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Nama wajib diisi" : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: emailCtrl,
                      decoration: InputDecoration(
                        labelText: "Email",
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Email wajib diisi" : null,
                    ),
                    const SizedBox(height: 12),

                    // tanggal lahir
                    InkWell(
                      onTap: _pickBirthDate,
                      borderRadius: BorderRadius.circular(16),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: "Tanggal Lahir",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _birthDate == null
                                  ? "Pilih tanggal, bulan, tahun"
                                  : "${_birthDate!.day.toString().padLeft(2, '0')}-"
                                        "${_birthDate!.month.toString().padLeft(2, '0')}-"
                                        "${_birthDate!.year}",
                            ),
                            const Icon(Icons.calendar_month_outlined),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // gender
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Jenis Kelamin",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text("Laki-laki"),
                          selected: _gender == "L",
                          shape: const StadiumBorder(),
                          onSelected: (_) => setState(() => _gender = "L"),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text("Perempuan"),
                          selected: _gender == "P",
                          shape: const StadiumBorder(),
                          onSelected: (_) => setState(() => _gender = "P"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: passCtrl,
                      obscureText: !_showPass,
                      decoration: InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPass
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _showPass = !_showPass),
                        ),
                      ),
                      validator: (v) => v == null || v.length < 6
                          ? "Minimal 6 karakter"
                          : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: confirmCtrl,
                      obscureText: !_showConfirm,
                      decoration: InputDecoration(
                        labelText: "Konfirmasi Password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _showConfirm = !_showConfirm),
                        ),
                      ),
                      validator: (v) =>
                          v != passCtrl.text ? "Password tidak sama" : null,
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: blue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Buat Akun",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
