import 'dart:convert';
import 'dart:typed_data';
import 'login_page.dart';
import '../services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import '../providers/theme_provider.dart';
import 'package:image_picker/image_picker.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameC = TextEditingController();
  final emailC = TextEditingController();
  final passC = TextEditingController();

  bool loading = false;
  bool showPass = false;

  Uint8List? imageBytes;
  String? imageBase64;

  String? gender;
  DateTime? birthDate;

  @override
  void dispose() {
    nameC.dispose();
    emailC.dispose();
    passC.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      final bytes = await picked.readAsBytes();

      if (bytes.lengthInBytes > 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ukuran foto maksimal 1 MB")),
        );
        return;
      }

      setState(() {
        imageBytes = bytes;
        imageBase64 = base64Encode(bytes);
      });
    }
  }

  void pickBirthDate() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        DateTime temp = birthDate ?? DateTime(2004, 1, 1);
        return SizedBox(
          height: 250,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    setState(() => birthDate = temp);
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
            children: [
              Image.asset(
                'assets/images/gymlife.png',
                height: size.height * 0.18,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: pickImage,
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.grey[300],
                  backgroundImage:
                      imageBytes != null ? MemoryImage(imageBytes!) : null,
                  child: imageBytes == null
                      ? const Icon(Icons.camera_alt, size: 30)
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Create Your Account 💪",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Daftar untuk mulai keanggotaan gym Anda",
                style: TextStyle(color: subTextColor),
              ),
              const SizedBox(height: 28),
              _CustomField(
                controller: nameC,
                label: "Nama Lengkap",
                icon: Icons.person_outline,
                fillColor: fieldFill,
                iconColor: iconColor,
                textColor: textColor,
              ),
              const SizedBox(height: 16),
              _CustomField(
                controller: emailC,
                label: "Email",
                icon: Icons.email_outlined,
                fillColor: fieldFill,
                iconColor: iconColor,
                textColor: textColor,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: pickBirthDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: "Tanggal Lahir",
                    filled: true,
                    fillColor: fieldFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        birthDate == null
                            ? "Pilih tanggal lahir"
                            : "${birthDate!.day.toString().padLeft(2, '0')}-"
                              "${birthDate!.month.toString().padLeft(2, '0')}-"
                              "${birthDate!.year}",
                        style: TextStyle(color: textColor),
                      ),
                      Icon(Icons.calendar_month, color: iconColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Jenis Kelamin",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text("Laki-laki"),
                    selected: gender == "L",
                    onSelected: (_) => setState(() => gender = "L"),
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text("Perempuan"),
                    selected: gender == "P",
                    onSelected: (_) => setState(() => gender = "P"),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          if (nameC.text.isEmpty ||
                              emailC.text.isEmpty ||
                              passC.text.isEmpty ||
                              gender == null ||
                              birthDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Semua field wajib diisi"),
                              ),
                            );
                            return;
                          }

                          setState(() => loading = true);

                          final error = await auth.registerUser(
                            name: nameC.text.trim(),
                            email: emailC.text.trim(),
                            password: passC.text.trim(),
                            gender: gender!,
                            birthDate: birthDate!,
                            photoBase64: imageBase64 ?? "",
                          );

                          setState(() => loading = false);

                          if (error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error)),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    "Registrasi berhasil, silakan login"),
                              ),
                            );
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                            );
                          }
                        },
                        child: Text(
                          "REGISTER",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: buttonTextColor,
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Sudah punya akun GymLife?",
                    style: TextStyle(color: subTextColor),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    child: Text(
                      "Login sekarang",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
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
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
