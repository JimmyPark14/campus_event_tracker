import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/event_provider.dart';
import '../models/event_model.dart';
import 'package:share_plus/share_plus.dart';

class OrganizerEventDetail extends StatelessWidget {
  final String id;

  const OrganizerEventDetail({
    super.key,
    required this.id,
  });

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  DateTime _parseEventDateTime(DateTime date, String time) {
    try {
      final timeFormat = DateFormat('h:mm a');
      final parsedTime = timeFormat.parse(time.trim());
      return DateTime(date.year, date.month, date.day, parsedTime.hour, parsedTime.minute);
    } catch (e) {
      try {
        final timeFormat = DateFormat('HH:mm');
        final parsedTime = timeFormat.parse(time.trim());
        return DateTime(date.year, date.month, date.day, parsedTime.hour, parsedTime.minute);
      } catch (_) {
        return date;
      }
    }
  }

  Future<void> _confirmCancelAction(BuildContext context, String title, String content, VoidCallback onConfirm) async {
    final TextEditingController controller = TextEditingController();
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        title: Text(title, style: TextStyle(color: Theme.of(ctx).colorScheme.error, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(content, style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Type CANCEL here',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Go Back', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text == 'CANCEL') {
                Navigator.of(ctx).pop(true);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('You must type CANCEL exactly to confirm.')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error, foregroundColor: Theme.of(ctx).colorScheme.onError),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ).then((val) {
      controller.dispose();
      return val;
    });

    if (result == true) {
      onConfirm();
    }
  }

  Future<void> _confirmAction(BuildContext context, String title, String content, VoidCallback onConfirm) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        title: Text(title, style: TextStyle(color: Theme.of(ctx).colorScheme.primary, fontWeight: FontWeight.bold)),
        content: Text(content, style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (result == true) {
      onConfirm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EventProvider>(
      builder: (context, eventProvider, _) {
        final event = eventProvider.getEventById(id);
        if (event == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Event Details')),
            body: const Center(child: Text('Event not found')),
          );
        }
        final bool isPast = event.date.isBefore(DateTime.now());
        final String status = event.isDraft ? 'DRAFT' : (isPast ? 'PAST' : 'PUBLISHED');
        final Color statusColor = event.isDraft ? Theme.of(context).colorScheme.surfaceContainerHigh : (isPast ? Theme.of(context).colorScheme.outline : Theme.of(context).colorScheme.secondaryContainer);
        final Color onStatusColor = event.isDraft ? Theme.of(context).colorScheme.onSurfaceVariant : (isPast ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSecondaryContainer);
        
        final double fillPercentage = event.spots > 0 ? ((event.spots - event.availableSpots) / event.spots) : 0;
        final int fillFlex = (fillPercentage * 100).toInt();
        final int emptyFlex = 100 - fillFlex;

        final now = DateTime.now();
        final startDateTime = _parseEventDateTime(event.date, event.time);
        final bool isEditLocked = now.isAfter(startDateTime.subtract(const Duration(hours: 1)));

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Event Details',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(
                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                height: 1.0,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.all(24),
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              status,
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: onStatusColor,
                                fontSize: 10,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'ID: ${event.id}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        event.title,
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 28,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.calendar_month, size: 20, color: Theme.of(context).colorScheme.outline),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_getMonthName(event.date.month)} ${event.date.day}, ${event.date.year} • ${event.time}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on, size: 20, color: Theme.of(context).colorScheme.outline),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final query = Uri.encodeComponent(event.location);
                                final googleUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
                                if (await canLaunchUrl(googleUrl)) {
                                  await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
                                }
                              },
                              child: Text(
                                event.location,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          OutlinedButton.icon(
                            onPressed: isEditLocked ? null : () => context.push('/organizer/edit-event/${event.id}'),
                            icon: const Icon(Icons.edit, size: 18),
                            label: Text(isEditLocked ? 'Edit Locked' : 'Edit Event'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.onSurface,
                              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                              side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ).copyWith(
                              foregroundColor: WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.disabled)) {
                                  return Theme.of(context).colorScheme.outline;
                                }
                                return Theme.of(context).colorScheme.onSurface;
                              }),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              SharePlus.instance.share(ShareParams(text: 'Check out ${event.title} on Campus Event Tracker! Join me there!'));
                            },
                            icon: const Icon(Icons.share, size: 18),
                            label: const Text('Share'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Management Actions Panel
                Container(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Management Actions',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildActionItem(context,
                        icon: Icons.group,
                        iconColor: Theme.of(context).colorScheme.primary,
                        iconBgColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                        title: 'View Roster',
                        subtitle: 'Manage attendees',
                        onTap: () => context.push('/participant-roster?eventId=${event.id}'),
                      ),
                      const SizedBox(height: 8),
                      _buildActionItem(context,
                        icon: Icons.how_to_reg,
                        iconColor: Theme.of(context).colorScheme.secondary,
                        iconBgColor: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
                        title: 'Check-in Attendance',
                        subtitle: 'Scan QR or manual entry',
                        onTap: () => context.push('/attendance-checklist?eventId=${event.id}'),
                      ),
                      const SizedBox(height: 8),
                      _buildActionItem(context,
                        icon: Icons.insights,
                        iconColor: Theme.of(context).colorScheme.tertiary,
                        iconBgColor: Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                        title: 'View Analytics',
                        subtitle: 'Engagement metrics',
                        onTap: () => context.push('/event-analytics/$id'),
                      ),
                      const SizedBox(height: 8),
                      _buildActionItem(context,
                        icon: Icons.fact_check,
                        iconColor: Colors.orange,
                        iconBgColor: Colors.orange.withValues(alpha: 0.1),
                        title: 'Verify Payments',
                        subtitle: 'Approve or reject student payments',
                        onTap: () => context.push('/payment-verify?eventId=${event.id}'),
                      ),
                      const SizedBox(height: 8),
                      _buildActionItem(context,
                        icon: Icons.money_off,
                        iconColor: Colors.red,
                        iconBgColor: Colors.red.withValues(alpha: 0.1),
                        title: 'Refund Requests',
                        subtitle: 'Process student refund requests',
                        onTap: () => context.push('/refund-requests?eventId=${event.id}'),
                      ),
                      const SizedBox(height: 8),
                      _buildActionItem(context,
                        icon: Icons.assignment_turned_in,
                        iconColor: Theme.of(context).colorScheme.error,
                        iconBgColor: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                        title: 'End Check-in',
                        subtitle: 'Close attendance scanning',
                        isDisabled: event.isCancelled || event.isEventEnded || event.isCheckInClosed || event.date.isBefore(DateTime.now()),
                        onTap: () {
                          _confirmAction(context, 'End Check-in', 'Are you sure you want to end check-in for this event? This action cannot be undone.', () async {
                            final newEvent = EventModel(
                              id: event.id, title: event.title, organizerId: event.organizerId, organizerName: event.organizerName, date: event.date, time: event.time, location: event.location, category: event.category, spots: event.spots, availableSpots: event.availableSpots, imageUrl: event.imageUrl, price: event.price, description: event.description, isPublic: event.isPublic, isDraft: event.isDraft, targetAudience: event.targetAudience, registrationTimestamps: event.registrationTimestamps, autoCloseRegistration: event.autoCloseRegistration, autoCloseRegistrationTime: event.autoCloseRegistrationTime, autoEndCheckIn: event.autoEndCheckIn, autoEndCheckInTime: event.autoEndCheckInTime, autoEndEvent: event.autoEndEvent, autoEndEventTime: event.autoEndEventTime, registeredUserIds: event.registeredUserIds, attendedUserIds: event.attendedUserIds, bookmarkedUserIds: event.bookmarkedUserIds, pendingUserIds: event.pendingUserIds, averageRating: event.averageRating, reviewCount: event.reviewCount, isTrendingFlag: event.isTrending, isLimitedSpotsFlag: event.isLimitedSpots,
                              isCheckInClosed: true, isRegistrationClosed: event.isRegistrationClosed, isEventEnded: event.isEventEnded, isCancelled: event.isCancelled,
                            );
                            await context.read<EventProvider>().updateEvent(
                              event.id, 
                              newEvent, 
                              actionTitle: 'Check-in Closed', 
                              actionMessage: 'You successfully ended check-in for "${event.title}".'
                            );
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check-in ended.')));
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildActionItem(context,
                        icon: Icons.block,
                        iconColor: Theme.of(context).colorScheme.error,
                        iconBgColor: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                        title: 'Close Registration',
                        subtitle: 'Stop new sign-ups',
                        isDisabled: event.isCancelled || event.isEventEnded || event.isRegistrationClosed || event.date.isBefore(DateTime.now()),
                        onTap: () {
                          _confirmAction(context, 'Close Registration', 'Are you sure you want to close registrations? No more students will be able to join.', () async {
                            final newEvent = EventModel(
                              id: event.id, title: event.title, organizerId: event.organizerId, organizerName: event.organizerName, date: event.date, time: event.time, location: event.location, category: event.category, spots: event.spots, availableSpots: event.availableSpots, imageUrl: event.imageUrl, price: event.price, description: event.description, isPublic: event.isPublic, isDraft: event.isDraft, targetAudience: event.targetAudience, registrationTimestamps: event.registrationTimestamps, autoCloseRegistration: event.autoCloseRegistration, autoCloseRegistrationTime: event.autoCloseRegistrationTime, autoEndCheckIn: event.autoEndCheckIn, autoEndCheckInTime: event.autoEndCheckInTime, autoEndEvent: event.autoEndEvent, autoEndEventTime: event.autoEndEventTime, registeredUserIds: event.registeredUserIds, attendedUserIds: event.attendedUserIds, bookmarkedUserIds: event.bookmarkedUserIds, pendingUserIds: event.pendingUserIds, averageRating: event.averageRating, reviewCount: event.reviewCount, isTrendingFlag: event.isTrending, isLimitedSpotsFlag: event.isLimitedSpots,
                              isCheckInClosed: event.isCheckInClosed, isRegistrationClosed: true, isEventEnded: event.isEventEnded, isCancelled: event.isCancelled,
                            );
                            await context.read<EventProvider>().updateEvent(
                              event.id, 
                              newEvent, 
                              actionTitle: 'Registration Closed', 
                              actionMessage: 'You successfully closed registration for "${event.title}".'
                            );
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event registrations closed.')));
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildActionItem(context,
                        icon: Icons.event_busy,
                        iconColor: Theme.of(context).colorScheme.error,
                        iconBgColor: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                        title: 'End Event',
                        subtitle: 'Mark event as completed',
                        isDisabled: event.isCancelled || event.isEventEnded || event.date.isBefore(DateTime.now()),
                        onTap: () {
                          _confirmAction(context, 'End Event', 'Are you sure you want to end this event early? It will be marked as completed.', () async {
                            final newEvent = EventModel(
                              id: event.id, title: event.title, organizerId: event.organizerId, organizerName: event.organizerName, date: event.date, time: event.time, location: event.location, category: event.category, spots: event.spots, availableSpots: event.availableSpots, imageUrl: event.imageUrl, price: event.price, description: event.description, isPublic: event.isPublic, isDraft: event.isDraft, targetAudience: event.targetAudience, registrationTimestamps: event.registrationTimestamps, autoCloseRegistration: event.autoCloseRegistration, autoCloseRegistrationTime: event.autoCloseRegistrationTime, autoEndCheckIn: event.autoEndCheckIn, autoEndCheckInTime: event.autoEndCheckInTime, autoEndEvent: event.autoEndEvent, autoEndEventTime: event.autoEndEventTime, registeredUserIds: event.registeredUserIds, attendedUserIds: event.attendedUserIds, bookmarkedUserIds: event.bookmarkedUserIds, pendingUserIds: event.pendingUserIds, averageRating: event.averageRating, reviewCount: event.reviewCount, isTrendingFlag: event.isTrending, isLimitedSpotsFlag: event.isLimitedSpots,
                              isCheckInClosed: event.isCheckInClosed, isRegistrationClosed: event.isRegistrationClosed, isEventEnded: true, isCancelled: event.isCancelled,
                            );
                            await context.read<EventProvider>().updateEvent(
                              event.id, 
                              newEvent, 
                              actionTitle: 'Event Ended', 
                              actionMessage: 'You successfully marked the event "${event.title}" as completed.'
                            );
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event marked as completed.')));
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildActionItem(context,
                        icon: Icons.cancel,
                        iconColor: Theme.of(context).colorScheme.error,
                        iconBgColor: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                        title: 'Cancel Event',
                        subtitle: 'Revoke and delete event',
                        isDisabled: event.isCancelled || event.isEventEnded || event.date.isBefore(DateTime.now()),
                        onTap: () {
                          _confirmCancelAction(context, 'Cancel Event', 'Are you sure you want to completely cancel and delete this event? This action is permanent.', () async {
                            final newEvent = EventModel(
                              id: event.id, title: event.title, organizerId: event.organizerId, organizerName: event.organizerName, date: event.date, time: event.time, location: event.location, category: event.category, spots: event.spots, availableSpots: event.availableSpots, imageUrl: event.imageUrl, price: event.price, description: event.description, isPublic: event.isPublic, isDraft: event.isDraft, targetAudience: event.targetAudience, registrationTimestamps: event.registrationTimestamps, autoCloseRegistration: event.autoCloseRegistration, autoCloseRegistrationTime: event.autoCloseRegistrationTime, autoEndCheckIn: event.autoEndCheckIn, autoEndCheckInTime: event.autoEndCheckInTime, autoEndEvent: event.autoEndEvent, autoEndEventTime: event.autoEndEventTime, registeredUserIds: event.registeredUserIds, attendedUserIds: event.attendedUserIds, bookmarkedUserIds: event.bookmarkedUserIds, pendingUserIds: event.pendingUserIds, averageRating: event.averageRating, reviewCount: event.reviewCount, isTrendingFlag: event.isTrending, isLimitedSpotsFlag: event.isLimitedSpots,
                              isCheckInClosed: event.isCheckInClosed, isRegistrationClosed: event.isRegistrationClosed, isEventEnded: event.isEventEnded, isCancelled: true,
                            );
                            await context.read<EventProvider>().updateEvent(
                              event.id, 
                              newEvent, 
                              actionTitle: 'Event Cancelled', 
                              actionMessage: 'You successfully cancelled the event "${event.title}".'
                            );
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event cancelled.')));
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Status & Metrics Card
                Container(
                  padding: const EdgeInsets.all(24),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Registration Overview',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              context.push('/export-data?eventId=${event.id}');
                            },
                            child: Row(
                              children: [
                                Icon(Icons.download, size: 16, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Export',
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetric(context,
                              value: '${event.spots - event.availableSpots}',
                              label: 'Total Participants',
                              valueColor: Theme.of(context).colorScheme.primary,
                              bgColor: Theme.of(context).colorScheme.surfaceContainerLow,
                              borderColor: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildMetric(context,
                              value: '$fillFlex%',
                              label: 'Capacity Filled',
                              valueColor: Theme.of(context).colorScheme.secondary,
                              bgColor: Theme.of(context).colorScheme.surfaceContainerLow,
                              borderColor: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (event.price > 0 || event.pendingUserIds.isNotEmpty) ...[
                            Expanded(
                              child: _buildMetric(context,
                                value: '${event.pendingUserIds.length}',
                                label: 'Pending Approvals',
                                valueColor: Theme.of(context).colorScheme.error,
                                bgColor: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                                borderColor: Theme.of(context).colorScheme.error.withValues(alpha: 0.2),
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          Expanded(
                            child: _buildMetric(context,
                              value: '${event.spots}',
                              label: 'Max Capacity',
                              valueColor: Theme.of(context).colorScheme.onSurface,
                              bgColor: Theme.of(context).colorScheme.surfaceContainerLow,
                              borderColor: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Registration Progress',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            '${event.spots - event.availableSpots} / ${event.spots}',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            if (fillFlex > 0)
                              Expanded(
                                flex: fillFlex,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.secondary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            if (emptyFlex > 0)
                              Expanded(flex: emptyFlex, child: const SizedBox()),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Only ${event.availableSpots} spots remaining',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionItem(BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.transparent),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDisabled ? Theme.of(context).colorScheme.surfaceContainerHighest : iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: isDisabled ? Theme.of(context).colorScheme.outline : iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isDisabled ? Theme.of(context).colorScheme.outline : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(BuildContext context, {
    required String value,
    required String label,
    required Color valueColor,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
