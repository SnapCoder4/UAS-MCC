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
    final String name = data['name'] ?? 'User';
    final String email = data['email'] ?? widget.user.email ?? '';
    final String photoBase64 = data['photoBase64'] ?? "";

    final pages = [
      _UserDashboard(name: name),
      const UserNewsPage(),
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
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text("Dashboard"),
              onTap: () => setState(() => _index = 0),
            ),
            ListTile(
              leading: const Icon(Icons.newspaper_outlined),
              title: const Text("News"),
              onTap: () => setState(() => _index = 1),
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text("Chat"),
              onTap: () => setState(() => _index = 2),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text("Settings"),
              onTap: () => setState(() => _index = 3),
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

class _UserDashboard extends StatelessWidget {
  final String name;
  const _UserDashboard({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Halo, $name 💪\nDashboard user di sini",
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
    if (birth != null) _birthDate = DateTime.tryParse(birth);
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
      if (_imageBytes != null) finalBase64 = base64Encode(_imageBytes!);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userDoc.id)
          .set({
            "name": _nameCtrl.text.trim(),
            "birthDate": _birthDate!.toIso8601String(),
            "gender": _gender,
            "photoBase64": finalBase64,
          }, SetOptions(merge: true));

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

class UserNewsPage extends StatelessWidget {
  const UserNewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('news')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final photoBase64 = data['photoBase64'] ?? "";
            final contentPreview = (data['content'] ?? "").length > 80
                ? "${(data['content'] ?? "").substring(0, 80)}..."
                : data['content'] ?? "";
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: photoBase64.isNotEmpty
                    ? Image.memory(
                        base64Decode(photoBase64),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      )
                    : null,
                title: Text(data['title'] ?? ""),
                subtitle: Text(contentPreview),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserNewsDetailPage(
                        title: data['title'] ?? "",
                        content: data['content'] ?? "",
                        photoBase64: photoBase64,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class UserNewsDetailPage extends StatelessWidget {
  final String title;
  final String content;
  final String photoBase64;

  const UserNewsDetailPage({
    super.key,
    required this.title,
    required this.content,
    required this.photoBase64,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Detail Berita")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (photoBase64.isNotEmpty)
              Image.memory(
                base64Decode(photoBase64),
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(content, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
