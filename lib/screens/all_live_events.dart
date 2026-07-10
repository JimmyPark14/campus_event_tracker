import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../providers/auth_provider.dart';
import '../models/event_model.dart';
import '../widgets/dynamic_avatar.dart';
import '../widgets/dynamic_image.dart';

class AllLiveEventsScreen extends StatefulWidget {
  const AllLiveEventsScreen({super.key});

  @override
  State<AllLiveEventsScreen> createState() => _AllLiveEventsScreenState();
}

class _AllLiveEventsScreenState extends State<AllLiveEventsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final userId = context.read<AuthProvider>().firebaseUser?.uid ?? '';
    final allEvents = eventProvider.events;

    // Filter events to only show live events (not past)
    final liveEvents = allEvents.where((e) => e.date.isAfter(DateTime.now().subtract(const Duration(days: 1)))).toList();
    
    final filteredEvents = liveEvents.where((event) {
      return event.title.toLowerCase().contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'All Events Live',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return DynamicAvatar(
                  name: authProvider.userProfile?.name ?? 'User',
                  radius: 16,
                  fontSize: 14,
                );
              },
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
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Search live events...',
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainer,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
                  ),
                ),
              ),
            ),
            
            // Event Feed
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: eventProvider.isLoading && filteredEvents.isEmpty
                  ? Column(
                      children: List.generate(3, (index) => _buildSkeletonCard(context)),
                    )
                  : filteredEvents.isEmpty
                      ? _buildEmptyState(context)
                  : Column(
                      children: List.generate(filteredEvents.length, (index) {
                        final event = filteredEvents[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: index == filteredEvents.length - 1 ? 0 : 24.0),
                          child: _buildEventCard(
                            context: context,
                            event: event,
                            index: index,
                            userId: userId,
                          ),
                        );
                      }),
                    ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildEventCard({
    required BuildContext context,
    required EventModel event,
    required int index,
    required String userId,
  }) {
    final badgeColor = event.isTrending ? Theme.of(context).colorScheme.error : const Color(0xFF0D9362); // Green color
    final badgeTextColor = event.isTrending ? Theme.of(context).colorScheme.onError : Colors.white;
    final isNew = DateTime.now().difference(event.createdAt).inDays <= 3;
    final badgeText = event.isTrending ? 'Trending' : (event.isLimitedSpots ? 'Limited Spots' : (isNew ? 'New' : 'Live'));
    
    Widget bottomLeftWidget = event.isTrending
        ? _buildAvatarPile(count: '+42')
        : Row(
            children: [
              SizedBox(
                width: 80,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: event.spots > 0 ? (event.spots - event.availableSpots) / event.spots : 0,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.secondary),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${event.spots - event.availableSpots}/${event.spots} spots filled',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          );

    String? secondaryStatus;
    if (event.isRegistrationClosed) {
      secondaryStatus = 'Registration Closed';
    } else if (event.isCheckInClosed) {
      secondaryStatus = 'Check-in Closed';
    } else if (event.isLimitedSpots && event.availableSpots <= 0) {
      secondaryStatus = 'Sold Out';
    }

    Widget bottomRightWidget = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
          child: Text(
            event.displayPrice,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        if (secondaryStatus != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              secondaryStatus,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );

    return GestureDetector(
      onTap: () {
        context.push('/event-detail/${event.id}');
      },
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
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image and Badges
            Stack(
              children: [
                Hero(
                  tag: 'event-image-${event.id}',
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: event.hasValidImage
                        ? DynamicImage(
                            imageUrl: event.imageUrl,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: Icon(
                                Icons.image,
                                size: 48,
                                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      badgeText.toUpperCase(),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: badgeTextColor,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.business_center, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        event.organizerName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today, size: 18, color: Theme.of(context).colorScheme.secondary),
                          const SizedBox(width: 4),
                          Text(
                            '${_formatDate(event.date)} • ${event.time}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on, size: 18, color: Theme.of(context).colorScheme.secondary),
                          const SizedBox(width: 4),
                          Text(
                            event.location,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      bottomLeftWidget,
                      bottomRightWidget,
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPile({required String count}) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          height: 24,
          child: Stack(
            children: [
              const Positioned(
                left: 0,
                child: DynamicAvatar(name: 'A', radius: 12, fontSize: 10),
              ),
              const Positioned(
                left: 16,
                child: DynamicAvatar(name: 'B', radius: 12, fontSize: 10),
              ),
              const Positioned(
                left: 32,
                child: DynamicAvatar(name: 'C', radius: 12, fontSize: 10),
              ),
              Positioned(
                left: 48,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Text(
                    count,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.event_busy, size: 64, color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: 24),
          Text(
            'No live events found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later or adjust your search to find what you are looking for.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
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
      child: Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        highlightColor: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 80, height: 16, color: Colors.white),
                  const SizedBox(height: 12),
                  Container(width: double.infinity, height: 24, color: Colors.white),
                  const SizedBox(height: 16),
                  Container(width: 150, height: 16, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
