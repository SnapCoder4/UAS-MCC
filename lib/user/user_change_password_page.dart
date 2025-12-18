import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserChangePasswordPage extends StatefulWidget {
  const UserChangePasswordPage({super.key});

  @override
  State<UserChangePasswordPage> createState() =>
      _UserChangePasswordPageState();
}

class _UserChangePasswordPageState extends State<UserChangePasswordPage> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  bool _hideOld = true;
  bool _hideNew = true;
  bool _hideConfirm = true;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final oldPass = _oldCtrl.text.trim();
    final newPass = _newCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (oldPass.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      _show("Semua field wajib diisi");
      return;
    }

    if (newPass.length < 6) {
      _show("Password baru minimal 6 karakter");
      return;
    }

    if (newPass != confirm) {
      _show("Konfirmasi password tidak sama");
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    setState(() => _loading = true);

    try {
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPass,
      );

      await user.reauthenticateWithCredential(cred);

      await user.updatePassword(newPass);

      if (!mounted) return;
      _show("Password berhasil diubah", success: true);
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        _show("Password lama salah");
      } else {
        _show(e.message ?? "Gagal mengubah password");
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _show(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ubah Password")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _oldCtrl,
              obscureText: _hideOld,
              decoration: InputDecoration(
                labelText: "Password Lama",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _hideOld ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _hideOld = !_hideOld),
                ),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _newCtrl,
              obscureText: _hideNew,
              decoration: InputDecoration(
                labelText: "Password Baru",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _hideNew ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _hideNew = !_hideNew),
                ),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _confirmCtrl,
              obscureText: _hideConfirm,
              decoration: InputDecoration(
                labelText: "Konfirmasi Password Baru",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _hideConfirm ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.lock_reset),
                label: _loading
                    ? const CircularProgressIndicator()
                    : const Text("Ubah Password"),
                onPressed: _loading ? null : _changePassword,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
