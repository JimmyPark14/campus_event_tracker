import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _firebaseUser;
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _verificationId;

  bool _initialized = false;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _firebaseUser = _auth.currentUser;
    if (_firebaseUser != null) {
      await _fetchUserProfile(_firebaseUser!.uid);
    }
    _initialized = true;
  }

  User? get firebaseUser => _firebaseUser;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _firebaseUser != null;

  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;
    if (user != null) {
      await _fetchUserProfile(user.uid);
    } else {
      _userProfile = null;
    }
    notifyListeners();
  }

  Future<void> _fetchUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _userProfile = UserProfile.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
  }

  Future<void> reloadProfile() async {
    if (_firebaseUser != null) {
      await _fetchUserProfile(_firebaseUser!.uid);
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password, String name, String role, {String phone = '', String major = '', String bio = ''}) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create profile in Firestore
      if (credential.user != null) {
        UserProfile newProfile = UserProfile(
          uid: credential.user!.uid,
          email: email,
          name: name,
          role: role,
          major: major,
          phone: phone,
          bio: bio,
        );
        await _firestore.collection('users').doc(credential.user!.uid).set(newProfile.toFirestore());
        _userProfile = newProfile;
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _firebaseUser = null;
    _userProfile = null;
    notifyListeners();
  }

  Future<void> toggleFollowOrganizer(String organizerId) async {
    if (_firebaseUser == null || _userProfile == null) return;
    
    final isFollowing = _userProfile!.following.contains(organizerId);
    List<String> updatedFollowing = List.from(_userProfile!.following);
    
    if (isFollowing) {
      updatedFollowing.remove(organizerId);
    } else {
      updatedFollowing.add(organizerId);
    }
    
    try {
      final batch = _firestore.batch();
      
      // Update current user's following list
      batch.update(_firestore.collection('users').doc(_firebaseUser!.uid), {
        'following': updatedFollowing,
      });

      // Update target organizer's followers list
      batch.update(_firestore.collection('users').doc(organizerId), {
        'followers': isFollowing 
            ? FieldValue.arrayRemove([_firebaseUser!.uid])
            : FieldValue.arrayUnion([_firebaseUser!.uid]),
      });

      // Send Notification to organizer if newly followed
      if (!isFollowing) {
        batch.set(_firestore.collection('users').doc(organizerId).collection('notifications').doc(), {
          'title': 'New Follower',
          'message': '${_userProfile!.name} started following your organization!',
          'iconName': 'userPlus',
          'iconColorName': 'primary',
          'actionRoute': null, // Optionally route to the student's profile later
          'isUnread': true,
          'section': 'New',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      await reloadProfile();
    } catch (e) {
      debugPrint('Error toggling follow: $e');
      rethrow;
    }
  }

  Future<void> sendPhoneVerification(String phoneNumber, {required Function(String) onCodeSent, required Function(String) onError}) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            if (_firebaseUser != null) {
              await _firebaseUser!.linkWithCredential(credential);
              await _markPhoneVerified();
            }
          } catch (e) {
            onError(e.toString());
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'Verification failed');
          _isLoading = false;
          notifyListeners();
        },
        codeSent: (String verId, int? resendToken) {
          _verificationId = verId;
          onCodeSent(verId);
          _isLoading = false;
          notifyListeners();
        },
        codeAutoRetrievalTimeout: (String verId) {
          _verificationId = verId;
        },
      );
    } catch (e) {
      onError(e.toString());
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> confirmSmsCode(String smsCode) async {
    if (_verificationId == null || _firebaseUser == null) throw Exception('No verification session or user not logged in');
    try {
      _isLoading = true;
      notifyListeners();
      
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      
      await _firebaseUser!.linkWithCredential(credential);
      await _markPhoneVerified();
      
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _markPhoneVerified() async {
    if (_firebaseUser != null) {
      await _firestore.collection('users').doc(_firebaseUser!.uid).update({
        'isPhoneVerified': true,
      });
      await reloadProfile();
    }
  }

  Future<void> sendEmailVerification() async {
    if (_firebaseUser != null && !_firebaseUser!.emailVerified) {
      try {
        _isLoading = true;
        notifyListeners();
        await _firebaseUser!.sendEmailVerification();
      } catch (e) {
        rethrow;
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> checkEmailVerified() async {
    if (_firebaseUser != null) {
      try {
        _isLoading = true;
        notifyListeners();
        await _firebaseUser!.reload();
        _firebaseUser = _auth.currentUser;
        if (_firebaseUser!.emailVerified) {
          await _markEmailVerified();
          return true;
        }
      } catch (e) {
        rethrow;
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
    return false;
  }

  Future<void> _markEmailVerified() async {
    if (_firebaseUser != null) {
      await _firestore.collection('users').doc(_firebaseUser!.uid).update({
        'isEmailVerified': true,
      });
      await reloadProfile();
    }
  }
}
