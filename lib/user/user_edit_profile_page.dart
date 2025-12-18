import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserEditProfilePage extends StatefulWidget {
  final DocumentSnapshot<Map<String, dynamic>> userDoc;

  const UserEditProfilePage({super.key, required this.userDoc});

  @override
  State<UserEditProfilePage> createState() => _UserEditProfilePageState();
}

class _UserEditProfilePageState extends State<UserEditProfilePage> {
  late TextEditingController _nameCtrl;
  DateTime? _birthDate;
  String? _gender;
  Uint8List? _imageBytes;
  String _photoBase64 = "";
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final data = widget.userDoc.data()!;
    _nameCtrl = TextEditingController(text: data['name'] ?? '');
    _photoBase64 = data['photoBase64'] ?? '';
    _gender = data['gender'];

    if (data['birthDate'] is Timestamp) {
      _birthDate = (data['birthDate'] as Timestamp).toDate();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _show(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _pickImage() async {
    Uint8List? bytes;

    if (Theme.of(context).platform == TargetPlatform.android ||
        Theme.of(context).platform == TargetPlatform.iOS) {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;
      bytes = await picked.readAsBytes();
    } else {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null) return;
      bytes = result.files.first.bytes;
    }

    if (bytes == null) return;

    if (bytes.length > 2.5 * 1024 * 1024) {
      _show("Ukuran foto maksimal 2.5 MB");
      return;
    }

    setState(() => _imageBytes = bytes);
  }

  void _pickBirthDate() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        DateTime temp = _birthDate ?? DateTime(2004);
        return SizedBox(
          height: 260,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    setState(() => _birthDate = temp);
                    Navigator.pop(context);
                  },
                  child: const Text("Pilih"),
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: temp,
                  maximumDate: DateTime.now(),
                  onDateTimeChanged: (d) => temp = d,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty || _birthDate == null || _gender == null) {
      _show("Semua data wajib diisi");
      return;
    }

    setState(() => _saving = true);

    try {
      String finalBase64 = _photoBase64;
      if (_imageBytes != null) {
        finalBase64 = base64Encode(_imageBytes!);
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userDoc.id)
          .update({
            "name": _nameCtrl.text.trim(),
            "birthDate": Timestamp.fromDate(_birthDate!),
            "gender": _gender,
            "photoBase64": finalBase64,
          });

      if (!mounted) return;

      _show("Profil berhasil diubah", success: true);
      Navigator.pop(context);
    } catch (e) {
      _show("Gagal menyimpan profil");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profil")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: _imageBytes != null
                    ? MemoryImage(_imageBytes!)
                    : _photoBase64.isNotEmpty
                    ? MemoryImage(base64Decode(_photoBase64))
                    : null,
                child: (_imageBytes == null && _photoBase64.isEmpty)
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: "Nama",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            InkWell(
              onTap: _pickBirthDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: "Tanggal Lahir",
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _birthDate == null
                      ? "Pilih tanggal"
                      : "${_birthDate!.day}-${_birthDate!.month}-${_birthDate!.year}",
                ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                ChoiceChip(
                  label: const Text("Laki-laki"),
                  selected: _gender == "L",
                  onSelected: (_) => setState(() => _gender = "L"),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("Perempuan"),
                  selected: _gender == "P",
                  onSelected: (_) => setState(() => _gender = "P"),
                ),
              ],
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator()
                    : const Text("Simpan"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
