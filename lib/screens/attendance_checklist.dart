import 'package:flutter/material.dart';
import 'qr_scan_check_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import 'package:intl/intl.dart';

class AttendanceChecklist extends StatefulWidget {
  final String? eventId;
  const AttendanceChecklist({super.key, this.eventId});

  @override
  State<AttendanceChecklist> createState() => _AttendanceChecklistState();
}

class _AttendanceChecklistState extends State<AttendanceChecklist> {
  String _searchQuery = '';
  String _selectedFilter = 'All';
  DateTime? _lastWarningTime;
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  String _eventTitle = 'Attendance Checklist';
  String _eventDate = '';
  DateTime? _eventStartDateTime;

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

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    if (widget.eventId == null) {
      setState(() { _isLoading = false; });
      return;
    }

    final eventProvider = context.read<EventProvider>();
    final event = eventProvider.getEventById(widget.eventId!);
    if (event == null) {
      setState(() { _isLoading = false; });
      return;
    }

    _eventTitle = event.title;
    _eventDate = DateFormat('MMM dd, yyyy').format(event.date);
    _eventStartDateTime = _parseEventDateTime(event.date, event.time);

    final List<Map<String, dynamic>> loaded = [];
    for (final uid in event.registeredUserIds) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          final isChecked = event.attendedUserIds.contains(uid);
          final name = data['name'] ?? 'Unknown';
          final initial = name.isNotEmpty ? name[0] : '?';
          loaded.add({
            'name': name,
            'initial': initial,
            'hasImage': false,
            'isChecked': isChecked,
            'time': isChecked ? 'Checked in' : '',
          });
        }
      } catch (e) {
        // skip failed user lookups
      }
    }

    setState(() {
      _students = loaded;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final event = widget.eventId != null ? eventProvider.getEventById(widget.eventId!) : null;
    final bool isCheckInClosed = event?.isCheckInClosed ?? false;
    
    final registeredCount = _students.length;
    final presentCount = _students.where((s) => s['isChecked'] == true).length;
    final absentCount = registeredCount - presentCount;

    final filteredStudents = _students.where((s) {
      final matchesSearch = s['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      bool matchesFilter = true;
      if (_selectedFilter == 'Checked-in') {
        matchesFilter = s['isChecked'] == true;
      } else if (_selectedFilter == 'Missing') {
        matchesFilter = s['isChecked'] == false;
      }
      return matchesSearch && matchesFilter;
    }).toList();

    final now = DateTime.now();
    final bool isScanOpen = _eventStartDateTime != null && now.isAfter(_eventStartDateTime!.subtract(const Duration(minutes: 30))) && !isCheckInClosed;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurfaceVariant),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text('Loading...'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            height: 1.0,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurfaceVariant),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _eventTitle,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              'Attendance Checklist • $_eventDate',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 100.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Metrics Grid
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                value: '$registeredCount',
                                label: 'REGISTERED',
                                valueColor: Theme.of(context).colorScheme.onSurface,
                                labelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                                bgColor: Theme.of(context).colorScheme.surface,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildMetricCard(
                                value: '$presentCount',
                                label: 'PRESENT',
                                valueColor: Theme.of(context).colorScheme.onSecondaryContainer,
                                labelColor: Theme.of(context).colorScheme.onSecondaryContainer,
                                bgColor: Theme.of(context).colorScheme.secondaryContainer,
                                borderColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                                child: _buildMetricCard(
                                  value: '$absentCount',
                                  label: 'ABSENT',
                                  valueColor: Theme.of(context).colorScheme.onErrorContainer,
                                  labelColor: Theme.of(context).colorScheme.onErrorContainer,
                                  bgColor: Theme.of(context).colorScheme.errorContainer,
                                  borderColor: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                                ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Search Bar
                        TextField(
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search student...',
                            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                            prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceContainer,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip('All ($registeredCount)', 'All'),
                              const SizedBox(width: 8),
                              _buildFilterChip('Checked-in ($presentCount)', 'Checked-in'),
                              const SizedBox(width: 8),
                              _buildFilterChip('Missing ($absentCount)', 'Missing'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Student List
                        if (filteredStudents.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Center(
                              child: Text('No students found.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredStudents.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final student = filteredStudents[index];
                              return _buildStudentRow(
                                student: student,
                                isCheckInClosed: isCheckInClosed,
                                onTap: () {
                                  final now = DateTime.now();
                                  if (_lastWarningTime == null || now.difference(_lastWarningTime!).inSeconds >= 30) {
                                    _lastWarningTime = now;
                                    ScaffoldMessenger.of(context).clearSnackBars();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Please use the QR Scanner to check in students.',
                                          style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                                        ),
                                        backgroundColor: Theme.of(context).colorScheme.errorContainer,
                                        behavior: SnackBarBehavior.floating,
                                        margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 48, top: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Theme.of(context).colorScheme.surfaceContainerLowest,
                    Theme.of(context).colorScheme.surfaceContainerLowest.withValues(alpha: 0.8),
                    Theme.of(context).colorScheme.surfaceContainerLowest.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: ElevatedButton.icon(
                onPressed: isScanOpen ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const QrScanCheckIn()),
                  );
                } : null,
                icon: Icon(
                  isScanOpen ? Icons.qr_code_scanner : Icons.lock_clock, 
                  color: isScanOpen ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.outline
                ),
                label: Text(
                  isScanOpen ? 'Scan QR Code' : 'Scan available 30 min before',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: isScanOpen ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.outline,
                    fontSize: isScanOpen ? null : 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ).copyWith(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.disabled)) {
                      return Theme.of(context).colorScheme.surfaceContainerHigh;
                    }
                    return Theme.of(context).colorScheme.primary;
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String value,
    required String label,
    required Color valueColor,
    required Color labelColor,
    required Color bgColor,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor ?? Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: valueColor,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: labelColor,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String filterValue) {
    bool isSelected = _selectedFilter == filterValue;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filterValue;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isSelected ? Theme.of(context).colorScheme.onSecondaryContainer : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildStudentRow({
    required Map<String, dynamic> student,
    required VoidCallback onTap,
    required bool isCheckInClosed,
  }) {
    final name = student['name'] as String;
    final hasImage = student['hasImage'] as bool? ?? false;
    final isChecked = student['isChecked'] as bool? ?? false;
    final initial = student['initial'] as String?;
    final time = student['time'] as String?;

    final statusText = isChecked ? 'Checked-in' : 'Missing';
    final statusColor = isChecked ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.outline;

    return GestureDetector(
      onTap: () {
        if (isCheckInClosed) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check-in has been closed.')));
          return;
        }
        onTap();
      },
      child: Opacity(
        opacity: isCheckInClosed ? 0.6 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(12),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
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
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                    child: Text(
                      initial ?? '',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          statusText.toUpperCase(),
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontSize: 10,
                            color: statusColor,
                            letterSpacing: 1.2,
                          ),
                        ),
                        if (isChecked && time != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            '• $time',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isChecked ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerLowest,
                border: isChecked ? null : Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5), width: 2),
              ),
              child: isChecked
                  ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.onPrimary, size: 20)
                  : Icon(Icons.radio_button_unchecked, color: Theme.of(context).colorScheme.outlineVariant, size: 20),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
