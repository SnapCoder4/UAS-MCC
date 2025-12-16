import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

class UserHome extends StatefulWidget {
  final User user;
  const UserHome({super.key, required this.user});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  int _index = 0;
  DocumentSnapshot<Map<String, dynamic>>? _userDoc;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .get();
    if (mounted) {
      setState(() => _userDoc = snap);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    if (_userDoc == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final data = _userDoc!.data() ?? {};
    final name = data['name'] ?? 'User';
    final email = data['email'] ?? widget.user.email ?? '';
    final photoUrl = data['photoBase64'] ?? ""; // sekarang isinya URL Storage

    final pages = [
      _UserDashboard(name: name),
      const _UserChatPage(),
      _UserSettingsPage(
        userDoc: _userDoc!,
        onProfileUpdated: _loadUser, // biar header ikut update
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gym App"),
        actions: [
          Switch(value: theme.isDarkMode, onChanged: theme.toggleTheme),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(name),
              accountEmail: Text(email),
              currentAccountPicture: CircleAvatar(
                backgroundImage: photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl.isEmpty
                    ? const Icon(Icons.person, size: 32)
                    : null,
              ),
            ),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text("Menu user lain (nanti diisi)"),
            ),
          ],
        ),
      ),
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: "Chat",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: "Setting",
          ),
        ],
      ),
    );
  }
}

class _UserDashboard extends StatelessWidget {
  final String name;
  const _UserDashboard({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Halo, $name 💪\nNanti isi fitur user (jadwal gym, membership, dsb) di sini",
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}

class _UserChatPage extends StatelessWidget {
  const _UserChatPage();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Halaman Chat User (placeholder)"));
  }
}

class _UserSettingsPage extends StatefulWidget {
  final DocumentSnapshot<Map<String, dynamic>> userDoc;
  final Future<void> Function()? onProfileUpdated;

  const _UserSettingsPage({
    super.key,
    required this.userDoc,
    this.onProfileUpdated,
  });

  @override
  State<_UserSettingsPage> createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<_UserSettingsPage> {
  bool _saving = false;

  late TextEditingController _nameCtrl;
  DateTime? _birthDate;
  String? _gender; // "L" / "P"

  Uint8List? _imageBytes; // untuk foto baru
  File? _imageFile; // preview di mobile
  String _photoUrl = ""; // URL foto lama / terbaru

  @override
  void initState() {
    super.initState();
    final data = widget.userDoc.data() ?? {};

    _nameCtrl = TextEditingController(text: data['name'] ?? '');

    final birthStr = data['birthDate'] as String?;
    if (birthStr != null && birthStr.isNotEmpty) {
      _birthDate = DateTime.tryParse(birthStr);
    }

    _gender = data['gender'] as String?;
    _photoUrl = data['photoBase64'] ?? ""; // URL dari Firestore
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      if (Theme.of(context).platform == TargetPlatform.android ||
          Theme.of(context).platform == TargetPlatform.iOS) {
        final picker = ImagePicker();
        final XFile? picked = await picker.pickImage(
          source: ImageSource.gallery,
        );
        if (picked != null) {
          _imageFile = File(picked.path);
          _imageBytes = await picked.readAsBytes();
          setState(() {});
        }
      } else {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: true,
        );
        if (result != null) {
          _imageBytes = result.files.first.bytes;
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

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Nama tidak boleh kosong")));
      return;
    }
    if (_birthDate == null || _gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tanggal lahir & jenis kelamin wajib diisi"),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      String photoUrl = _photoUrl;

      // Kalau user pilih foto baru, upload ke Storage
      if (_imageBytes != null) {
        final uid = widget.userDoc.id;
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_photos')
            .child('$uid.jpg');

        await ref.putData(
          _imageBytes!,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        photoUrl = await ref.getDownloadURL();
      }

      // Update Firestore (masih pakai field "photoBase64", tapi isi URL)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userDoc.id)
          .update({
            "name": _nameCtrl.text.trim(),
            "birthDate": _birthDate!.toIso8601String(),
            "gender": _gender,
            "photoBase64": photoUrl,
          });

      _photoUrl = photoUrl;

      if (widget.onProfileUpdated != null) {
        await widget.onProfileUpdated!();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profil berhasil diupdate"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(12),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal update profil: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text("Pengaturan Akun", style: titleStyle),
          const SizedBox(height: 16),

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
                    child: _imageBytes != null
                        ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                        : _photoUrl.isNotEmpty
                        ? Image.network(_photoUrl, fit: BoxFit.cover)
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
                  label: const Text("Ubah Foto"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Nama
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: "Nama",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // Tanggal lahir
          InkWell(
            onTap: _pickBirthDate,
            borderRadius: BorderRadius.circular(16),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: "Tanggal Lahir",
                border: OutlineInputBorder(),
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

          // Gender
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
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Simpan Perubahan"),
            ),
          ),
        ],
      ),
    );
  }
}
