import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/event_provider.dart';
import '../models/user_profile.dart';
import '../widgets/dynamic_avatar.dart';
import '../widgets/user_list_sheet.dart';
import '../widgets/dynamic_image.dart';

class OrganizerProfileDetail extends StatefulWidget {
  final String id;
  const OrganizerProfileDetail({super.key, required this.id});

  @override
  State<OrganizerProfileDetail> createState() => _OrganizerProfileDetailState();
}

class _OrganizerProfileDetailState extends State<OrganizerProfileDetail> {
  UserProfile? _organizerProfile;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchOrganizerProfile();
  }

  Future<void> _fetchOrganizerProfile() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.id).get();
      if (doc.exists) {
        setState(() {
          _organizerProfile = UserProfile.fromFirestore(doc);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Organizer not found.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profile.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty || _organizerProfile == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
        ),
        body: Center(child: Text(_errorMessage)),
      );
    }

    final eventProvider = context.watch<EventProvider>();
    final organizerEvents = eventProvider.events.where((e) => e.organizerId == widget.id).toList();
    final liveEvents = organizerEvents.where((e) => !e.isEventEnded && !e.date.isBefore(DateTime.now())).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          'Organizer Profile',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => context.go('/profile'),
              child: Consumer<AuthProvider>(
                builder: (context, auth, _) => DynamicAvatar(
                  name: auth.userProfile?.name ?? 'Student',
                  avatarUrl: auth.userProfile?.avatarUrl,
                  radius: 16,
                  fontSize: 14,
                ),
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 4),
            // Avatar
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3), width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: _organizerProfile!.avatarUrl.isNotEmpty
                          ? DynamicImage(
                              imageUrl: _organizerProfile!.avatarUrl,
                              fit: BoxFit.cover,
                            )
                          : DynamicAvatar(name: _organizerProfile!.name, radius: 48),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
                      ),
                      child: Icon(Icons.verified, size: 16, color: Theme.of(context).colorScheme.onPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Name
            Text(
              _organizerProfile!.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.school, size: 14, color: Theme.of(context).colorScheme.onSecondaryContainer),
                  const SizedBox(width: 4),
                  Text(
                    'Official Organization',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Stats (Events | Rating)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 48),
              padding: const EdgeInsets.symmetric(vertical: 12),
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
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      UserListSheet.show(
                        context,
                        title: 'Followers',
                        userIds: _organizerProfile!.followers,
                        emptyMessage: 'No followers yet.',
                      );
                    },
                    child: Column(
                      children: [
                        Text(
                          '${_organizerProfile!.followers.length}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Followers',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 40, color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  Column(
                    children: [
                      Text(
                        '${organizerEvents.length}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Events',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 40, color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  Column(
                    children: [
                        Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            organizerEvents.isEmpty || organizerEvents.fold<double>(0.0, (total, e) => total + e.averageRating) == 0
                                ? '-'
                                : (organizerEvents.fold<double>(0.0, (total, e) => total + e.averageRating) / organizerEvents.where((e) => e.averageRating > 0).length).toStringAsFixed(1),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rating',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // About section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _organizerProfile!.bio.isNotEmpty 
                    ? _organizerProfile!.bio 
                    : 'No bio provided yet.',
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Follow Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  final bool isFollowing = auth.userProfile?.following.contains(widget.id) ?? false;
                  return ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await auth.toggleFollowOrganizer(widget.id);
                        if (context.mounted) {
                          setState(() {
                            if (isFollowing) {
                              _organizerProfile!.followers.remove(auth.userProfile?.uid);
                            } else {
                              final uid = auth.userProfile?.uid;
                              if (uid != null) {
                                _organizerProfile!.followers.add(uid);
                              }
                            }
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(isFollowing ? 'Unfollowed!' : 'Followed!')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to update follow status.')),
                          );
                        }
                      }
                    },
                    icon: Icon(isFollowing ? Icons.person_remove : Icons.person_add),
                    label: Text(isFollowing ? 'Unfollow' : 'Follow', style: const TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                      backgroundColor: isFollowing ? Theme.of(context).colorScheme.surfaceContainerHighest : Theme.of(context).colorScheme.primary,
                      foregroundColor: isFollowing ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Live Events',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
              if (liveEvents.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('No live events at the moment.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: liveEvents.length,
                  itemBuilder: (context, index) {
                    final ev = liveEvents[index];
                    return GestureDetector(
                      onTap: () => context.push('/event-detail/${ev.id}'),
                      child: Container(
                        width: double.infinity,
                        height: 180,
                        margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: DecorationImage(
                              image: ev.hasValidImage 
                                ? getDynamicImageProvider(ev.imageUrl) 
                                : const NetworkImage('https://ui-avatars.com/api/?name=Event&background=random') as ImageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('OPEN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimaryContainer)),
                                ),
                              ),
                              Positioned(
                                bottom: 12,
                                left: 12,
                                right: 12,
                                child: Text(
                                  ev.title,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
