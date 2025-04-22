import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final String senderName;
  final DateTime timestamp;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.senderName,
    required this.timestamp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('hh:mm a').format(timestamp);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isMe ? Colors.blueAccent : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                senderName,
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            SizedBox(height: 4),
            Text(
              message,
              style: TextStyle(color: isMe ? Colors.white : Colors.black87),
            ),
            SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(fontSize: 12, color: isMe ? Colors.white70 : Colors.black54),
            )
          ],
        ),
      ),
    );
  }
}
