import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseMessagingService {
  static final _firestore = FirebaseFirestore.instance;

  static String getConversationId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  static Future<void> sendMessage({
    required String senderId,
    required String senderName,
    required String receiverId,
    required String text,
  }) async {
    final conversationId = getConversationId(senderId, receiverId);
    final chatRef = _firestore
        .collection('messages')
        .doc(conversationId)
        .collection('chats')
        .doc();

    await chatRef.set({
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
