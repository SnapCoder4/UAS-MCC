import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

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
    if (mounted) {
      setState(() => _adminDoc = snap);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    if (_adminDoc == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final data = _adminDoc!.data() ?? {};
    final name = data['name'] ?? 'Admin';
    final email = data['email'] ?? widget.user.email ?? '';
    final String photoBase64 = (data['photoBase64'] ?? "") as String;

    final pages = [
      _AdminDashboard(name: name),
      const _AdminChatPage(),
      _AdminSettingsPage(adminDoc: _adminDoc!),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Panel"),
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
    return const Center(child: Text("Halaman Chat Admin (placeholder)"));
  }
}

class _AdminSettingsPage extends StatefulWidget {
  final DocumentSnapshot<Map<String, dynamic>> adminDoc;
  const _AdminSettingsPage({super.key, required this.adminDoc});

  @override
  State<_AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<_AdminSettingsPage> {
  bool _saving = false;
  Uint8List? _imageBytes;
  File? _imageFile;
  late TextEditingController _nameCtrl;
  String _originalPhotoBase64 = "";

  @override
  void initState() {
    super.initState();
    final data = widget.adminDoc.data() ?? {};
    _nameCtrl = TextEditingController(text: data['name'] ?? '');

    _originalPhotoBase64 = (data['photoBase64'] ?? "") as String;
    if (_originalPhotoBase64.isNotEmpty) {
      _imageBytes = base64Decode(_originalPhotoBase64);
    }
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

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final String base64Image = _imageBytes != null
          ? base64Encode(_imageBytes!)
          : _originalPhotoBase64;

      await FirebaseFirestore.instance
          .collection('admins')
          .doc(widget.adminDoc.id)
          .update({"name": _nameCtrl.text.trim(), "photoBase64": base64Image});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Profil admin diupdate"),
          backgroundColor: Colors.green,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            "Pengaturan Admin",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 50,
            backgroundImage: _imageBytes != null
                ? MemoryImage(_imageBytes!)
                : null,
            child: _imageBytes == null
                ? const Icon(Icons.person, size: 40)
                : null,
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 16),
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
