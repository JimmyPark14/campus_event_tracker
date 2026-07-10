import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team_member.dart';

class TeamProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getTeamMembersStream(String organizerId) {
    return _firestore
        .collection('users')
        .doc(organizerId)
        .collection('team_members')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> addTeamMember(String organizerId, TeamMember member) async {
    try {
      await _firestore
          .collection('users')
          .doc(organizerId)
          .collection('team_members')
          .add(member.toFirestore());
    } catch (e) {
      debugPrint('Error adding team member: $e');
      rethrow;
    }
  }

  Future<void> removeTeamMember(String organizerId, String memberId) async {
    try {
      await _firestore
          .collection('users')
          .doc(organizerId)
          .collection('team_members')
          .doc(memberId)
          .delete();
    } catch (e) {
      debugPrint('Error removing team member: $e');
      rethrow;
    }
  }
}
