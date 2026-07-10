import 'package:cloud_firestore/cloud_firestore.dart';

class TeamMember {
  final String id;
  final String name;
  final String role;
  final String email;
  final bool isAdmin;

  TeamMember({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    required this.isAdmin,
  });

  factory TeamMember.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TeamMember(
      id: doc.id,
      name: data['name'] ?? '',
      role: data['role'] ?? '',
      email: data['email'] ?? '',
      isAdmin: data['isAdmin'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'role': role,
      'email': email,
      'isAdmin': isAdmin,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
