import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String name;
  final String role; // 'student' or 'organizer'
  final String major;
  final int points;
  final String avatarUrl;
  final String phone;
  final Map<String, dynamic> preferences;
  final String duitNowQrBase64;
  final String bankAccountName;
  final double balance;
  final bool isPhoneVerified;
  final bool isEmailVerified;
  final String bio;
  final double rating;
  final List<String> following;
  final List<String> followers;

  UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.major = '',
    this.points = 0,
    this.avatarUrl = '',
    this.phone = '',
    this.preferences = const {},
    this.duitNowQrBase64 = '',
    this.bankAccountName = '',
    this.balance = 0.0,
    this.isPhoneVerified = false,
    this.isEmailVerified = false,
    this.bio = '',
    this.rating = 0.0,
    this.following = const [],
    this.followers = const [],
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'student',
      major: data['major'] ?? '',
      points: data['points'] ?? 0,
      avatarUrl: data['avatarUrl'] ?? '',
      phone: data['phone'] ?? '',
      preferences: data['preferences'] ?? {},
      duitNowQrBase64: data['duitNowQrBase64'] ?? '',
      bankAccountName: data['bankAccountName'] ?? '',
      balance: (data['balance'] ?? 0.0).toDouble(),
      isPhoneVerified: data['isPhoneVerified'] ?? false,
      isEmailVerified: data['isEmailVerified'] ?? false,
      bio: data['bio'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      following: List<String>.from(data['following'] ?? []),
      followers: List<String>.from(data['followers'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'email': email,
      'name': name,
      'role': role,
      'avatarUrl': avatarUrl,
      'phone': phone,
      'preferences': preferences,
      'duitNowQrBase64': duitNowQrBase64,
      'bankAccountName': bankAccountName,
      'balance': balance,
      'isPhoneVerified': isPhoneVerified,
      'isEmailVerified': isEmailVerified,
      'bio': bio,
      'rating': rating,
      'following': following,
      'followers': followers,
    };

    map['major'] = major;

    if (role != 'organizer') {
      map['points'] = points;
    }

    return map;
  }
}
