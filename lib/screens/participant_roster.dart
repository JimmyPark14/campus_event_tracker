import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../providers/registration_provider.dart';


class ParticipantRoster extends StatefulWidget {
  final String? eventId;
  const ParticipantRoster({super.key, this.eventId});

  @override
  State<ParticipantRoster> createState() => _ParticipantRosterState();
}

class _ParticipantRosterState extends State<ParticipantRoster> {
  String _searchQuery = '';
  String _selectedFilter = 'All';
  List<Map<String, dynamic>> _participants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    if (widget.eventId == null) {
      setState(() { _isLoading = false; });
      return;
    }

    final eventProvider = context.read<EventProvider>();
    final event = eventProvider.getEventById(widget.eventId!);
    if (event == null) {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
      return;
    }

    try {
      // Fetch all registrations to get receipts
      final registrationsQuery = await context.read<RegistrationProvider>().getAllRegistrationsFuture(widget.eventId!);
      final Map<String, String> receipts = {};
      for (var doc in registrationsQuery.docs) {
        receipts[doc['userId']] = (doc.data() as Map<String, dynamic>).containsKey('receiptBase64') ? doc['receiptBase64'] : '';
      }
      
      final List<Map<String, dynamic>> loaded = [];
      for (final uid in event.registeredUserIds) {
        try {
          final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          if (doc.exists) {
            final data = doc.data()!;
            final isAttended = event.attendedUserIds.contains(uid);
            final name = data['name'] ?? 'Unknown';
            final initials = name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
            loaded.add({
              'initials': initials,
              'name': name,
              'id': uid.length >= 8 ? uid.substring(0, 8).toUpperCase() : uid.toUpperCase(),
              'status': isAttended ? 'Attended' : 'Reg',
              'receiptBase64': receipts[uid] ?? '',
            });
          }
        } catch (e) {
          // skip failed user lookups
        }
      }

      if (mounted) {
        setState(() {
          _participants = loaded;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading participants: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.read<EventProvider>();
    final event = widget.eventId != null ? eventProvider.getEventById(widget.eventId!) : null;
    final eventTitle = event?.title ?? 'Unknown Event';
    final registeredCount = event?.registeredUserIds.length ?? 0;

    final filteredParticipants = _participants.where((p) {
      final name = p['name'].toString().toLowerCase();
      final id = p['id'].toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      final matchesSearch = name.contains(q) || id.contains(q);

      bool matchesFilter = true;
      if (_selectedFilter == 'Registered') {
        matchesFilter = p['status'] == 'Reg';
      } else if (_selectedFilter == 'Attended') {
        matchesFilter = p['status'] == 'Attended';
      }

      return matchesSearch && matchesFilter;
    }).toList();

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurfaceVariant),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text('Participant Roster', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.02),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurfaceVariant),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Participant Roster',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Context Area
              Column(
                children: [
                  Text(
                    eventTitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group, size: 16, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        '$registeredCount Registered',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Search Bar
              TextField(
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search students...',
                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.outline),
                  prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
              const SizedBox(height: 16),

              // Filter Chips
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                _buildFilterChip('All'),
                    _buildFilterChip('Registered'),
                    _buildFilterChip('Attended'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Roster List
              if (filteredParticipants.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Text('No participants found.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ),
                )
              else
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
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredParticipants.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final p = filteredParticipants[index];
                      final isAttended = p['status'] == 'Attended';
                      return _buildRosterItem(
                        initials: p['initials'],
                        avatarBgColor: Theme.of(context).colorScheme.primaryContainer,
                        avatarTextColor: Theme.of(context).colorScheme.onPrimaryContainer,
                        hasImage: p['hasImage'] ?? false,
                        name: p['name'],
                        id: p['id'],
                        status: p['status'],
                        statusBgColor: isAttended ? Theme.of(context).colorScheme.secondaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest,
                        statusTextColor: isAttended ? Theme.of(context).colorScheme.onSecondaryContainer : Theme.of(context).colorScheme.onSurfaceVariant,
                        statusBorderColor: p['statusBorderColor'],
                        receiptBase64: p['receiptBase64'],
                      );
                    },
                  ),
                ),
              const SizedBox(height: 24),

              // Load More Action
              Center(
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No more participants to load.')));
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    side: BorderSide(color: Theme.of(context).colorScheme.outline),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    'Load More',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = label;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.surfaceContainerLowest : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 2,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRosterItem({
    String? initials,
    Color? avatarBgColor,
    Color? avatarTextColor,
    bool hasImage = false,
    required String name,
    required String id,
    required String status,
    required Color statusBgColor,
    required Color statusTextColor,
    Color? statusBorderColor,
    String? receiptBase64,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          if (hasImage)
            CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
              child: Icon(Icons.person, color: Theme.of(context).colorScheme.onSurfaceVariant),
            )
          else
            CircleAvatar(
              radius: 20,
              backgroundColor: avatarBgColor,
              child: Text(
                initials ?? '',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: avatarTextColor,
                ),
              ),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  id,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: BorderRadius.circular(16),
              border: statusBorderColor != null ? Border.all(color: statusBorderColor) : null,
            ),
            child: Text(
              status,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: statusTextColor,
              ),
            ),
          ),
          if (receiptBase64 != null && receiptBase64.isNotEmpty) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.receipt_long),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Receipt - $name'),
                    content: Image.memory(
                      // ignore: prefer_interpolation_to_compose_strings
                      Uri.parse('data:image/png;base64,' + receiptBase64).data!.contentAsBytes(),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
