import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:add_2_calendar/add_2_calendar.dart' as add2cal;
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/event_provider.dart';
import '../providers/auth_provider.dart';
import '../models/event_model.dart';
import '../widgets/dynamic_image.dart';

class EventDetail extends StatelessWidget {
  final String id;
  const EventDetail({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.firebaseUser?.uid ?? '';
    final isOrganizer = authProvider.userProfile?.role == 'organizer';

    EventModel event;
    try {
      event = eventProvider.events.firstWhere((e) => e.id == id);
    } catch (e) {
      return const Scaffold(body: Center(child: Text('Event not found')));
    }

    bool isRegistered = event.registeredUserIds.contains(userId);
    bool isAttended = event.attendedUserIds.contains(userId);
    
    final monthName = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][event.date.month - 1];
    final dateStr = '$monthName ${event.date.day}, ${event.date.year}';

    String statusText = 'Open';
    Color statusBgColor = Theme.of(context).colorScheme.secondaryContainer;
    Color statusTextColor = Theme.of(context).colorScheme.onSecondaryContainer;
    bool isFree = event.price == 0;

    String buttonText = 'Reserve My Seat';
    IconData buttonIcon = Icons.confirmation_num;
    String buttonRoute = isFree ? '/rsvp-confirm' : '/student-payment/${event.id}';
    bool isActionDisabled = false;

    if (event.isCancelled) {
      statusText = 'Cancelled';
      statusBgColor = Theme.of(context).colorScheme.errorContainer;
      statusTextColor = Theme.of(context).colorScheme.error;
      buttonText = 'Event Cancelled';
      buttonIcon = Icons.cancel;
      isActionDisabled = true;
    } else if (event.isEventEnded || event.date.isBefore(DateTime.now())) {
      statusText = 'Past Event';
      statusBgColor = Theme.of(context).colorScheme.surfaceContainerHighest;
      statusTextColor = Theme.of(context).colorScheme.onSurfaceVariant;
      buttonText = 'Event Ended';
      buttonIcon = Icons.event_busy;
      isActionDisabled = true;
    } else if (event.isRegistrationClosed && !isRegistered && !isAttended) {
      statusText = 'Registration Closed';
      statusBgColor = Theme.of(context).colorScheme.errorContainer;
      statusTextColor = Theme.of(context).colorScheme.error;
      buttonText = 'Registration Closed';
      buttonIcon = Icons.block;
      isActionDisabled = true;
    } else if (event.isLimitedSpots && event.availableSpots <= 0 && !isRegistered && !isAttended) {
      statusText = 'Sold Out';
      statusBgColor = Theme.of(context).colorScheme.errorContainer;
      statusTextColor = Theme.of(context).colorScheme.error;
      buttonText = 'Sold Out';
      buttonIcon = Icons.block;
      isActionDisabled = true;
    }

    if (isAttended) {
      statusText = 'Attended';
      statusBgColor = Theme.of(context).colorScheme.surfaceContainerHighest;
      statusTextColor = Theme.of(context).colorScheme.onSurfaceVariant;
      buttonText = 'View Ticket';
      buttonIcon = Icons.qr_code;
      buttonRoute = '/digital-ticket/${event.id}';
      isActionDisabled = false;
    } else if (isRegistered) {
      statusText = 'Registered';
      statusBgColor = Theme.of(context).colorScheme.secondaryContainer;
      statusTextColor = Theme.of(context).colorScheme.onSecondaryContainer;
      buttonText = 'View Ticket';
      buttonIcon = Icons.qr_code;
      buttonRoute = '/digital-ticket/${event.id}';
      isActionDisabled = false;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Image Header & Back Action
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  minHeight: MediaQuery.of(context).padding.top + 56,
                  maxHeight: 300,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'event-image-${event.id}',
                        child: event.hasValidImage
                            ? DynamicImage(
                                imageUrl: event.imageUrl,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                child: Center(
                                  child: Icon(Icons.image, size: 64, color: Theme.of(context).colorScheme.outline),
                                ),
                              ),
                      ),
                      Container(
                        color: Colors.black.withValues(alpha: 0.2),
                      ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 16,
                        child: GestureDetector(
                          onTap: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/home');
                            }
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -1,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 24,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content Canvas
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, isOrganizer ? 24 : 140),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Info
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                event.title,
                                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusBgColor,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: statusTextColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isFree ? Theme.of(context).colorScheme.secondaryContainer : Theme.of(context).colorScheme.tertiaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isFree ? 'FREE' : event.displayPrice,
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isFree ? Theme.of(context).colorScheme.onSecondaryContainer : Theme.of(context).colorScheme.onTertiaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Info Bento Grid
                        Row(
                          children: [
                            Expanded(
                              child: _buildBentoCard(context,
                                icon: Icons.calendar_month,
                                iconColor: Theme.of(context).colorScheme.onPrimaryContainer,
                                iconBgColor: Theme.of(context).colorScheme.primaryContainer,
                                label: 'DATE & TIME',
                                title: dateStr,
                                subtitle: event.time,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildBentoCard(context,
                                icon: Icons.location_on,
                                iconColor: Theme.of(context).colorScheme.onPrimaryContainer,
                                iconBgColor: Theme.of(context).colorScheme.primaryContainer,
                                label: 'VENUE',
                                title: event.location,
                                subtitle: '',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Capacity
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
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.tertiaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.group, size: 18, color: Theme.of(context).colorScheme.onTertiaryContainer),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.spots == 0 ? 'Unlimited Spots' : '${event.availableSpots} Seats Left',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      event.spots == 0 ? 'No max capacity' : 'Out of ${event.spots} capacity',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              if (event.spots > 0)
                                SizedBox(
                                  width: 48,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: event.spots > 0 ? (event.spots - event.availableSpots) / event.spots : 0,
                                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                                      minHeight: 8,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Rating & Reviews
                        if (event.reviewCount > 0)
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 24),
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
                              children: [
                                Row(
                                  children: List.generate(5, (index) {
                                    return Icon(
                                      index < event.averageRating.round() ? Icons.star : Icons.star_border,
                                      color: Colors.amber,
                                      size: 20,
                                    );
                                  }),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  event.averageRating.toStringAsFixed(1),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(${event.reviewCount} reviews)',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),

                        // About Section
                        Text(
                          'About',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          event.description.isNotEmpty ? event.description : 'No description available.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Organizer Box
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              if (!isOrganizer) {
                                context.push('/organizer-profile/${event.organizerId}');
                              }
                            },
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
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
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.school, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Organized by',
                                          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                        ),
                                        Text(
                                          event.organizerName,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  final startDate = _parseEventDateTime(event.date, event.time);
                                  final endDate = startDate.add(const Duration(hours: 2));
                                  final calEvent = add2cal.Event(
                                    title: event.title,
                                    description: event.description,
                                    location: event.location,
                                    startDate: startDate,
                                    endDate: endDate,
                                    allDay: false,
                                  );
                                  add2cal.Add2Calendar.addEvent2Cal(calEvent);
                                },
                                icon: const Icon(Icons.calendar_today, size: 18),
                                label: const Text('Add to Calendar'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  SharePlus.instance.share(ShareParams(text: 'Check out ${event.title} on Campus Event Tracker! Join me there!'));
                                },
                                icon: const Icon(Icons.share, size: 18),
                                label: const Text('Share Event'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () { context.push('/event-chat/${event.id}'); },
                                icon: const Icon(Icons.forum, size: 18),
                                label: const Text('Community Chat'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (isRegistered && !event.isEventEnded && !event.date.isBefore(DateTime.now()) && event.price > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Refund request submitted to organizer.')));
                                    },
                                    icon: const Icon(Icons.money_off, size: 18),
                                    label: const Text('Request Refund'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      foregroundColor: Colors.orange,
                                      side: const BorderSide(color: Colors.orange),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Sticky Action Footer
          if (!isOrganizer)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isAttended && (event.isEventEnded || event.date.isBefore(DateTime.now())))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () { context.push('/post-event-feedback/${event.id}'); },
                            icon: const Icon(Icons.star),
                            label: const Text('Leave a Rating', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isActionDisabled ? null : () { context.push(buttonRoute); },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isActionDisabled ? Theme.of(context).colorScheme.surfaceContainerHighest : Theme.of(context).colorScheme.secondary,
                          foregroundColor: isActionDisabled ? Theme.of(context).colorScheme.outline : Theme.of(context).colorScheme.onSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              buttonText,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(buttonIcon, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBentoCard(BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    final card = Container(
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
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: card,
      );
    }
    return card;
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
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
