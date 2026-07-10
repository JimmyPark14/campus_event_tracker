import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/ai_service.dart';

class RegistrationProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Submits a payment receipt for verification.
  /// Saves to events/{eventId}/registrations/{userId}
  Future<void> submitPayment(String eventId, String userId, String receiptBase64) async {
    try {
      // Fetch data for AI
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) throw Exception('Event not found');
      final eventData = eventDoc.data()!;
      final expectedAmount = (eventData['price'] ?? 0).toDouble();
      final organizerId = eventData['organizerId'];
      final createdAt = (eventData['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);

      final organizerDoc = await _firestore.collection('users').doc(organizerId).get();
      final expectedName = organizerDoc.data()?['bankAccountName']?.toString().isNotEmpty == true 
          ? organizerDoc.data()!['bankAccountName'] 
          : organizerDoc.data()?['name'] ?? '';

      // Call AI Service
      final aiResult = await AiService.verifyReceipt(
        base64Image: receiptBase64,
        expectedAmount: expectedAmount,
        expectedName: expectedName,
      );

      bool isAiVerified = aiResult['isAiVerified'] ?? false;
      String aiReason = aiResult['reason'] ?? '';
      final transactionId = aiResult['transactionId'] ?? '';
      final transactionDateStr = aiResult['transactionDate'] ?? '';

      // Security Check: Duplicate Transaction ID
      if (transactionId.isNotEmpty) {
        // Search across all registrations for this event to see if transactionId is reused
        final dupCheck = await _firestore
            .collection('events')
            .doc(eventId)
            .collection('registrations')
            .where('transactionId', isEqualTo: transactionId)
            .limit(1)
            .get();
        if (dupCheck.docs.isNotEmpty) {
          isAiVerified = false;
          aiReason = "Duplicate Transaction ID (Shared Receipt). Original: \$aiReason";
        }
      }

      // Security Check: Date
      if (transactionDateStr.isNotEmpty) {
        try {
          // Attempt to parse YYYY-MM-DD HH:MM
          final transDate = DateTime.parse(transactionDateStr.replaceAll(' ', 'T'));
          if (transDate.isBefore(createdAt)) {
            isAiVerified = false;
            aiReason = "Transaction date is older than event creation. Fake receipt. Original: \$aiReason";
          }
        } catch (_) {}
      }

      // Security Check: Trust Score
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final isPhoneVerified = userDoc.data()?['isPhoneVerified'] ?? false;
      final isEmailVerified = userDoc.data()?['isEmailVerified'] ?? false;
      if (!isPhoneVerified && !isEmailVerified) {
        aiReason += " [Warning: Account not verified. Risk of burner account.]";
      }

      final docRef = _firestore
          .collection('events')
          .doc(eventId)
          .collection('registrations')
          .doc(userId);

      await docRef.set({
        'eventId': eventId,
        'userId': userId,
        'receiptBase64': receiptBase64,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending_verification',
        'paymentMethod': 'DuitNow QR',
        'refundRequested': false,
        'aiVerified': isAiVerified,
        'aiReason': aiReason,
        'transactionId': transactionId,
      });

      // Also add to event's pendingUserIds array for quick querying
      await _firestore.collection('events').doc(eventId).update({
        'pendingUserIds': FieldValue.arrayUnion([userId]),
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error submitting payment: $e');
      rethrow;
    }
  }

  /// Verifies a payment and fully registers the student
  Future<void> verifyPayment(String eventId, String userId) async {
    try {
      final docRef = _firestore
          .collection('events')
          .doc(eventId)
          .collection('registrations')
          .doc(userId);
      
      await docRef.update({
        'status': 'verified',
      });

      // Move user from pending to registered
      await _firestore.collection('events').doc(eventId).update({
        'pendingUserIds': FieldValue.arrayRemove([userId]),
        'registeredUserIds': FieldValue.arrayUnion([userId]),
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error verifying payment: $e');
      rethrow;
    }
  }

  /// Get registration stream for a specific user and event (Digital Ticket)
  Stream<DocumentSnapshot> getRegistrationStream(String eventId, String userId) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('registrations')
        .doc(userId)
        .snapshots();
  }
  
  Stream<QuerySnapshot> getVerifiedRegistrationsStream(String eventId) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('registrations')
        .where('status', isEqualTo: 'verified')
        .snapshots();
  }

  Stream<QuerySnapshot> getPendingRefundsStream(String eventId) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('registrations')
        .where('refundStatus', isEqualTo: 'pending')
        .snapshots();
  }

  Future<QuerySnapshot> getAllRegistrationsFuture(String eventId) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('registrations')
        .get();
  }

  /// Get all pending registrations for an event (Payment Verify)
  Future<List<Map<String, dynamic>>> getPendingRegistrations(String eventId) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .doc(eventId)
          .collection('registrations')
          .where('status', isEqualTo: 'pending_verification')
          .get();
          
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error getting pending registrations: $e');
      return [];
    }
  }
  
  /// Get all verified registrations for an event (Participant Roster)
  Future<List<Map<String, dynamic>>> getVerifiedRegistrations(String eventId) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .doc(eventId)
          .collection('registrations')
          .where('status', isEqualTo: 'verified')
          .get();
          
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error getting verified registrations: $e');
      return [];
    }
  }
}
