import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event_model.dart';
import '../services/notification_service.dart';

class EventProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<EventModel> _events = [];
  bool _isLoading = false;
  DateTime? _lastRefreshTime;
  
  StreamSubscription<QuerySnapshot>? _eventsSubscription;

  Future<bool> requestRefresh() async {
    final now = DateTime.now();
    if (_lastRefreshTime != null && now.difference(_lastRefreshTime!).inSeconds < 30) {
      return false; // Deny refresh
    }
    _lastRefreshTime = now;
    await Future.delayed(const Duration(seconds: 1));
    return true; // Allow refresh
  }

  List<EventModel> get events => _events.where((e) => !e.isDraft).toList();
  bool get isLoading => _isLoading;

  EventProvider() {
    _listenToEvents();
  }

  void _listenToEvents() async {
    _isLoading = true;
    notifyListeners();

    // Load from cache first
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedEvents = prefs.getStringList('cached_events');
      if (cachedEvents != null) {
        _events = cachedEvents.map((e) => EventModel.fromJson(jsonDecode(e))).toList();
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cached events: $e');
    }

    _eventsSubscription?.cancel();
    
    _eventsSubscription = _firestore
        .collection('events')
        .snapshots()
        .listen((snapshot) async {
      
      _events = snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
      _isLoading = false;
      notifyListeners();
      
      // Save to cache
      try {
        final prefs = await SharedPreferences.getInstance();
        final eventStrings = _events.map((e) => jsonEncode(e.toJson())).toList();
        await prefs.setStringList('cached_events', eventStrings);
      } catch (e) {
        debugPrint('Error caching events: $e');
      }
    }, onError: (error) {
      debugPrint('Error listening to events: $error');
      _isLoading = false;
      notifyListeners();
    });
  }

  EventModel? getEventById(String id) {
    try {
      return _events.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  List<EventModel> getOrganizerEvents(String organizerId) {
    return _events.where((e) => e.organizerId == organizerId).toList();
  }

  int getOrganizerTotalRegistrations(String organizerId) {
    int total = 0;
    for (var event in getOrganizerEvents(organizerId)) {
      total += event.registeredUserIds.length;
    }
    return total;
  }

  int getOrganizerPendingApprovals(String organizerId) {
    int total = 0;
    for (var event in getOrganizerEvents(organizerId)) {
      total += event.pendingUserIds.length;
    }
    return total;
  }

  double getOrganizerTotalRevenue(String organizerId) {
    double total = 0;
    for (var event in getOrganizerEvents(organizerId)) {
      // Very basic logic for revenue based on numeric price
      total += event.price * event.registeredUserIds.length;
    }
    return total;
  }

  int getOrganizerActiveEvents(String organizerId) {
    return getOrganizerEvents(organizerId).where((e) => !e.date.isBefore(DateTime.now()) && !e.isEventEnded && !e.isCancelled && !e.isDraft).length;
  }

  Future<void> _createNotification({
    required String userId,
    required String title,
    required String message,
    required String iconName,
    required String iconColorName,
    String? actionRoute,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': title,
        'message': message,
        'iconName': iconName,
        'iconColorName': iconColorName,
        'actionRoute': actionRoute,
        'isUnread': true,
        'section': 'New',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }

  Future<void> addEvent(EventModel event) async {
    try {
      String eventId = event.id;
      if (eventId.isNotEmpty) {
        await _firestore.collection('events').doc(eventId).set(event.toFirestore());
      } else {
        final docRef = await _firestore.collection('events').add(event.toFirestore());
        eventId = docRef.id;
      }
      
      // Notify organizer
      await _createNotification(
        userId: event.organizerId,
        title: 'Event Successfully Created',
        message: 'Your event "${event.title}" is now live.',
        iconName: 'calendarCheck',
        iconColorName: 'primary',
        actionRoute: '/organizer/event-detail/$eventId',
      );

      // Notify followers
      try {
        final organizerDoc = await _firestore.collection('users').doc(event.organizerId).get();
        if (organizerDoc.exists) {
          final data = organizerDoc.data();
          if (data != null && data.containsKey('followers')) {
            final followers = List<String>.from(data['followers'] ?? []);
            final organizerName = data['name'] ?? 'An organizer you follow';
            
            for (final followerId in followers) {
               await _createNotification(
                 userId: followerId,
                 title: 'New Event from $organizerName',
                 message: 'They just published "${event.title}". Check it out!',
                 iconName: 'event',
                 iconColorName: 'primary',
                 actionRoute: '/event-detail/$eventId',
               );
            }
          }
        }
      } catch (e) {
        debugPrint('Error notifying followers: $e');
      }
      
    } catch (e) {
      debugPrint('Error adding event: $e');
      rethrow;
    }
  }

  Future<void> updateEvent(
    String eventId,
    EventModel updatedEvent, {
    String? actionTitle,
    String? actionMessage,
  }) async {
    try {
      await _firestore.collection('events').doc(eventId).update(updatedEvent.toFirestore());
      
      final title = actionTitle ?? 'Event Successfully Updated';
      final message = actionMessage ?? 'Your event "${updatedEvent.title}" has been updated.';

      // Notify organizer
      await _createNotification(
        userId: updatedEvent.organizerId,
        title: title,
        message: message,
        iconName: 'calendarCheck',
        iconColorName: 'primary',
        actionRoute: '/organizer/event-detail/$eventId',
      );
      
      // Notify registered students about specific status changes
      if (actionTitle != null && actionMessage != null) {
        String studentMessage = actionMessage
            .replaceAll("You successfully ", "The organizer ")
            .replaceAll("You ", "The organizer ");
            
        for (String studentId in updatedEvent.registeredUserIds) {
          if (studentId != updatedEvent.organizerId) {
            await _createNotification(
              userId: studentId,
              title: actionTitle,
              message: studentMessage,
              iconName: 'info',
              iconColorName: 'primary',
              actionRoute: '/event-detail/$eventId',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error updating event: $e');
      rethrow;
    }
  }

  Future<void> toggleBookmark(String eventId, String userId) async {
    try {
      final event = getEventById(eventId);
      if (event == null) return;
      
      final docRef = _firestore.collection('events').doc(eventId);
      final isBookmarked = event.bookmarkedUserIds.contains(userId);
      
      if (isBookmarked) {
        await docRef.update({
          'bookmarkedUserIds': FieldValue.arrayRemove([userId])
        });
      } else {
        await docRef.update({
          'bookmarkedUserIds': FieldValue.arrayUnion([userId])
        });
        await _createNotification(
          userId: userId,
          title: 'Event Saved',
          message: 'You bookmarked "${event.title}".',
          iconName: 'bookmark',
          iconColorName: 'primary',
          actionRoute: '/event-detail/$eventId',
        );
      }
    } catch (e) {
      debugPrint('Error toggling bookmark: $e');
    }
  }
  
  Future<void> submitPaymentForVerification(String eventId, String userId) async {
    try {
      final docRef = _firestore.collection('events').doc(eventId);
      await docRef.update({
        'pendingUserIds': FieldValue.arrayUnion([userId]),
      });
      
      final event = getEventById(eventId);
      if (event != null) {
        // Notify student
        await _createNotification(
          userId: userId,
          title: 'Payment Submitted',
          message: 'Your payment for "${event.title}" is pending verification.',
          iconName: 'info',
          iconColorName: 'secondary',
          actionRoute: '/event-detail/$eventId',
        );
        
        // Notify organizer
        String studentName = 'A student';
        try {
          final userDoc = await _firestore.collection('users').doc(userId).get();
          if (userDoc.exists) {
            studentName = userDoc.data()?['name'] ?? 'A student';
          }
        } catch (_) {}
        
        await _createNotification(
          userId: event.organizerId,
          title: 'New Payment Verification',
          message: '$studentName has submitted a payment for "${event.title}".',
          iconName: 'alertCircle',
          iconColorName: 'secondary',
          actionRoute: '/payment-verify?eventId=$eventId',
        );
      }
    } catch (e) {
      debugPrint('Error submitting payment: $e');
    }
  }

  Future<void> verifyPayment(String eventId, String userId, bool isApproved) async {
    try {
      final event = getEventById(eventId);
      if (event == null) return;
      
      final docRef = _firestore.collection('events').doc(eventId);
      
      if (isApproved) {
        await docRef.update({
          'pendingUserIds': FieldValue.arrayRemove([userId]),
          'registeredUserIds': FieldValue.arrayUnion([userId]),
          'availableSpots': FieldValue.increment(-1),
          'registrationTimestamps': FieldValue.arrayUnion([Timestamp.now()]),
        });
        
        await _createNotification(
          userId: userId,
          title: 'Payment Verified',
          message: 'Your payment for "${event.title}" has been approved! You are now registered.',
          iconName: 'checkCircle',
          iconColorName: 'primary',
          actionRoute: '/event-detail/$eventId',
        );
      } else {
        await docRef.update({
          'pendingUserIds': FieldValue.arrayRemove([userId]),
        });
        
        await _createNotification(
          userId: userId,
          title: 'Payment Rejected',
          message: 'Your payment for "${event.title}" could not be verified. Please contact the organizer.',
          iconName: 'error',
          iconColorName: 'error',
          actionRoute: '/event-detail/$eventId',
        );
      }
    } catch(e) {
      debugPrint('Error verifying payment: $e');
    }
  }

  Future<void> requestRefund(String eventId, String userId, String reason) async {
    try {
      if (reason.trim().isEmpty) {
        throw Exception('A reason is required to request a refund.');
      }

      final docRef = _firestore.collection('events').doc(eventId).collection('registrations').doc(userId);
      
      final docSnap = await docRef.get();
      if (docSnap.exists) {
        final data = docSnap.data() as Map<String, dynamic>;
        if (data['refundRequested'] == true) {
          throw Exception('A refund has already been requested for this event.');
        }
      }

      await docRef.update({
        'refundRequested': true,
        'refundReason': reason,
        'refundStatus': 'pending',
      });
      
      final event = getEventById(eventId);
      if (event != null) {
        // Notify student
        await _createNotification(
          userId: userId,
          title: 'Refund Request Submitted',
          message: 'Your refund request for "${event.title}" is being reviewed.',
          iconName: 'info',
          iconColorName: 'secondary',
          actionRoute: '/event-detail/$eventId',
        );
        
        // Notify organizer
        String studentName = 'A student';
        try {
          final userDoc = await _firestore.collection('users').doc(userId).get();
          if (userDoc.exists) {
            studentName = userDoc.data()?['name'] ?? 'A student';
          }
        } catch (_) {}
        
        await _createNotification(
          userId: event.organizerId,
          title: 'New Refund Request',
          message: '$studentName requested a refund for "${event.title}".',
          iconName: 'alertCircle',
          iconColorName: 'secondary',
          actionRoute: '/refund-requests?eventId=$eventId',
        );
      }
      // Add refund to the event document itself for easier querying
      // We will also use the registrations subcollection directly to get the list
    } catch(e) {
      debugPrint('Error requesting refund: $e');
      rethrow;
    }
  }

  Future<void> processRefund(String eventId, String userId, String refundReceiptBase64) async {
    try {
      final event = getEventById(eventId);
      if (event == null) return;

      // Update registration subcollection
      final regRef = _firestore.collection('events').doc(eventId).collection('registrations').doc(userId);
      await regRef.update({
        'refundStatus': 'approved',
        'refundReceiptBase64': refundReceiptBase64,
      });

      // Update event document to remove them from registered and open up a spot
      final docRef = _firestore.collection('events').doc(eventId);
      await docRef.update({
        'registeredUserIds': FieldValue.arrayRemove([userId]),
        'availableSpots': FieldValue.increment(1),
      });

      await _createNotification(
        userId: userId,
        title: 'Refund Approved',
        message: 'Your refund request for "${event.title}" has been approved.',
        iconName: 'checkCircle',
        iconColorName: 'primary',
        actionRoute: '/event-detail/$eventId',
      );
    } catch(e) {
      debugPrint('Error processing refund: $e');
    }
  }

  
  Future<void> submitFeedback({
    required String eventId,
    required String userId,
    required double overallRating,
    required double speakerRating,
    required double venueRating,
    required double contentRating,
    required String comments,
  }) async {
    try {
      final db = _firestore;
      
      // Save review to subcollection
      await db.collection('events').doc(eventId).collection('reviews').add({
        'userId': userId,
        'overallRating': overallRating,
        'speakerRating': speakerRating,
        'venueRating': venueRating,
        'contentRating': contentRating,
        'comments': comments,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Update event average rating
      final eventRef = db.collection('events').doc(eventId);
      final eventDoc = await eventRef.get();
      if (eventDoc.exists) {
         final data = eventDoc.data()!;
         int reviewCount = data['reviewCount'] ?? 0;
         double averageRating = (data['averageRating'] ?? 0.0).toDouble();
         
         double totalRating = averageRating * reviewCount;
         totalRating += overallRating;
         reviewCount++;
         
         await eventRef.update({
           'reviewCount': reviewCount,
           'averageRating': totalRating / reviewCount,
         });
      }
    } catch (e) {
      debugPrint('Error submitting feedback: $e');
      rethrow;
    }
  }

  Future<void> registerForEvent(String eventId, String userId) async {
    try {
      final event = getEventById(eventId);
      if (event == null) return;
      
      final docRef = _firestore.collection('events').doc(eventId);
      
      if (!event.registeredUserIds.contains(userId) && event.availableSpots > 0) {
        // Optimistic update using FieldValue
        await docRef.update({
          'registeredUserIds': FieldValue.arrayUnion([userId]),
          'availableSpots': FieldValue.increment(-1),
          'registrationTimestamps': FieldValue.arrayUnion([Timestamp.now()]),
        });
        
        await NotificationService().scheduleEventReminder(eventId, event.title, event.time);
        
        await _createNotification(
          userId: userId,
          title: 'Registration Confirmed',
          message: 'You successfully registered for ${event.title}.',
          iconName: 'info',
          iconColorName: 'primary',
          actionRoute: '/event-detail/$eventId',
        );
        
        if (event.organizerId.isNotEmpty) {
          // Fetch student's name
          String studentName = 'Someone';
          try {
            final userDoc = await _firestore.collection('users').doc(userId).get();
            if (userDoc.exists) {
              studentName = userDoc.data()?['name'] ?? 'A student';
            }
          } catch (_) {}
          
          await _createNotification(
            userId: event.organizerId,
            title: 'New Participant Registered',
            message: '$studentName successfully registered for ${event.title}.',
            iconName: 'userPlus',
            iconColorName: 'secondary',
            actionRoute: '/participant-roster?eventId=$eventId',
          );
        }
      }
    } catch (e) {
      debugPrint('Error registering for event: $e');
    }
  }

  Future<void> checkInUser(String eventId, String userId) async {
    try {
      final docRef = _firestore.collection('events').doc(eventId);
      await docRef.update({
        'attendedUserIds': FieldValue.arrayUnion([userId])
      });
      
      final event = getEventById(eventId);
      if (event != null) {
        // Gamification: 10 points for free, 30 points for paid
        final points = event.price > 0 ? 30 : 10;
        await _firestore.collection('users').doc(userId).update({
          'points': FieldValue.increment(points),
          'checkIns': FieldValue.increment(1),
        });
        
        await _createNotification(
          userId: userId,
          title: 'Checked In Successfully!',
          message: 'You checked into "${event.title}" and earned $points points!',
          iconName: 'calendarCheck',
          iconColorName: 'primary',
          actionRoute: '/event-detail/$eventId',
        );
      }

    } catch (e) {
      debugPrint('Error checking in user: $e');
      rethrow;
    }
  }

  List<EventModel> getEventsByCategory(String category) {
    if (category == 'All Events') return _events;
    return _events.where((e) => e.category == category).toList();
  }

  List<EventModel> getSavedEvents(String userId) {
    return _events.where((e) => e.bookmarkedUserIds.contains(userId)).toList();
  }

  List<EventModel> getRegisteredEvents(String userId) {
    return _events.where((e) => e.registeredUserIds.contains(userId)).toList();
  }
}
