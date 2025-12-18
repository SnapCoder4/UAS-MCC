import 'dart:convert';
import 'admin_chat_page.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
              final d = docs[i].data();
              final photo = d['userPhotoBase64'] ?? "";

              final time = d['lastMessageAt'] != null
                  ? DateFormat(
                      'HH:mm',
                    ).format((d['lastMessageAt'] as Timestamp).toDate())
                  : "";

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
                    backgroundImage: photo.isNotEmpty
                        ? MemoryImage(base64Decode(photo))
                        : null,
                    child: photo.isEmpty
                        ? Icon(Icons.person, color: scheme.primary)
                        : null,
                  ),
                  title: Text(
                    d['userName'] ?? "User",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      d['lastMessage'] ?? "",
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
                          userId: d['userId'],
                          userName: d['userName'],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
