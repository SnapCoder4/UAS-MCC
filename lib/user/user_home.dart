import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    if (mounted) setState(() => _userDoc = snap);
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
    final photoBase64 = data['photoBase64'] ?? "";

    final pages = [
      _UserDashboard(name: name),
      const _UserChatPage(),
      _UserSettingsPage(userDoc: _userDoc!, onProfileUpdated: _loadUser),
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
                backgroundImage: photoBase64.isNotEmpty
                    ? MemoryImage(base64Decode(photoBase64))
                    : null,
                child: photoBase64.isEmpty
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
        "Halo, $name 💪\nNanti isi fitur user di sini",
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _UserChatPage extends StatelessWidget {
  const _UserChatPage();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Halaman Chat User"));
  }
}

class _UserSettingsPage extends StatefulWidget {
  final DocumentSnapshot<Map<String, dynamic>> userDoc;
  final Future<void> Function()? onProfileUpdated;

  const _UserSettingsPage({required this.userDoc, this.onProfileUpdated});

  @override
  State<_UserSettingsPage> createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<_UserSettingsPage> {
  bool _saving = false;

  late TextEditingController _nameCtrl;
  DateTime? _birthDate;
  String? _gender;

  Uint8List? _imageBytes;
  String _photoBase64 = "";

  @override
  void initState() {
    super.initState();
    final data = widget.userDoc.data() ?? {};
    _nameCtrl = TextEditingController(text: data['name'] ?? '');
    _gender = data['gender'];
    _photoBase64 = data['photoBase64'] ?? "";

    final birth = data['birthDate'];
    if (birth != null) {
      _birthDate = DateTime.tryParse(birth);
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
        DateTime temp = _birthDate ?? DateTime(2004, 1, 1);
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
      ).showSnackBar(const SnackBar(content: Text("Data wajib diisi")));
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
            "birthDate": _birthDate!.toIso8601String(),
            "gender": _gender,
            "photoBase64": finalBase64,
          });

      _photoBase64 = finalBase64;
      await widget.onProfileUpdated?.call();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Profil berhasil diupdate")));
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
