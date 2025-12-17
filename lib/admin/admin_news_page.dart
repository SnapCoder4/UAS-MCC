import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminNewsPage extends StatefulWidget {
  const AdminNewsPage({super.key});

  @override
  State<AdminNewsPage> createState() => _AdminNewsPageState();
}

class _AdminNewsPageState extends State<AdminNewsPage> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  Uint8List? _imageBytes;
  bool _saving = false;

  Future<void> _pickImage() async {
    Uint8List? bytes;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null) return;
    bytes = result.files.first.bytes;
    if (bytes == null) return;

    if (bytes.lengthInBytes > 2.5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ukuran foto maksimal 2.5 MB")),
      );
      return;
    }

    setState(() => _imageBytes = bytes);
  }

  Future<void> _saveNews() async {
    if (_titleCtrl.text.isEmpty || _contentCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title dan content wajib diisi")),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      String photoBase64 = "";
      if (_imageBytes != null) {
        photoBase64 = base64Encode(_imageBytes!);
      }

      await FirebaseFirestore.instance.collection('news').add({
        "title": _titleCtrl.text.trim(),
        "content": _contentCtrl.text.trim(),
        "photoBase64": photoBase64,
        "createdAt": Timestamp.now(),
      });

      _titleCtrl.clear();
      _contentCtrl.clear();
      setState(() => _imageBytes = null);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Berita berhasil ditambahkan")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteNews(String docId) async {
    await FirebaseFirestore.instance.collection('news').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: "Title",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _contentCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: "Content",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          if (_imageBytes != null)
            Image.memory(_imageBytes!, height: 120, fit: BoxFit.cover),
          TextButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.image),
            label: const Text("Pilih Foto"),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveNews,
              child: _saving
                  ? const CircularProgressIndicator()
                  : const Text("Tambah Berita"),
            ),
          ),
          const Divider(),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('news')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Center(child: Text("Belum ada berita"));
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading:
                          data['photoBase64'] != null &&
                              data['photoBase64'] != ""
                          ? Image.memory(
                              base64Decode(data['photoBase64']),
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.image_not_supported),
                      title: Text(data['title'] ?? ''),
                      subtitle: Text(data['content'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteNews(doc.id),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
