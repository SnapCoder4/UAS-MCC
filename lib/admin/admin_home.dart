import 'dart:convert';
import 'admin_news_page.dart';
import 'admin_members_page.dart';
import 'admin_settings_page.dart';
import 'admin_chat_list_page.dart';
import 'package:flutter/material.dart';
import 'admin_membership_packages.dart';
import 'package:flutter/cupertino.dart';
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
    if (_adminDoc == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final data = _adminDoc!.data() ?? {};
    final name = data['name'] ?? 'Admin';
    final email = data['email'] ?? widget.user.email ?? '';
    final photoBase64 = data['photoBase64'] ?? "";

    final pages = [
      _AdminDashboard(
        name: name,
        onNavigate: (i) => setState(() => _index = i),
      ),
      const AdminNewsPage(),
      const AdminMembershipPackagesPage(),
      const AdminMembersPage(),
      const AdminChatListPage(),
      AdminSettingsPage(adminDoc: _adminDoc!, onProfileUpdated: _loadAdmin),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Panel"),
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
            _drawerItem(1, "Kelola Berita", Icons.newspaper_outlined),
            _drawerItem(2, "Kelola Paket", Icons.inventory_2),
            _drawerItem(3, "Kelola Member", Icons.group),
            _drawerItem(4, "Chat", Icons.chat_bubble_outline),
            _drawerItem(5, "Pengaturan", Icons.settings_outlined),
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

class _AdminDashboard extends StatelessWidget {
  final String name;
  final void Function(int index) onNavigate;

  const _AdminDashboard({required this.name, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('user_memberships')
          .snapshots(),
      builder: (context, memberSnapshot) {
        int totalMembers = 0;
        int activeMembers = 0;
        int silver = 0, gold = 0, platinum = 0;

        if (memberSnapshot.hasData) {
          for (var d in memberSnapshot.data!.docs) {
            totalMembers++;
            final data = d.data();
            final expiry = (data['expiryDate'] as Timestamp).toDate();
            if (DateTime.now().isBefore(expiry)) activeMembers++;

            final pkg = (data['packageName'] ?? '').toString().toLowerCase();
            if (pkg.contains('silver')) silver++;
            if (pkg.contains('gold')) gold++;
            if (pkg.contains('platinum')) platinum++;
          }
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('news').snapshots(),
          builder: (context, newsSnap) {
            final totalNews = newsSnap.hasData ? newsSnap.data!.docs.length : 0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Selamat Datang Admin 👑",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(name),

                  const SizedBox(height: 16),

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
                          value: silver.toString(),
                          icon: Icons.star_border,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          title: "Gold",
                          value: gold.toString(),
                          icon: Icons.star_half,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          title: "Platinum",
                          value: platinum.toString(),
                          icon: Icons.star,
                          color: Colors.purple,
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _QuickAccessCard(
                          title: "Kelola Berita",
                          icon: Icons.newspaper,
                          color: Colors.orange,
                          onTap: () => onNavigate(1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAccessCard(
                          title: "Kelola Paket",
                          icon: Icons.inventory_2,
                          color: Colors.purple,
                          onTap: () => onNavigate(2),
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
                          onTap: () => onNavigate(3),
                        ),
                      ),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(title, textAlign: TextAlign.center),
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
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 12),
              Text(title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
