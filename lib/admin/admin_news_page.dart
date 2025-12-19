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

  // ================= PICK IMAGE =================
  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null) return;
    final bytes = result.files.first.bytes;
    if (bytes == null) return;

    if (bytes.lengthInBytes > 2.5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ukuran foto maksimal 2.5 MB")),
      );
      return;
    }

    setState(() => _imageBytes = bytes);
  }

  // ================= ADD NEWS =================
  Future<void> _saveNews() async {
    if (_titleCtrl.text.isEmpty || _contentCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title dan content wajib diisi")),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      String photoBase64 = _imageBytes != null
          ? base64Encode(_imageBytes!)
          : "";

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

  // ================= DELETE NEWS =================
  Future<void> _deleteNews(String docId) async {
    await FirebaseFirestore.instance.collection('news').doc(docId).delete();
  }

  // ================= EDIT NEWS =================
  Future<void> _editNews(String docId, Map<String, dynamic> data) async {
    _titleCtrl.text = data['title'] ?? '';
    _contentCtrl.text = data['content'] ?? '';
    _imageBytes = (data['photoBase64'] != null && data['photoBase64'] != "")
        ? base64Decode(data['photoBase64'])
        : null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Berita"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: "Title"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _contentCtrl,
                maxLines: 4,
                decoration: const InputDecoration(labelText: "Content"),
              ),
              const SizedBox(height: 8),
              if (_imageBytes != null)
                Image.memory(_imageBytes!, height: 120, fit: BoxFit.cover),
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text("Pilih Foto"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              String photoBase64 = _imageBytes != null
                  ? base64Encode(_imageBytes!)
                  : "";

              await FirebaseFirestore.instance
                  .collection('news')
                  .doc(docId)
                  .update({
                    "title": _titleCtrl.text.trim(),
                    "content": _contentCtrl.text.trim(),
                    "photoBase64": photoBase64,
                  });

              _titleCtrl.clear();
              _contentCtrl.clear();
              _imageBytes = null;
              if (mounted) setState(() {});

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Berita berhasil diupdate")),
              );
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // FORM TAMBAH NEWS
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
          // LIST BERITA
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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editNews(doc.id, data),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteNews(doc.id),
                          ),
                        ],
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
