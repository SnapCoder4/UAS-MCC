import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminChatPage extends StatefulWidget {
  final String userId;
  final String userName;

  const AdminChatPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<AdminChatPage> createState() => _AdminChatPageState();
}

class _AdminChatPageState extends State<AdminChatPage> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  Future<void> _send() async {
    if (_ctrl.text.trim().isEmpty) return;
    final text = _ctrl.text.trim();
    _ctrl.clear();

    final chatRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.userId);

    await chatRef.update({
      "lastMessage": text,
      "lastMessageAt": FieldValue.serverTimestamp(),
    });

    await chatRef.collection('messages').add({
      "senderId": "admin",
      "senderRole": "admin",
      "text": text,
      "createdAt": FieldValue.serverTimestamp(),
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final chatRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.userId);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(title: Text(widget.userName), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: chatRef
                  .collection('messages')
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (c, s) {
                if (!s.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final msgs = s.data!.docs;

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(12),
                  itemCount: msgs.length,
                  itemBuilder: (c, i) {
                    final m = msgs[i].data();
                    final isAdmin = m['senderRole'] == 'admin';

                    final time = m['createdAt'] != null
                        ? DateFormat(
                            'HH:mm',
                          ).format((m['createdAt'] as Timestamp).toDate())
                        : "";

                    return Align(
                      alignment: isAdmin
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isAdmin
                              ? scheme.primary
                              : scheme.secondaryContainer,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isAdmin ? 16 : 0),
                            bottomRight: Radius.circular(isAdmin ? 0 : 16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              m['text'],
                              style: TextStyle(
                                color: isAdmin
                                    ? scheme.onPrimary
                                    : scheme.onSecondaryContainer,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 11,
                                color: isAdmin
                                    ? scheme.onPrimary.withOpacity(0.7)
                                    : scheme.onSecondaryContainer.withOpacity(
                                        0.6,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _inputBar(scheme),
        ],
      ),
    );
  }

  Widget _inputBar(ColorScheme scheme) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        color: scheme.surface,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: "Balas pesan...",
                  filled: true,
                  fillColor: scheme.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 22,
              backgroundColor: scheme.primary,
              child: IconButton(
                icon: Icon(Icons.send, color: scheme.onPrimary, size: 20),
                onPressed: _send,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
