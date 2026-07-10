import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sends a message to a specific event's chat
  Future<void> sendMessage({
    required String eventId,
    required String userId,
    required String userName,
    required String userRole,
    required String text,
  }) async {
    try {
      await _firestore
          .collection('events')
          .doc(eventId)
          .collection('messages')
          .add({
        'text': text,
        'userId': userId,
        'userName': userName,
        'userRole': userRole,
        'timestamp': FieldValue.serverTimestamp(),
      });
      // We don't necessarily need to notifyListeners() here since the UI
      // will be listening to the stream.
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  /// Returns a stream of messages for a specific event
  Stream<QuerySnapshot> getMessagesStream(String eventId) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
