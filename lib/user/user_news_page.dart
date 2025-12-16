import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final title = data['title'] ?? '';
            final content = data['content'] ?? '';
            final photoBase64 = data['photoBase64'] ?? '';
            final createdAt = data['createdAt'] != null
                ? (data['createdAt'] as Timestamp).toDate()
                : null;

            return Card(
              child: ListTile(
                leading: photoBase64.isNotEmpty
                    ? Image.memory(
                        base64Decode(photoBase64),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.newspaper),
                title: Text(title),
                subtitle: Text(
                  content.length > 50 ? "${content.substring(0, 50)}..." : content,
                ),
                trailing: createdAt != null
                    ? Text(
                        "${createdAt.day}-${createdAt.month}-${createdAt.year}",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      )
                    : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserNewsDetailPage(news: data),
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
  final Map<String, dynamic> news;
  const UserNewsDetailPage({required this.news, super.key});

  @override
  Widget build(BuildContext context) {
    final title = news['title'] ?? '';
    final content = news['content'] ?? '';
    final photoBase64 = news['photoBase64'] ?? '';
    final createdAt = news['createdAt'] != null
        ? (news['createdAt'] as Timestamp).toDate()
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text("Detail Berita")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (photoBase64.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  base64Decode(photoBase64),
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            if (createdAt != null)
              Text(
                "${createdAt.day}-${createdAt.month}-${createdAt.year}",
                style: const TextStyle(color: Colors.grey),
              ),
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
