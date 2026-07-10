import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../providers/auth_provider.dart';
import 'dynamic_avatar.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userProfile = authProvider.userProfile;
    final isOrganizer = userProfile?.role == 'organizer';

    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            accountName: Text(
              userProfile?.name ?? 'Loading...',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(userProfile?.email ?? 'Loading...'),
            currentAccountPicture: DynamicAvatar(
              name: userProfile?.name,
              avatarUrl: userProfile?.avatarUrl,
              radius: 36,
              fontSize: 32,
            ),
          ),
          ListTile(
            leading: Icon(Icons.person_outline, color: Theme.of(context).colorScheme.onSurfaceVariant),
            title: const Text('Profile Settings'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              context.go(isOrganizer ? '/organizer-profile' : '/profile');
            },
          ),
          ListTile(
            leading: Icon(Icons.security_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
            title: const Text('Privacy & Security'),
            onTap: () {
              Navigator.pop(context);
              context.push(isOrganizer ? '/organizer-profile/privacy' : '/profile/privacy');
            },
          ),
          ListTile(
            leading: Icon(Icons.help_outline, color: Theme.of(context).colorScheme.onSurfaceVariant),
            title: const Text('Help & Support'),
            onTap: () {
              Navigator.pop(context);
              context.push(isOrganizer ? '/organizer-profile/support' : '/profile/support');
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            title: Text('Sign Out', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                context.go('/');
              }
            },
          ),
        ],
      ),
    );
  }
}
