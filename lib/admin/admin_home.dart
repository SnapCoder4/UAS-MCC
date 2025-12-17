import 'dart:convert';
import 'dart:typed_data';
import 'admin_news_page.dart';
import 'admin_members_page.dart';
import 'admin_membership_packages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
      const AdminMembershipPackagesPage(),
      const AdminMembersPage(),
      const _AdminChatPage(),
      _AdminSettingsPage(adminDoc: _adminDoc!, onUpdated: _loadAdmin),
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
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text("Dashboard"),
              onTap: () {
                Navigator.pop(context);
                setState(() => _index = 0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.newspaper_outlined),
              title: const Text("Kelola Berita"),
              onTap: () {
                Navigator.pop(context);
                setState(() => _index = 1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text("Kelola Paket"),
              onTap: () {
                Navigator.pop(context);
                setState(() => _index = 2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text("Kelola Member"),
              onTap: () {
                Navigator.pop(context);
                setState(() => _index = 3);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text("Chat"),
              onTap: () {
                Navigator.pop(context);
                setState(() => _index = 4);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text("Pengaturan"),
              onTap: () {
                Navigator.pop(context);
                setState(() => _index = 5);
              },
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
            label: "Berita",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: "Paket",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "Member"),
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
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('user_memberships')
          .snapshots(),
      builder: (context, memberSnapshot) {
        int totalMembers = 0;
        int activeMembers = 0;
        int silverCount = 0;
        int goldCount = 0;
        int platinumCount = 0;

        if (memberSnapshot.hasData) {
          totalMembers = memberSnapshot.data!.docs.length;
          for (var doc in memberSnapshot.data!.docs) {
            final data = doc.data();
            final expiryDate = (data['expiryDate'] as Timestamp).toDate();
            if (DateTime.now().isBefore(expiryDate)) {
              activeMembers++;
            }
            final packageName = (data['packageName'] as String? ?? '')
                .toLowerCase();
            if (packageName.contains('silver')) silverCount++;
            if (packageName.contains('gold')) goldCount++;
            if (packageName.contains('platinum')) platinumCount++;
          }
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('news').snapshots(),
          builder: (context, newsSnapshot) {
            int totalNews = newsSnapshot.hasData
                ? newsSnapshot.data!.docs.length
                : 0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            Colors.deepPurple[700]!,
                            Colors.deepPurple[900]!,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Selamat Datang Admin! 👑",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Statistik Gym",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: "Total Member",
                          value: totalMembers.toString(),
                          icon: Icons.group,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: "Member Aktif",
                          value: activeMembers.toString(),
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: "Silver",
                          value: silverCount.toString(),
                          icon: Icons.star_border,
                          color: Colors.grey[700]!,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          title: "Gold",
                          value: goldCount.toString(),
                          icon: Icons.star_half,
                          color: Colors.amber[700]!,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          title: "Platinum",
                          value: platinumCount.toString(),
                          icon: Icons.star,
                          color: Colors.purple[700]!,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    title: "Total Berita",
                    value: totalNews.toString(),
                    icon: Icons.newspaper,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Akses Cepat",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAccessCard(
                          title: "Kelola Berita",
                          icon: Icons.newspaper,
                          color: Colors.orange,
                          onTap: () {
                            final adminState = context
                                .findAncestorStateOfType<_AdminHomeState>();
                            if (adminState != null) {
                              adminState.setState(() {
                                adminState._index = 1;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAccessCard(
                          title: "Kelola Paket",
                          icon: Icons.inventory_2,
                          color: Colors.purple,
                          onTap: () {
                            final adminState = context
                                .findAncestorStateOfType<_AdminHomeState>();
                            if (adminState != null) {
                              adminState.setState(() {
                                adminState._index = 2;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAccessCard(
                          title: "Kelola Member",
                          icon: Icons.group,
                          color: Colors.blue,
                          onTap: () {
                            final adminState = context
                                .findAncestorStateOfType<_AdminHomeState>();
                            if (adminState != null) {
                              adminState.setState(() {
                                adminState._index = 3;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
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
