import 'register_page.dart';
import '../services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailC = TextEditingController();
  final passC = TextEditingController();
  bool loading = false;
  bool showPass = false;

  @override
  void dispose() {
    emailC.dispose();
    passC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final bgColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final fieldFill = isDark ? Colors.grey[850] : Colors.grey[200];
    final iconColor = isDark ? Colors.white70 : Colors.black54;
    final buttonColor = isDark ? Colors.grey[900] : Colors.black;
    final buttonTextColor = Colors.white;

    final auth = Provider.of<AuthService>(context, listen: false);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/gymlife.png',
                      height: size.height * 0.18,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              const SizedBox(height: 35),
              Text(
                "Welcome Back 💪",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Login untuk mengelola keanggotaan gym Anda",
                style: TextStyle(fontSize: 15, color: subTextColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              _CustomField(
                controller: emailC,
                label: "Email",
                icon: Icons.email_outlined,
                fillColor: fieldFill,
                iconColor: iconColor,
                textColor: textColor,
              ),
              const SizedBox(height: 18),
              _CustomField(
                controller: passC,
                label: "Password",
                obscure: !showPass,
                icon: Icons.lock_outline,
                suffix: IconButton(
                  icon: Icon(
                    showPass ? Icons.visibility_off : Icons.visibility,
                    color: iconColor,
                  ),
                  onPressed: () => setState(() => showPass = !showPass),
                ),
                fillColor: fieldFill,
                iconColor: iconColor,
                textColor: textColor,
              ),
              const SizedBox(height: 28),
              loading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          "LOGIN",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: buttonTextColor,
                            letterSpacing: 1.2,
                          ),
                        ),
                        onPressed: () async {
                          if (emailC.text.isEmpty || passC.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Email dan password wajib diisi"),
                              ),
                            );
                            return;
                          }

                          setState(() => loading = true);

                          final error = await auth.login(
                            emailC.text.trim(),
                            passC.text.trim(),
                          );

                          setState(() => loading = false);

                          if (error != null) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(error)));
                          }
                        },
                      ),
                    ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Belum punya akun GymLife?",
                    style: TextStyle(color: subTextColor),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      );
                    },
                    child: Text(
                      "Daftar Sekarang",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final Color? fillColor;
  final Color? iconColor;
  final Color? textColor;

  const _CustomField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.fillColor,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: iconColor),
        suffixIcon: suffix,
        labelText: label,
        labelStyle: TextStyle(color: iconColor),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
