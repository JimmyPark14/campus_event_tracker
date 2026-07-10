import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../models/user_profile.dart';
import 'dynamic_avatar.dart';

class UserListSheet extends StatelessWidget {
  final String title;
  final List<String> userIds;
  final String emptyMessage;

  const UserListSheet({
    super.key,
    required this.title,
    required this.userIds,
    required this.emptyMessage,
  });

  Future<List<UserProfile>> _fetchUsers() async {
    if (userIds.isEmpty) return [];
    
    List<UserProfile> users = [];
    // Fetch users in parallel
    final snapshots = await Future.wait(
      userIds.map((id) => FirebaseFirestore.instance.collection('users').doc(id).get())
    );
    
    for (var doc in snapshots) {
      if (doc.exists) {
        users.add(UserProfile.fromFirestore(doc));
      }
    }
    return users;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Divider(),
          Flexible(
            child: userIds.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      emptyMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  )
                : FutureBuilder<List<UserProfile>>(
                    future: _fetchUsers(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        );
                      }
                      
                      if (snapshot.hasError || !snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text('Error loading users.'),
                        );
                      }
                      
                      final users = snapshot.data!;
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return ListTile(
                            leading: DynamicAvatar(name: user.name, avatarUrl: user.avatarUrl, radius: 20),
                            title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(user.role == 'organizer' ? 'Organizer' : 'Student'),
                            onTap: () {
                              Navigator.pop(context); // Close the sheet
                              if (user.role == 'organizer') {
                                // Navigate to organizer profile if they are an organizer
                                context.push('/event-detail/organizer/${user.uid}');
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      ),
    );
  }

  static void show(BuildContext context, {required String title, required List<String> userIds, required String emptyMessage}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          // Wrapping inside a SingleChildScrollView is not strictly necessary 
          // because UserListSheet handles scrolling in its ListView, but we pass the bounds.
          return UserListSheet(title: title, userIds: userIds, emptyMessage: emptyMessage);
        },
      ),
    );
  }
}
