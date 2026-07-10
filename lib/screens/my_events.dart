import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../providers/auth_provider.dart';
import '../models/event_model.dart';
import '../widgets/dynamic_avatar.dart';

class MyEvents extends StatefulWidget {
  const MyEvents({super.key});

  @override
  State<MyEvents> createState() => _MyEventsState();
}

class _MyEventsState extends State<MyEvents> {
  String _activeFilter = 'All'; // 'All', 'Registered', 'Attended'

  String _getMonthName(int month) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final userId = context.read<AuthProvider>().firebaseUser?.uid ?? '';
    final allEvents = eventProvider.events;

    final registeredEvents = allEvents.where((e) => e.registeredUserIds.contains(userId)).toList();
    final attendedEvents = allEvents.where((e) => e.attendedUserIds.contains(userId)).toList();
    
    // Combine them with status
    final List<Map<String, dynamic>> myEvents = [];
    for (var e in registeredEvents) {
      if (!e.attendedUserIds.contains(userId)) {
        String status = 'Registered';
        if (e.isCancelled) {
          status = e.price > 0 ? 'Refunded' : 'Cancelled';
        } else if (e.isEventEnded || e.date.isBefore(DateTime.now())) {
          status = 'Missed';
        }
        myEvents.add({
          'event': e,
          'status': status,
        });
      }
    }
    for (var e in attendedEvents) {
      myEvents.add({
        'event': e,
        'status': 'Attended',
      });
    }

    // Filter events
    final filteredEvents = myEvents.where((item) {
      if (_activeFilter == 'All') return true;
      return item['status'] == _activeFilter;
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        automaticallyImplyLeading: false,
        title: Text(
          'Campus Events',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                context.go('/profile');
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
      body: RefreshIndicator(
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
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Text(
              'My Activity',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              'Track your campus engagement',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Stats Grid
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${registeredEvents.length}',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'REGISTERED',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF166B66).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF166B66).withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${attendedEvents.length}',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: const Color(0xFF166B66),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ATTENDED',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _activeFilter == 'All' ? 'Your Events' : '$_activeFilter Events',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.filter_list, size: 24, color: Theme.of(context).colorScheme.secondary),
                  onSelected: (value) {
                    setState(() {
                      _activeFilter = value;
                    });
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'All',
                      child: Text('All Events'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'Registered',
                      child: Text('Registered Only'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'Attended',
                      child: Text('Attended Only'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Event Cards
            filteredEvents.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'No events found',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: List.generate(filteredEvents.length, (index) {
                      final item = filteredEvents[index];
                      final EventModel event = item['event'];
                      final status = item['status'];
                      
                      final month = _getMonthName(event.date.month);
                      final day = event.date.day.toString();

                      final isActive = status == 'Registered';
                      final badgeText = status;
                      
                      Color badgeColor = Theme.of(context).colorScheme.surfaceContainerHighest;
                      Color onBadgeColor = Theme.of(context).colorScheme.onSurfaceVariant;
                      IconData? badgeIcon;
                      
                      if (isActive) {
                        badgeColor = Theme.of(context).colorScheme.secondaryContainer;
                        onBadgeColor = Theme.of(context).colorScheme.onSecondaryContainer;
                      } else if (status == 'Attended') {
                        badgeIcon = Icons.check_circle;
                      } else if (status == 'Cancelled' || status == 'Refunded' || status == 'Missed') {
                        badgeColor = Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.5);
                        onBadgeColor = Theme.of(context).colorScheme.error;
                        badgeIcon = Icons.cancel;
                      }
                      
                      return Padding(
                        padding: EdgeInsets.only(bottom: index == filteredEvents.length - 1 ? 0 : 16.0),
                        child: _buildEventCard(
                          context: context,
                          id: event.id,
                          month: month,
                          day: day,
                          title: event.title,
                          location: event.location,
                          badgeText: badgeText,
                          badgeColor: badgeColor,
                          onBadgeColor: onBadgeColor,
                          badgeIcon: badgeIcon,
                          isActive: isActive,
                        ),
                      );
                    }),
                  ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildEventCard({
    required BuildContext context,
    required String id,
    required String month,
    required String day,
    required String title,
    required String location,
    required String badgeText,
    required Color badgeColor,
    required Color onBadgeColor,
    Color? badgeBorderColor,
    IconData? badgeIcon,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () {
        context.push('/event-detail/$id');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.surfaceContainerLowest.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Colors.transparent : Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isActive ? Theme.of(context).colorScheme.surfaceContainerLow : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    month,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    day,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isActive ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(16),
                border: badgeBorderColor != null ? Border.all(color: badgeBorderColor) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (badgeIcon != null) ...[
                    Icon(badgeIcon, size: 12, color: onBadgeColor),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    badgeText,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: onBadgeColor,
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
