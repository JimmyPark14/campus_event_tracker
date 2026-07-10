import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class UserCacheProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, UserProfile> _cache = {};

  UserProfile? getUser(String uid) {
    return _cache[uid];
  }

  Future<UserProfile?> fetchUser(String uid) async {
    if (_cache.containsKey(uid)) {
      return _cache[uid];
    }
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final profile = UserProfile.fromFirestore(doc);
        _cache[uid] = profile;
        notifyListeners(); // Notify listeners that a new user was cached
        return profile;
      }
    } catch (e) {
      debugPrint('Error fetching user for cache: $e');
    }
    return null;
  }
}
