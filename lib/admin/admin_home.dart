import 'dart:convert';
import 'dart:typed_data';
import 'admin_news_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminHome extends StatefulWidget {
  final User user;
  const AdminHome({super.key, required this.user});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _index = 0;
  DocumentSnapshot<Map<String, dynamic>>? _adminDoc;

  @override
  void initState() {
    super.initState();
    _loadAdmin();
  }

  Future<void> _loadAdmin() async {
    final snap = await FirebaseFirestore.instance
        .collection('admins')
        .doc(widget.user.uid)
        .get();
    if (mounted) setState(() => _adminDoc = snap);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    if (_adminDoc == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final data = _adminDoc!.data() ?? {};
    final String name = data['name'] ?? 'Admin';
    final String email = data['email'] ?? widget.user.email ?? '';
    final String photoBase64 = data['photoBase64'] ?? "";

    final pages = [
      _AdminDashboard(name: name),
      const AdminNewsPage(),
      const _AdminChatPage(),
      _AdminSettingsPage(adminDoc: _adminDoc!, onUpdated: _loadAdmin),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin"),
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
                backgroundImage: photoBase64.isNotEmpty
                    ? MemoryImage(base64Decode(photoBase64))
                    : null,
                child: photoBase64.isEmpty
                    ? const Icon(Icons.person, size: 32)
                    : null,
              ),
            ),
            const ListTile(
              leading: Icon(Icons.admin_panel_settings),
              title: Text("Menu admin lain (nanti diisi)"),
            ),
          ],
        ),
      ),
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.newspaper_outlined),
            label: "News",
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

class _AdminDashboard extends StatelessWidget {
  final String name;
  const _AdminDashboard({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Halo, Admin $name 👑\nNanti isi fitur admin di sini",
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _AdminChatPage extends StatelessWidget {
  const _AdminChatPage();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Halaman Chat Admin"));
  }
}

class _AdminSettingsPage extends StatefulWidget {
  final DocumentSnapshot<Map<String, dynamic>> adminDoc;
  final Future<void> Function()? onUpdated;

  const _AdminSettingsPage({required this.adminDoc, this.onUpdated});

  @override
  State<_AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<_AdminSettingsPage> {
  bool _saving = false;

  late TextEditingController _nameCtrl;
  DateTime? _birthDate;
  String? _gender;
  Uint8List? _imageBytes;
  String _photoBase64 = "";

  @override
  void initState() {
    super.initState();
    final data = widget.adminDoc.data() ?? {};
    _nameCtrl = TextEditingController(text: data['name'] ?? '');
    _photoBase64 = data['photoBase64'] ?? "";
    _gender = data['gender'];

    final birth = data['birthDate'];
    if (birth != null) {
      if (birth is Timestamp) {
        _birthDate = birth.toDate();
      } else if (birth is String) {
        _birthDate = DateTime.tryParse(birth);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
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
    if (bytes.lengthInBytes > 2.5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ukuran foto maksimal 2.5 MB")),
      );
      return;
    }
    setState(() => _imageBytes = bytes);
  }

  void _pickBirthDate() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        DateTime temp = _birthDate ?? DateTime(1980, 1, 1);
        return SizedBox(
          height: 250,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Semua data wajib diisi")));
      return;
    }

    setState(() => _saving = true);

    try {
      String finalBase64 = _photoBase64;
      if (_imageBytes != null) finalBase64 = base64Encode(_imageBytes!);

      await FirebaseFirestore.instance
          .collection('admins')
          .doc(widget.adminDoc.id)
          .set({
            "name": _nameCtrl.text.trim(),
            "birthDate": Timestamp.fromDate(_birthDate!),
            "gender": _gender,
            "photoBase64": finalBase64,
          }, SetOptions(merge: true));

      _photoBase64 = finalBase64;
      await widget.onUpdated?.call();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil admin berhasil diupdate")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: SizedBox(
              width: 120,
              height: 120,
              child: _imageBytes != null
                  ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                  : _photoBase64.isNotEmpty
                  ? Image.memory(base64Decode(_photoBase64), fit: BoxFit.cover)
                  : const Icon(Icons.person, size: 60),
            ),
          ),
          TextButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.image),
            label: const Text("Ubah Foto"),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: "Nama Admin",
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
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const CircularProgressIndicator()
                  : const Text("Simpan Perubahan"),
            ),
          ),
        ],
      ),
    );
  }
}
