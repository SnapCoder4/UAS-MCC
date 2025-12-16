import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'auth/login_page.dart';
import 'admin/admin_home.dart';
import 'user/user_home.dart';

/// Key global buat snackBar (nanti bisa dipakai di mana saja)
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<String?> getUserRole(String uid) async {
  // Cek dulu di koleksi admins
  final adminDoc = await FirebaseFirestore.instance
      .collection('admins')
      .doc(uid)
      .get();
  if (adminDoc.exists) return "admin";

  // Kalau bukan admin, cek users
  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .get();
  if (userDoc.exists) return "user";

  return null;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, st) {
    // Kalau ada masalah saat init Firebase, kelihatan di console
    debugPrint("Error init Firebase: $e");
    debugPrintStack(stackTrace: st);
  }

  runApp(const GymApp());
}

class GymApp extends StatelessWidget {
  const GymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Gym App',
            scaffoldMessengerKey: rootScaffoldMessengerKey,
            themeMode: theme.themeMode,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              useMaterial3: true,
            ),
            darkTheme: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
              ),
            ),

            // route utama tetap AuthGate
            home: const AuthGate(),

            // optional: named routes kalau nanti mau dipakai
            routes: {
              '/login': (_) => const LoginPage(),
              // route ini biasanya dipakai setelah AuthGate cek role
              '/admin': (ctx) {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return const LoginPage();
                return AdminHome(user: user);
              },
              '/user': (ctx) {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return const LoginPage();
                return UserHome(user: user);
              },
            },
          );
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snap.hasData) {
          return const LoginPage();
        }

        final user = snap.data!;
        return FutureBuilder<String?>(
          future: getUserRole(user.uid),
          builder: (context, roleSnap) {
            if (roleSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!roleSnap.hasData) {
              // user login tapi belum punya data di admins/users
              return const LoginPage();
            }

            final role = roleSnap.data;
            if (role == "admin") {
              return AdminHome(user: user);
            } else {
              return UserHome(user: user);
            }
          },
        );
      },
    );
  }
}
