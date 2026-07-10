import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../theme.dart';
import '../providers/auth_provider.dart';
import '../providers/event_provider.dart';
import '../providers/user_cache_provider.dart';
import '../widgets/dynamic_avatar.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All Events';
  Timer? _debounce;
  int _visibleLimit = 15;
  
  final List<String> _categories = ['All Events', 'Saved', 'Organizer', 'Tech', 'Arts', 'Sports', 'Academic'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _searchQuery = _searchController.text.toLowerCase();
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
        child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
              if (mounted) {
                setState(() {
                  _visibleLimit += 15;
                });
              }
            }
            return false;
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
            SliverAppBar(
              expandedHeight: 180.0,
              floating: false,
              pinned: true,
              backgroundColor: Theme.of(context).colorScheme.primary,
              elevation: 0,
              shape: const ContinuousRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(48),
                ),
              ),
              automaticallyImplyLeading: false, // Removes the default leading widget (no hamburger)
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: GestureDetector(
                    onTap: () => context.go('/profile'),
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
                    final hour = DateTime.now().hour;
                    final greeting = hour < 12 ? 'Good morning,' : hour < 17 ? 'Good afternoon,' : 'Good evening,';
                    return Container(
                      padding: const EdgeInsets.only(left: 24.0, bottom: 24.0),
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
                            greeting,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          Text(
                            authProvider.userProfile?.name ?? 'Student',
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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
                padding: const EdgeInsets.only(top: 24.0, left: 24.0, right: 24.0, bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search campus events...',
                          prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
                          contentPadding: const EdgeInsets.symmetric(vertical: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Categories
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: SizedBox(
                  height: 40,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category == _selectedCategory;
                      return ActionChip(
                        label: Text(
                          category,
                          style: TextStyle(
                            color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.primary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        backgroundColor: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
                        side: isSelected ? BorderSide.none : BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusFull)),
                        onPressed: () {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Events',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Dynamic Event List
                    Consumer<EventProvider>(
                      builder: (context, eventProvider, _) {
                        final now = DateTime.now();
                        final userId = context.read<AuthProvider>().firebaseUser?.uid ?? '';
                        
                        if (_selectedCategory == 'Organizer') {
                          final uniqueOrganizers = <String, Map<String, dynamic>>{};
                          for (var e in eventProvider.events) {
                            if (!uniqueOrganizers.containsKey(e.organizerId)) {
                              uniqueOrganizers[e.organizerId] = {
                                'id': e.organizerId,
                                'name': e.organizerName,
                              };
                            }
                          }
                          final organizersList = uniqueOrganizers.values
                              .where((org) => org['name'].toString().toLowerCase().contains(_searchQuery))
                              .toList();
                              
                          if (organizersList.isEmpty) {
                            return Container(
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
                                      child: Icon(Icons.person_off, size: 48, color: Theme.of(context).colorScheme.outline),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No organizers found',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: organizersList.map((org) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                  onTap: () => context.push('/organizer-profile/${org['id']}'),
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
                                        Consumer<UserCacheProvider>(
                                          builder: (context, userCache, child) {
                                            final cachedUser = userCache.getUser(org['id'].toString());
                                            if (cachedUser == null) {
                                              // Fetch it asynchronously without rebuilding endlessly
                                              Future.microtask(() => userCache.fetchUser(org['id'].toString()));
                                            }
                                            return DynamicAvatar(
                                              name: org['name'].toString(),
                                              avatarUrl: cachedUser?.avatarUrl,
                                              radius: 24,
                                            );
                                          }
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(child: Text(org['name'].toString(), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                                        Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        }

                        final upcomingEvents = eventProvider.events
                            .where((e) => e.date.isAfter(now) && !e.isCancelled && !e.isEventEnded)
                            .toList()
                          ..sort((a, b) => a.date.compareTo(b.date));
                          
                        final filteredEvents = upcomingEvents.where((event) {
                          final matchesCategory = _selectedCategory == 'All Events' 
                              ? true 
                              : _selectedCategory == 'Saved' 
                                  ? event.bookmarkedUserIds.contains(userId)
                                  : event.category == _selectedCategory;
                          final matchesSearch = event.title.toLowerCase().contains(_searchQuery);
                          return matchesCategory && matchesSearch;
                        }).toList();

                        if (eventProvider.isLoading && filteredEvents.isEmpty) {
                          return Column(
                            children: List.generate(4, (index) => _buildSkeletonCard(context)),
                          );
                        }

                        if (filteredEvents.isEmpty) {
                          return Container(
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
                                    child: Icon(Icons.event_busy, size: 48, color: Theme.of(context).colorScheme.outline),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No events found',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try adjusting your search or filters.',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        }

                        final eventsToShow = filteredEvents.take(_visibleLimit).toList();

                        return Column(
                          children: eventsToShow.map((event) {
                            final isFree = event.price == 0;
                            String? secondaryTag;
                            if (event.isRegistrationClosed) {
                              secondaryTag = 'Registration Closed';
                            } else if (event.isCheckInClosed) {
                              secondaryTag = 'Check-in Closed';
                            } else if (event.isLimitedSpots && event.availableSpots <= 0) {
                              secondaryTag = 'Sold Out';
                            } else if (event.isLimitedSpots) {
                              secondaryTag = 'Limited Space';
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                onTap: () => context.push('/event-detail/${event.id}'),
                                child: _buildEventCard(context,
                                  month: DateFormat('MMM').format(event.date).toUpperCase(),
                                  day: DateFormat('dd').format(event.date),
                                  title: event.title,
                                  location: event.location,
                                  tag: isFree ? 'FREE' : 'PAID',
                                  secondaryTag: secondaryTag,
                                  isFree: isFree,
                                  dateColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                                  onDateColor: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 80), // Padding for the floating nav bar
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildSkeletonCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
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
      child: Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        highlightColor: Theme.of(context).colorScheme.surface,
        child: Row(
          children: [
            Container(
              width: 64,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 100, height: 12, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(width: double.infinity, height: 16, color: Colors.white),
                  const SizedBox(height: 12),
                  Container(width: 80, height: 12, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, {
    required String month,
    required String day,
    required String title,
    required String location,
    required String tag,
    String? secondaryTag,
    required bool isFree,
    required Color dateColor,
    required Color onDateColor,
  }) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 72,
            decoration: BoxDecoration(
              color: dateColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  month,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: onDateColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  day,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: onDateColor,
                    fontWeight: FontWeight.bold,
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isFree ? Colors.green.withValues(alpha: 0.1) : Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Text(
                        tag,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isFree ? Colors.green.shade700 : Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (secondaryTag != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: Text(
                          secondaryTag,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
        ],
      ),
    );
  }
}
