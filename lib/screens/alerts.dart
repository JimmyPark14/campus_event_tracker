import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import '../widgets/dynamic_avatar.dart';
import '../providers/notification_provider.dart';

final ValueNotifier<bool> globalHasUnreadNotifications = ValueNotifier<bool>(false);

class Alerts extends StatefulWidget {
  const Alerts({super.key});

  @override
  State<Alerts> createState() => _AlertsState();
}

class _AlertsState extends State<Alerts> {
  String _getTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final difference = now.difference(timestamp.toDate());

    if (difference.inDays > 1) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'min' : 'mins'} ago';
    } else {
      return 'Just now';
    }
  }

  IconData _getIconFromName(String? iconName) {
    switch (iconName) {
      case 'userPlus':
        return LucideIcons.userPlus;
      case 'alertCircle':
        return LucideIcons.alertCircle;
      case 'info':
        return LucideIcons.info;
      case 'calendarCheck':
        return LucideIcons.calendarCheck;
      case 'bookmark':
        return LucideIcons.bookmark;
      default:
        return LucideIcons.bell;
    }
  }

  Future<void> _markAllAsRead(String uid) async {
    await context.read<NotificationProvider>().markAllAsRead(uid);
    globalHasUnreadNotifications.value = false;

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showNotificationDetails(Map<String, dynamic> data, String docId, String uid) async {
    if (data['isUnread'] == true) {
      await context.read<NotificationProvider>().markAsRead(uid, docId);
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(_getIconFromName(data['iconName']), color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(data['title'] ?? '')),
              ],
            ),
            content: Text(data['message'] ?? ''),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              if (data['actionRoute'] != null && data['actionRoute'].toString().isNotEmpty)
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push(data['actionRoute']);
                  },
                  child: const Text('View'),
                ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.firebaseUser;
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Not logged in')),
      );
    }

    Color getColorFromName(String name) {
      switch (name) {
        case 'secondary':
          return colorScheme.secondary;
        case 'error':
          return colorScheme.error;
        case 'primary':
        default:
          return colorScheme.primary;
      }
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        automaticallyImplyLeading: false,
        leading: context.canPop() ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ) : null,
        title: Text(
          'Campus Events',
          style: textTheme.headlineMedium?.copyWith(
            color: colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.checkCheck),
            tooltip: 'Mark all as read',
            onPressed: () => _markAllAsRead(user.uid),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                final role = authProvider.userProfile?.role;
                if (role == 'organizer') {
                  context.push('/organizer/profile');
                } else {
                  context.go('/profile');
                }
              },
              child: Consumer<AuthProvider>(
                builder: (context, auth, _) => DynamicAvatar(
                  name: auth.userProfile?.name,
                  avatarUrl: auth.userProfile?.avatarUrl,
                  radius: 18,
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: context.read<NotificationProvider>().getNotificationsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          
          final newNotifications = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return data['section'] == 'New' || data['isUnread'] == true;
          }).toList();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (globalHasUnreadNotifications.value != newNotifications.isNotEmpty) {
              globalHasUnreadNotifications.value = newNotifications.isNotEmpty;
            }
          });
          
          final earlierNotifications = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return data['section'] == 'Earlier' || data['isUnread'] == false;
          }).toList();

          final headerWidget = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications',
                style: textTheme.displaySmall?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
              Text(
                'Stay updated with your campus events',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
            ],
          );

          if (docs.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                headerWidget,
                const SizedBox(height: 64),
                Center(
                  child: Text(
                    'No notifications yet',
                    style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              headerWidget,
              if (newNotifications.isNotEmpty) ...[
                Text(
                  'New',
                  style: textTheme.titleSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                ...newNotifications.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildNotificationItem(
                    context: context,
                    docId: doc.id,
                    uid: user.uid,
                    data: data,
                    iconColor: getColorFromName(data['iconColorName'] ?? 'primary'),
                  );
                }),
                const SizedBox(height: 16),
              ],
              if (earlierNotifications.isNotEmpty) ...[
                Text(
                  'Earlier',
                  style: textTheme.titleSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                ...earlierNotifications.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildNotificationItem(
                    context: context,
                    docId: doc.id,
                    uid: user.uid,
                    data: data,
                    iconColor: getColorFromName(data['iconColorName'] ?? 'primary'),
                  );
                }),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem({
    required BuildContext context,
    required String docId,
    required String uid,
    required Map<String, dynamic> data,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final bool isUnread = data['isUnread'] ?? false;
    final String title = data['title'] ?? 'Notification';
    final String message = data['message'] ?? '';
    final String time = _getTimeAgo(data['timestamp'] as Timestamp?);
    final IconData icon = _getIconFromName(data['iconName'] as String?);
    
    return GestureDetector(
      onTap: () => _showNotificationDetails(data, docId, uid),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        time,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
