import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_membership_page.dart';
import 'user_chat_page.dart';
import 'user_settings_page.dart';

// Feature pages (dummy/real sesuai file kamu)
import '../features/workouts_page.dart';
import '../features/nutrition_page.dart';
import '../features/class_schedule_page.dart';
import '../features/personal_trainer_page.dart';

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

  void _goTo(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    if (_userDoc == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final data = _userDoc!.data() ?? {};
    final String name = data['name'] ?? 'User';
    final String email = data['email'] ?? widget.user.email ?? '';
    final String photoBase64 = data['photoBase64'] ?? "";

    final pages = [
      _UserDashboard(name: name, userId: widget.user.uid, onNavigate: _goTo),
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
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text("Dashboard"),
              onTap: () {
                Navigator.pop(context);
                _goTo(0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.newspaper_outlined),
              title: const Text("Berita"),
              onTap: () {
                Navigator.pop(context);
                _goTo(1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.card_membership),
              title: const Text("Membership"),
              onTap: () {
                Navigator.pop(context);
                _goTo(2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text("Chat"),
              onTap: () {
                Navigator.pop(context);
                _goTo(3);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text("Pengaturan"),
              onTap: () {
                Navigator.pop(context);
                _goTo(4);
              },
            ),
          ],
        ),
      ),
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _goTo,
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
              // ===== Welcome Card =====
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade700, Colors.blue.shade900],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Selamat Datang! 💪",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ===== Membership =====
              const Text(
                "Status Membership",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.card_membership,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  membershipType,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  membershipStatus,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (expiryDate != null) ...[
                        const Divider(height: 22),
                        Text(
                          "Berlaku hingga: ${expiryDate.day}-${expiryDate.month}-${expiryDate.year}",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                      if (membershipType == "Belum ada") ...[
                        const Divider(height: 22),
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

              const SizedBox(height: 22),

              // ===== Feature Cards =====
              const Text(
                "Fitur Gym",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _FeatureCard(
                    icon: Icons.schedule,
                    title: "Jadwal Kelas",
                    subtitle: "Lihat kelas minggu ini",
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ClassSchedulePage(),
                        ),
                      );
                    },
                  ),
                  _FeatureCard(
                    icon: Icons.fitness_center,
                    title: "Latihan",
                    subtitle: "Program latihan harian",
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WorkoutsPage()),
                      );
                    },
                  ),
                  _FeatureCard(
                    icon: Icons.restaurant_menu,
                    title: "Nutrisi",
                    subtitle: "Menu & rekomendasi",
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NutritionPage(),
                        ),
                      );
                    },
                  ),
                  _FeatureCard(
                    icon: Icons.person_outline,
                    title: "Personal Trainer",
                    subtitle: "Pilih trainer terbaik",
                    color: Colors.red,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PersonalTrainerPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withOpacity(0.65),
                ),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: Icon(
                  Icons.chevron_right,
                  color: scheme.onSurface.withOpacity(0.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== NEWS (tetap seperti punyamu) ====================

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
