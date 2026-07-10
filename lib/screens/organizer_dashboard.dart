import 'package:flutter/material.dart';
import '../theme.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/dynamic_avatar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/user_list_sheet.dart';

class OrganizerDashboard extends StatelessWidget {
  const OrganizerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Consumer<EventProvider>(
        builder: (context, eventProvider, _) {
          final userId = context.read<AuthProvider>().firebaseUser?.uid ?? '';
          final activeEvents = eventProvider.getOrganizerActiveEvents(userId);
          final totalRegistrations = eventProvider.getOrganizerTotalRegistrations(userId);
          final events = eventProvider.getOrganizerEvents(userId);
          final liveEvents = events.where((e) => !e.date.isBefore(DateTime.now()) && !e.isEventEnded && !e.isCancelled && !e.isDraft).toList();

          return RefreshIndicator(
            displacement: 100.0,
            onRefresh: () async {
              final success = await context.read<EventProvider>().requestRefresh();
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please wait 30 seconds before refreshing again.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
              SliverAppBar(
                expandedHeight: 220.0,
                floating: false,
                pinned: true,
                backgroundColor: Theme.of(context).colorScheme.primary,
                elevation: 0,
                shape: const ContinuousRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(48),
                  ),
                ),
                automaticallyImplyLeading: false,
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: GestureDetector(
                      onTap: () => context.go('/organizer/profile'),
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
                flexibleSpace: FlexibleSpaceBar(
                  background: Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      return Container(
                        padding: const EdgeInsets.only(left: 24.0, bottom: 24.0, right: 24.0),
                        decoration: ShapeDecoration(
                          shape: const ContinuousRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(48),
                            ),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.primaryContainer,
                            ],
                          ),
                        ),
                        alignment: Alignment.bottomLeft,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Organizer Portal',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            Text(
                              'Hello, ${authProvider.userProfile?.name ?? 'Organizer'}',
                              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => context.push('/organizer/create-event'),
                              icon: const Icon(Icons.add, size: 20),
                              label: const Text('CREATE NEW EVENT'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.secondary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 24.0, top: 24.0, right: 24.0, bottom: 96.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Stats
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(context,
                                  icon: Icons.people,
                                  iconBgColor: Theme.of(context).colorScheme.tertiaryContainer,
                                  iconColor: Theme.of(context).colorScheme.tertiary,
                                  value: '${context.read<AuthProvider>().userProfile?.followers.length ?? 0}',
                                  label: 'Total\nFollowers',
                                  valueColor: Theme.of(context).colorScheme.tertiary,
                                  onTap: () {
                                    final followers = context.read<AuthProvider>().userProfile?.followers ?? [];
                                    UserListSheet.show(
                                      context,
                                      title: 'Followers',
                                      userIds: followers,
                                      emptyMessage: 'You don\'t have any followers yet.',
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(context,
                                  icon: Icons.event,
                                  iconBgColor: Theme.of(context).colorScheme.primaryContainer,
                                  iconColor: Theme.of(context).colorScheme.primary,
                                  value: '$activeEvents',
                                  label: 'Active\nEvents',
                                  valueColor: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(context,
                                  icon: Icons.how_to_reg,
                                  iconBgColor: Theme.of(context).colorScheme.secondaryContainer,
                                  iconColor: Theme.of(context).colorScheme.secondary,
                                  value: '$totalRegistrations',
                                  label: 'Total\nParticipants',
                                  valueColor: Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(context,
                                  icon: Icons.pending_actions,
                                  iconBgColor: Theme.of(context).colorScheme.errorContainer,
                                  iconColor: Theme.of(context).colorScheme.error,
                                  value: '${eventProvider.getOrganizerPendingApprovals(userId)}',
                                  label: 'Pending\nApprovals',
                                  valueColor: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Recent Activity
                      Container(
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
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            onTap: () => context.push('/notifications'),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Notifications',
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).colorScheme.outline),
                                    ],
                                  ),
                                  StreamBuilder<QuerySnapshot>(
                                    stream: context.read<NotificationProvider>().getRecentNotificationsStream(userId),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const Center(child: CircularProgressIndicator());
                                      }
                                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                        return const Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: Text("No recent activity"),
                                        );
                                      }
                                      
                                      return Column(
                                        children: snapshot.data!.docs.map((doc) {
                                          final data = doc.data() as Map<String, dynamic>;
                                          final title = data['title'] ?? '';
                                          final message = data['message'] ?? '';
                                          final iconName = data['iconName'] as String?;
                                          final iconColorName = data['iconColorName'] as String?;
                                          final timestamp = data['timestamp'] as Timestamp?;
                                          
                                          // Simple time ago
                                          String timeStr = '';
                                          if (timestamp != null) {
                                            final diff = DateTime.now().difference(timestamp.toDate());
                                            if (diff.inDays > 0) {
                                              timeStr = '${diff.inDays}d ago';
                                            } else if (diff.inHours > 0) {
                                              timeStr = '${diff.inHours}h ago';
                                            } else if (diff.inMinutes > 0) {
                                              timeStr = '${diff.inMinutes}m ago';
                                            } else {
                                              timeStr = 'Just now';
                                            }
                                          }
                                          
                                          // Simple icon
                                          IconData iconData = Icons.notifications;
                                          if (iconName == 'userPlus') {
                                            iconData = Icons.person_add;
                                          } else if (iconName == 'calendarCheck') {
                                            iconData = Icons.event_available;
                                          }
                                          
                                          Color iconColor = Theme.of(context).colorScheme.primary;
                                          Color iconBgColor = Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5);
                                          if (iconColorName == 'secondary') {
                                            iconColor = Theme.of(context).colorScheme.secondary;
                                            iconBgColor = Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.5);
                                          }
                                          
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 16.0),
                                            child: _buildActivityItem(
                                              context,
                                              icon: iconData,
                                              iconBgColor: iconBgColor,
                                              iconColor: iconColor,
                                              textSpans: [
                                                TextSpan(text: '$title: ', style: TextStyle(fontWeight: FontWeight.bold, color: iconColor)),
                                                TextSpan(text: message),
                                              ],
                                              time: timeStr,
                                            ),
                                          );
                                        }).toList(),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // My Events Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'All Events Live',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/organizer/all-live-events'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'View All',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.secondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios, size: 12, color: Theme.of(context).colorScheme.secondary),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (liveEvents.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(40),
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
                          child: Center(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.event_note, size: 48, color: Theme.of(context).colorScheme.outline),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No live events found.',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...liveEvents.take(3).map((event) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: _buildMyEventCard(context,
                              title: event.title,
                              date: '${event.date.month}/${event.date.day} - ${event.time}',
                              badge: event.isDraft ? 'Draft' : ((event.isLimitedSpots && event.availableSpots <= 0) ? 'Sold Out' : 'Live'),
                              badgeColor: event.isDraft ? Theme.of(context).colorScheme.surfaceContainerHigh : ((event.isLimitedSpots && event.availableSpots <= 0) ? Theme.of(context).colorScheme.errorContainer : Theme.of(context).colorScheme.secondaryContainer),
                              onBadgeColor: event.isDraft ? Theme.of(context).colorScheme.onSurfaceVariant : ((event.isLimitedSpots && event.availableSpots <= 0) ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.secondary),
                              hasImage: true,
                              isDraft: event.isDraft,
                              rsvps: '${event.spots - event.availableSpots} / ${event.spots} Participants',
                              onTap: () => context.push('/event-detail/${event.id}'),
                            ),
                          );
                        }),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, {
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String value,
    required String label,
    required Color valueColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, {
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required List<TextSpan> textSpans,
    required String time,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  children: textSpans,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMyEventCard(BuildContext context, {
    required String title,
    required String date,
    required String badge,
    required Color badgeColor,
    required Color onBadgeColor,
    required bool hasImage,
    bool isDraft = false,
    String? rsvps,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
                ),
                child: Stack(
                  children: [
                    if (hasImage)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
                        child: Container(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          width: double.infinity,
                          height: double.infinity,
                          child: Icon(Icons.image, size: 48, color: Theme.of(context).colorScheme.outline),
                        ),
                      )
                    else
                      Center(
                        child: Icon(Icons.image, size: 48, color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: Text(
                          badge,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: onBadgeColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Theme.of(context).colorScheme.outline),
                        const SizedBox(width: 6),
                        Text(
                          date,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (isDraft)
                          Text(
                            'Setup incomplete',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        else if (rsvps != null)
                          Row(
                            children: [
                              Icon(Icons.group, size: 16, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 6),
                              Text(
                                rsvps,
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        else
                          const SizedBox(),
                        if (isDraft)
                          TextButton(
                            onPressed: () {
                              debugPrint('Feature not implemented');
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                              ),
                            ),
                            child: Text(
                              'Edit',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
