import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserChatPage extends StatefulWidget {
  const UserChatPage({super.key});

  @override
  State<UserChatPage> createState() => _UserChatPageState();
}

class _UserChatPageState extends State<UserChatPage> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final user = FirebaseAuth.instance.currentUser!;

  Future<void> _send() async {
    if (_ctrl.text.trim().isEmpty) return;
    final text = _ctrl.text.trim();
    _ctrl.clear();

    final chatRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(user.uid);

    await chatRef.set({
      "userId": user.uid,
      "userName": user.displayName ?? "User",
      "lastMessage": text,
      "lastMessageAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await chatRef.collection('messages').add({
      "senderId": user.uid,
      "senderRole": "user",
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
        .doc(user.uid);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(title: const Text("Chat Admin"), centerTitle: true),
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
                    final isMe = m['senderRole'] == 'user';

                    final time = m['createdAt'] != null
                        ? DateFormat(
                            'HH:mm',
                          ).format((m['createdAt'] as Timestamp).toDate())
                        : "";

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? scheme.primary
                              : scheme.secondaryContainer,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              m['text'],
                              style: TextStyle(
                                color: isMe
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
                                color: isMe
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
                decoration: InputDecoration(
                  hintText: "Ketik pesan...",
                  filled: true,
                  fillColor: scheme.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: scheme.primary,
              child: IconButton(
                icon: Icon(Icons.send, color: scheme.onPrimary),
                onPressed: _send,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
