import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/event_provider.dart';

class EventAnalytics extends StatefulWidget {
  final String eventId;
  const EventAnalytics({super.key, required this.eventId});

  @override
  State<EventAnalytics> createState() => _EventAnalyticsState();
}

class _EventAnalyticsState extends State<EventAnalytics> {
  Map<String, int> _majorCounts = {};
  bool _isLoadingMajors = true;

  @override
  void initState() {
    super.initState();
    _loadMajors();
  }

  Future<void> _loadMajors() async {
    final eventProvider = context.read<EventProvider>();
    final event = eventProvider.getEventById(widget.eventId);
    if (event == null || event.registeredUserIds.isEmpty) {
      if (mounted) setState(() => _isLoadingMajors = false);
      return;
    }

    try {
      final counts = <String, int>{};
      for (final uid in event.registeredUserIds) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (doc.exists) {
          final major = doc.data()?['major'] ?? 'Unknown';
          final m = major.toString().trim().isEmpty ? 'Unknown' : major;
          counts[m] = (counts[m] ?? 0) + 1;
        }
      }
      if (mounted) {
        setState(() {
          _majorCounts = counts;
          _isLoadingMajors = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMajors = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Event Analytics'),
      ),
      body: Consumer<EventProvider>(
        builder: (context, eventProvider, child) {
          final event = eventProvider.getEventById(widget.eventId);
          if (event == null) {
            return const Center(child: Text('Event not found.'));
          }

          final totalRegistered = event.registeredUserIds.length;
          final totalAttended = event.attendedUserIds.length;
          final totalPending = event.pendingUserIds.length;
          final conversionRate = totalRegistered > 0 ? (totalAttended / totalRegistered * 100).toStringAsFixed(1) : '0.0';

          double totalRevenue = (event.price * totalRegistered).toDouble();
          String revenueStr = '\$${totalRevenue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    Expanded(
                      child: _buildGridStat(
                        icon: Icons.how_to_reg,
                        iconBgColor: Theme.of(context).colorScheme.primaryContainer,
                        iconColor: Theme.of(context).colorScheme.onPrimaryContainer,
                        title: 'Total RSVPs',
                        value: '$totalRegistered',
                        trend: '',
                        trendIcon: Icons.arrow_upward,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildGridStat(
                        icon: Icons.fact_check,
                        iconBgColor: Theme.of(context).colorScheme.secondaryContainer,
                        iconColor: Theme.of(context).colorScheme.onSecondaryContainer,
                        title: 'Attendance Rate',
                        value: '$conversionRate%',
                        trend: '',
                        trendIcon: Icons.arrow_upward,
                      ),
                    ),
                  ],
                ),
                ),
                const SizedBox(height: 16),
                _buildRevenueStat(revenueStr),
                const SizedBox(height: 16),
                _buildAttendanceStat(totalRegistered, totalPending),
                const SizedBox(height: 24),
                
                // Top Major Participation Pie Chart
                Container(
                  width: double.infinity,
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
                        'Top Major Participation',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildMajorParticipationPieChart(context),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildMajorParticipationPieChart(BuildContext context) {
    if (_isLoadingMajors) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_majorCounts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('No participant data yet', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
    }

    final sortedMajors = _majorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
      Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
      Theme.of(context).colorScheme.secondary.withValues(alpha: 0.6),
    ];

    int totalCount = _majorCounts.values.fold(0, (a, b) => a + b);

    List<PieChartSectionData> sections = [];
    List<Widget> legendItems = [];
    int otherCount = 0;
    
    for (int i = 0; i < sortedMajors.length; i++) {
      if (i < 4) {
        final entry = sortedMajors[i];
        final percentage = (entry.value / totalCount * 100);
        sections.add(PieChartSectionData(
          color: colors[i % colors.length],
          value: entry.value.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 60,
          titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
        ));
        legendItems.add(_buildLegendItem(colors[i % colors.length], entry.key));
      } else {
        otherCount += sortedMajors[i].value;
      }
    }
    
    if (otherCount > 0) {
       final percentage = (otherCount / totalCount * 100);
       sections.add(PieChartSectionData(
          color: Theme.of(context).colorScheme.outlineVariant,
          value: otherCount.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 60,
          titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
        ));
        legendItems.add(_buildLegendItem(Theme.of(context).colorScheme.outlineVariant, 'Other'));
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: legendItems,
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildGridStat({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String value,
    required String trend,
    required IconData trendIcon,
  }) {
    return Container(
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
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          value,
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    if (trend.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(trendIcon, size: 14, color: Theme.of(context).colorScheme.secondary),
                          Text(
                            trend,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueStat(String revenueStr) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.payments, color: Theme.of(context).colorScheme.onTertiaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Revenue Collected',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        revenueStr,
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStat(int totalConfirmed, int totalPending) {
    int total = totalConfirmed + totalPending;
    int percentage = total == 0 ? 0 : ((totalConfirmed / total) * 100).round();

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.groups, color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Registration Status',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '$percentage%',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 32,
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Confirmed: $totalConfirmed',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Pending: $totalPending',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
