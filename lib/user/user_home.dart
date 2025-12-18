import 'dart:convert';
import 'user_chat_page.dart';
import 'user_settings_page.dart';
import 'user_membership_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
    if (_userDoc == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final data = _userDoc!.data() ?? {};
    final name = data['name'] ?? 'User';
    final email = data['email'] ?? widget.user.email ?? '';
    final photoBase64 = data['photoBase64'] ?? "";

    final pages = [
      _UserDashboard(
        name: name,
        userId: widget.user.uid,
        onNavigate: (i) => setState(() => _index = i),
      ),
      const UserNewsPage(),
      const UserMembershipPage(),
      const UserChatPage(),
      UserSettingsPage(userDoc: _userDoc!, onUpdated: _loadUser),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gym App"),
        actions: [
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
            _drawerItem(0, "Dashboard", Icons.dashboard_outlined),
            _drawerItem(1, "Berita", Icons.newspaper_outlined),
            _drawerItem(2, "Membership", Icons.card_membership),
            _drawerItem(3, "Chat", Icons.chat_bubble_outline),
            _drawerItem(4, "Pengaturan", Icons.settings_outlined),
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
            icon: Icon(Icons.card_membership),
            label: "Membership",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: "Chat",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: "Pengaturan",
          ),
        ],
      ),
    );
  }

  ListTile _drawerItem(int i, String title, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        setState(() => _index = i);
      },
    );
  }
}

class _UserDashboard extends StatelessWidget {
  final String name;
  final String userId;
  final void Function(int index) onNavigate;

  const _UserDashboard({
    required this.name,
    required this.userId,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('user_memberships')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        String membershipType = "Belum ada";
        String membershipStatus = "Tidak aktif";
        Color statusColor = Colors.grey;
        DateTime? expiryDate;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data()!;
          membershipType = data['packageName'] ?? "Belum ada";
          final expiry = data['expiryDate'] as Timestamp?;
          if (expiry != null) {
            expiryDate = expiry.toDate();
            final daysLeft = expiryDate.difference(DateTime.now()).inDays;
            if (daysLeft < 0) {
              membershipStatus = "Kadaluarsa";
              statusColor = Colors.red;
            } else if (daysLeft <= 7) {
              membershipStatus = "Aktif (segera berakhir)";
              statusColor = Colors.orange;
            } else {
              membershipStatus = "Aktif";
              statusColor = Colors.green;
            }
          }
        }

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
                      colors: [Colors.blue[700]!, Colors.blue[900]!],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Selamat Datang! 💪",
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
              const SizedBox(height: 20),
              const Text(
                "Status Membership",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        membershipType,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        membershipStatus,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (expiryDate != null) ...[
                        const Divider(),
                        Text(
                          "Berlaku hingga: ${expiryDate.day}-${expiryDate.month}-${expiryDate.year}",
                        ),
                      ],
                      if (membershipType == "Belum ada") ...[
                        const Divider(),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => onNavigate(2),
                            icon: const Icon(Icons.add_card),
                            label: const Text("Beli Membership"),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final photoBase64 = data['photoBase64'] ?? "";
            final content = data['content'] ?? "";
            final preview = content.length > 80
                ? "${content.substring(0, 80)}..."
                : content;

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
                subtitle: Text(preview),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserNewsDetailPage(
                        title: data['title'] ?? "",
                        content: content,
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
