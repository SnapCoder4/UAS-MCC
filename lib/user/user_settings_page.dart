import 'user_edit_profile_page.dart';
import 'package:flutter/material.dart';
import 'user_change_password_page.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserSettingsPage extends StatelessWidget {
  final DocumentSnapshot<Map<String, dynamic>> userDoc;
  final Future<void> Function()? onUpdated;

  const UserSettingsPage({super.key, required this.userDoc, this.onUpdated});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ===== Header =====
        const Text(
          "Pengaturan",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          "Kelola akun dan preferensi aplikasi",
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),

        // ===== Akun =====
        _sectionTitle("Akun"),

        _settingsCard(
          icon: Icons.person_outline,
          title: "Edit Profil",
          subtitle: "Ubah data pribadi",
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserEditProfilePage(userDoc: userDoc),
              ),
            );
            await onUpdated?.call();
          },
        ),

        _settingsCard(
          icon: Icons.lock_outline,
          title: "Ubah Password",
          subtitle: "Perbarui keamanan akun",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserChangePasswordPage()),
            );
          },
        ),

        const SizedBox(height: 24),

        // ===== Tampilan =====
        _sectionTitle("Tampilan"),

        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: SwitchListTile(
            secondary: _iconBox(Icons.dark_mode_outlined),
            title: const Text("Mode Gelap"),
            subtitle: const Text("Aktifkan tema gelap"),
            value: theme.isDarkMode,
            onChanged: theme.toggleTheme,
          ),
        ),
      ],
    );
  }

  // ===== Helpers (SAMA dengan Admin) =====

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _settingsCard({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: _iconBox(icon),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Colors.blue),
    );
  }
}
