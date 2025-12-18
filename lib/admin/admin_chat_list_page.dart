import 'dart:convert';
import 'dart:typed_data';

import 'admin_chat_page.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Uint8List? _safeBase64(String? s) {
  if (s == null) return null;
  var v = s.trim();
  if (v.isEmpty) return null;

  // kalau kebawa "...."
  if (v.startsWith('"') && v.endsWith('"') && v.length >= 2) {
    v = v.substring(1, v.length - 1).trim();
  }

  // kalau format data url
  final idx = v.indexOf('base64,');
  if (idx != -1) v = v.substring(idx + 7).trim();

  if (v.isEmpty) return null;
  try {
    return base64Decode(v);
  } catch (_) {
    return null;
  }
}

class AdminChatListPage extends StatelessWidget {
  const AdminChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Daftar Chat"), centerTitle: true),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .orderBy('lastMessageAt', descending: true)
            .snapshots(),
        builder: (c, s) {
          if (!s.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = s.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Text(
                "Belum ada chat",
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (c, i) {
              final chatData = docs[i].data();

              // ✅ userId wajib. Kalau field userId tidak ada, pakai doc.id
              final String userId = (chatData['userId'] ?? docs[i].id)
                  .toString();

              final time = chatData['lastMessageAt'] != null
                  ? DateFormat(
                      'HH:mm',
                    ).format((chatData['lastMessageAt'] as Timestamp).toDate())
                  : "";

              // ✅ Ambil user profile dari users/{userId}
              return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .snapshots(),
                builder: (context, userSnap) {
                  final user = userSnap.data?.data() ?? {};

                  final String name =
                      (user['name'] ??
                              user['username'] ??
                              user['email'] ??
                              chatData['userName'] ??
                              "User")
                          .toString();

                  // prioritas foto dari users, fallback ke chat doc
                  final bytes = _safeBase64(
                    (user['photoBase64'] ?? chatData['userPhotoBase64'])
                        ?.toString(),
                  );

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      leading: CircleAvatar(
                        radius: 26,
                        backgroundColor: scheme.primary.withOpacity(0.15),
                        backgroundImage: bytes != null
                            ? MemoryImage(bytes)
                            : null,
                        child: bytes == null
                            ? Icon(Icons.person, color: scheme.primary)
                            : null,
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          (chatData['lastMessage'] ?? "").toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: scheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          c,
                          MaterialPageRoute(
                            builder: (_) => AdminChatPage(
                              userId: userId,
                              userName: name, // ✅ kirim nama asli
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
        },
      ),
    );
  }
}
