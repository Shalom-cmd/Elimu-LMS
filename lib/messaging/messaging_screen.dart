// lib/messaging/messaging_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_bubble.dart';
import 'firebase_messaging_service.dart';
import 'package:intl/intl.dart';

class MessagingScreen extends StatefulWidget {
  final String userId;
  final String fullName;
  final String role;
  final String schoolDomain;

  const MessagingScreen({
    Key? key,
    required this.userId,
    required this.fullName,
    required this.role,
    required this.schoolDomain,
  }) : super(key: key);

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  final TextEditingController _messageController = TextEditingController();
  String? _selectedReceiverId;
  String? _selectedReceiverName;
  Map<String, String> _lastMessages = {};

  @override
  void initState() {
    super.initState();
    _fetchLastMessages();
  }

  Future<void> _fetchLastMessages() async {
    final users = await _fetchUsersFromAllRoles();
    for (var user in users) {
      final conversationId = FirebaseMessagingService.getConversationId(widget.userId, user['uid']);
      final chatsSnapshot = await FirebaseFirestore.instance
          .collection('messages')
          .doc(conversationId)
          .collection('chats')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (chatsSnapshot.docs.isNotEmpty) {
        final lastMessage = chatsSnapshot.docs.first['text'];
        _lastMessages[user['uid']] = lastMessage;
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _selectedReceiverName != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Chat with $_selectedReceiverName',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _selectedReceiverId = null;
                        _selectedReceiverName = null;
                      });
                    },
                  )
                ],
              )
            : Text('Select a User to Chat'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          if (_selectedReceiverId == null)
            Expanded(child: _buildUserList())
          else
            Expanded(child: _buildChatMessages()),
          if (_selectedReceiverId != null) _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchUsersFromAllRoles(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        final users = snapshot.data!;
        if (users.isEmpty) {
          return Center(child: Text("No users available to message in your school."));
        }
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              title: Text(user['fullName']),
              subtitle: Text(_lastMessages[user['uid']] ?? user['role']),
              leading: Icon(Icons.person),
              onTap: () {
                setState(() {
                  _selectedReceiverId = user['uid'];
                  _selectedReceiverName = user['fullName'];
                });
              },
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchUsersFromAllRoles() async {
    final List<Map<String, dynamic>> users = [];
    final roles = ['students', 'teachers', 'admin'];

    for (String role in roles) {
      final snapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolDomain)
          .collection(role)
          .get();

      for (var doc in snapshot.docs) {
        if (doc.id != widget.userId) {
          users.add({
            'uid': doc['uid'],
            'fullName': doc['fullName'],
            'role': role.substring(0, role.length - 1), 
          });
        }
      }
    }
    return users;
  }

  Widget _buildChatMessages() {
    final conversationId = FirebaseMessagingService.getConversationId(widget.userId, _selectedReceiverId!);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('messages')
          .doc(conversationId)
          .collection('chats')
          .orderBy('timestamp')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

        final messages = snapshot.data!.docs;
        String? currentDate;

        return ListView.builder(
          padding: EdgeInsets.all(10),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index]; 
            final rawTimestamp = msg['timestamp'];
            final parsedTimestamp = rawTimestamp != null ? (rawTimestamp as Timestamp).toDate() : DateTime.now();

            final msgDate = DateFormat.yMMMd().format(parsedTimestamp);
            final showDate = msgDate != currentDate;
            currentDate = msgDate;

            final isMe = msg['senderId'] == widget.userId;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (showDate)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      msgDate,
                      style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ),
                ChatBubble(
                  message: msg['text'],
                  isMe: isMe,
                  senderName: msg['senderName'],
                  timestamp: parsedTimestamp,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.send, color: Colors.blueAccent),
            onPressed: _sendMessage,
          )
        ],
      ),
    );
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _selectedReceiverId == null) return;

    await FirebaseMessagingService.sendMessage(
      senderId: widget.userId,
      senderName: widget.fullName,
      receiverId: _selectedReceiverId!,
      text: _messageController.text.trim(),
    );

    _messageController.clear();
    _fetchLastMessages();
  }
}
