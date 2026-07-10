import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/dynamic_avatar.dart';
import '../models/event_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OverallAnalytics extends StatefulWidget {
  const OverallAnalytics({super.key});

  @override
  State<OverallAnalytics> createState() => _OverallAnalyticsState();
}

class _OverallAnalyticsState extends State<OverallAnalytics> {
  int _selectedYear = DateTime.now().year;
  String _selectedGrowthPeriod = 'Last 30 Days';
  Map<String, int> _majorCounts = {};
  bool _isLoadingMajors = true;

  @override
  void initState() {
    super.initState();
    // Load majors asynchronously
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMajors();
    });
  }

  Future<void> _loadMajors() async {
    if (!mounted) return;
    setState(() => _isLoadingMajors = true);
    
    try {
      final authId = context.read<AuthProvider>().userProfile?.uid ?? '';
      final allEvents = context.read<EventProvider>().getOrganizerEvents(authId);
      final events = allEvents.where((e) => e.date.year == _selectedYear).toList();
      final allUserIds = <String>{};
      for (final event in events) {
        allUserIds.addAll(event.registeredUserIds);
      }

      if (allUserIds.isEmpty) {
        if (mounted) {
          setState(() {
            _majorCounts = {};
            _isLoadingMajors = false;
          });
        }
        return;
      }

      final counts = <String, int>{};
      for (final uid in allUserIds) {
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.02),
        automaticallyImplyLeading: false,
        title: Text(
          'Event Analytics',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () { context.go('/organizer/profile'); },
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0, bottom: 96.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section Card
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
                  Row(
                    children: [
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          return Text(
                            authProvider.userProfile?.name ?? 'Organizer',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          final int startYear = 1900;
                          final int endYear = DateTime.now().year + 5;
                          final int totalYears = endYear - startYear + 1;
                          final int currentYearIndex = _selectedYear - startYear;
                          final FixedExtentScrollController scrollController =
                              FixedExtentScrollController(initialItem: currentYearIndex);
                          showModalBottomSheet(
                            context: context,
                            useRootNavigator: true,
                            builder: (context) => Container(
                              height: 280,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                        ),
                                        Text('Select Year', style: Theme.of(context).textTheme.headlineMedium),
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _selectedYear = startYear + scrollController.selectedItem;
                                            });
                                            _loadMajors();
                                            Navigator.pop(context);
                                          },
                                          child: Text('Done', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(height: 1),
                                  Expanded(
                                    child: CupertinoPicker(
                                      scrollController: scrollController,
                                      itemExtent: 42,
                                      onSelectedItemChanged: (index) {
                                        debugPrint('Feature not implemented');
                                      },
                                      children: List.generate(totalYears, (index) {
                                        final year = startYear + index;
                                        return Center(
                                          child: Text(
                                            '$year',
                                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$_selectedYear',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_drop_down, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Performance Overview',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          context.push('/export-data');
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.download, size: 16, color: Theme.of(context).colorScheme.onSurface),
                              const SizedBox(width: 4),
                              Text(
                                'Export Report',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Participant Growth Chart Section
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          'Participant Growth\nOver Time',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedGrowthPeriod,
                            isDense: true,
                            icon: Icon(Icons.expand_more, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Last 30 Days', child: Text('Last 30 Days')),
                              DropdownMenuItem(value: 'Last 7 Days', child: Text('Last 7 Days')),
                              DropdownMenuItem(value: 'All Time', child: Text('All Time')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedGrowthPeriod = value;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 220,
                    width: double.infinity,
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
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, right: 36, top: 16, bottom: 8),
                      child: LineChart(
                        LineChartData(
                                        lineTouchData: LineTouchData(
                                          touchTooltipData: LineTouchTooltipData(
                                            fitInsideHorizontally: true,
                                            fitInsideVertically: true,
                                            tooltipPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                            getTooltipColor: (touchedSpot) => Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                                            getTooltipItems: (touchedSpots) {
                                              return touchedSpots.map((spot) {
                                                return LineTooltipItem(
                                                  '${spot.y.toInt()}',
                                                  TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 14),
                                                  textAlign: TextAlign.center,
                                                );
                                              }).toList();
                                            },
                                          ),
                                          getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                                            return spotIndexes.map((index) {
                                              return TouchedSpotIndicatorData(
                                                FlLine(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3), strokeWidth: 2, dashArray: [4, 4]),
                                                FlDotData(
                                                  show: true,
                                                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                                    radius: 6,
                                                    color: Theme.of(context).colorScheme.primary,
                                                    strokeWidth: 2,
                                                    strokeColor: Theme.of(context).colorScheme.surface,
                                                  ),
                                                ),
                                              );
                                            }).toList();
                                          },
                                          handleBuiltInTouches: true,
                                        ),
                                        gridData: FlGridData(
                                          show: true,
                                          drawVerticalLine: false,
                                          drawHorizontalLine: true,
                                          horizontalInterval: 1,
                                          getDrawingHorizontalLine: (value) {
                                            return FlLine(
                                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                                              strokeWidth: 1,
                                              dashArray: [5, 5],
                                            );
                                          },
                                        ),
                                        titlesData: FlTitlesData(
                                          show: true,
                                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 40,
                                              interval: 1,
                                              getTitlesWidget: _getTitlesWidget,
                                            ),
                                          ),
                                          leftTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 28,
                                              getTitlesWidget: _getLeftTitlesWidget,
                                            ),
                                          ),
                                        ),
                                        borderData: FlBorderData(show: false),
                                        minX: 0,
                                        maxX: _getMaxX(),
                                        minY: 0,
                                        maxY: _getMaxY(context),
                                        lineBarsData: [
                                          LineChartBarData(
                                            spots: _buildRegistrationSpots(context),
                                            isCurved: false,
                                            gradient: LinearGradient(
                                              colors: [
                                                Theme.of(context).colorScheme.primary,
                                                Theme.of(context).colorScheme.secondary,
                                              ],
                                            ),
                                            barWidth: 4,
                                            isStrokeCapRound: true,
                                            dotData: FlDotData(
                                              show: true,
                                              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                                radius: 4,
                                                color: Theme.of(context).colorScheme.surface,
                                                strokeWidth: 2,
                                                strokeColor: Theme.of(context).colorScheme.primary,
                                              ),
                                            ),
                                            belowBarData: BarAreaData(
                                              show: true,
                                              gradient: LinearGradient(
                                                colors: [
                                                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.0),
                                                ],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                            ),
                                          ),
                                ], // lineBarsData
                              ), // LineChartData
                        ),
                      ),
                    ),
                ], // Column children
              ), // Column
            ), // Padding
            const SizedBox(height: 24),
            
            Consumer<EventProvider>(
              builder: (context, eventProvider, child) {
                final authId = context.read<AuthProvider>().userProfile?.uid ?? '';
                final allEvents = eventProvider.getOrganizerEvents(authId);
                final events = allEvents.where((e) => e.date.year == _selectedYear).toList();
                final totalEvents = events.length;
                final totalRegistered = events.fold<int>(0, (prevSum, e) => prevSum + e.registeredUserIds.length);
                final totalAttended = events.fold<int>(0, (prevSum, e) => prevSum + e.attendedUserIds.length);
                final conversionRate = totalRegistered > 0 ? (totalAttended / totalRegistered * 100).toStringAsFixed(1) : '0.0';

                return Column(
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                        Expanded(
                          child: _buildGridStat(
                            icon: Icons.event,
                            iconBgColor: Theme.of(context).colorScheme.primaryContainer,
                            iconColor: Theme.of(context).colorScheme.onPrimaryContainer,
                            title: 'Total Events',
                            value: '$totalEvents',
                            trend: '',
                            trendIcon: Icons.arrow_upward,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildGridStat(
                            icon: Icons.how_to_reg,
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
                    _buildRevenueStat(events),
                    const SizedBox(height: 16),
                    _buildAttendanceStat(events),
                  ],
                );
              }
            ),
            const SizedBox(height: 24),

            // Top Major Participation Bar Chart
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
      ),
    );
  }

  double _getMaxY(BuildContext context) {
    final spots = _buildRegistrationSpots(context);
    if (spots.isEmpty) return 10.0;
    double max = 0;
    for (var spot in spots) {
      if (spot.y > max) max = spot.y;
    }
    if (max == 0) return 10.0;
    return (max * 1.2).ceilToDouble();
  }

  int _getRegistrationsUpTo(DateTime date, List<EventModel> allEvents) {
    int count = 0;
    for (var e in allEvents) {
      if (e.date.isBefore(date) || e.date.isAtSameMomentAs(date)) {
        count += e.registeredUserIds.length;
      }
    }
    return count;
  }



  double _getMaxX() {
    if (_selectedGrowthPeriod == 'Last 7 Days') return 6.0;
    if (_selectedGrowthPeriod == 'Last 30 Days') return 3.0;
    return 11.0;
  }

  Widget _getTitlesWidget(double value, TitleMeta meta) {
    const style = TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 10);
    final int index = value.toInt();
    
    if (_selectedGrowthPeriod == 'Last 7 Days') {
      if (index >= 0 && index <= 6) {
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final d = startOfWeek.add(Duration(days: index));
        final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];
        final dateStr = '${d.day}/${d.month}';
        return SideTitleWidget(
          meta: meta,
          space: 8,
          fitInside: SideTitleFitInsideData.fromTitleMeta(meta, distanceFromEdge: 0),
          child: Text('$dayName\n$dateStr', textAlign: TextAlign.center, style: style),
        );
      }
    } else if (_selectedGrowthPeriod == 'Last 30 Days') {
      if (index >= 0 && index <= 3) {
        return SideTitleWidget(
          meta: meta,
          space: 8,
          fitInside: SideTitleFitInsideData.fromTitleMeta(meta, distanceFromEdge: 0),
          child: Text('W${index + 1}', style: style),
        );
      }
    } else {
      if (index >= 0 && index <= 11) {
        final monthName = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][index];
        return SideTitleWidget(
          meta: meta,
          space: 8,
          fitInside: SideTitleFitInsideData.fromTitleMeta(meta, distanceFromEdge: 0),
          child: Text(monthName, style: style),
        );
      }
    }
    return SideTitleWidget(meta: meta, child: const Text('', style: style));
  }

  Widget _getLeftTitlesWidget(double value, TitleMeta meta) {
    const style = TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 10);
    // Don't show decimal titles, but DO show 0
    if (value != value.toInt()) {
      return const SizedBox.shrink();
    }
    String text;
    if (value >= 1000000) {
      text = '${(value / 1000000).toStringAsFixed(value % 1000000 == 0 ? 0 : 1)}M';
    } else if (value >= 1000) {
      text = '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K';
    } else {
      text = '${value.toInt()}';
    }

    return SideTitleWidget(
      meta: meta,
      space: 12,
      child: Text(text, style: style),
    );
  }

  List<FlSpot> _buildRegistrationSpots(BuildContext context) {
    final authId = context.read<AuthProvider>().userProfile?.uid ?? '';
    final allEventsOriginal = context.read<EventProvider>().getOrganizerEvents(authId);
    final allEvents = allEventsOriginal.where((e) => e.date.year == _selectedYear).toList();
    
    final spots = <FlSpot>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (_selectedGrowthPeriod == 'Last 7 Days') {
      final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
      for (int i = 0; i <= 6; i++) {
        final d = startOfWeek.add(Duration(days: i));
        final endOfDay = DateTime(d.year, d.month, d.day, 23, 59, 59);
        final count = _getRegistrationsUpTo(endOfDay, allEvents);
        spots.add(FlSpot(i.toDouble(), count.toDouble()));
      }
    } else if (_selectedGrowthPeriod == 'Last 30 Days') {
      for (int i = 0; i <= 3; i++) {
        final d = today.subtract(Duration(days: 21 - (i * 7)));
        final endOfDay = DateTime(d.year, d.month, d.day, 23, 59, 59);
        final count = _getRegistrationsUpTo(endOfDay, allEvents);
        spots.add(FlSpot(i.toDouble(), count.toDouble()));
      }
    } else {
      for (int i = 0; i < 12; i++) {
        int nextMonth = i + 2;
        int year = _selectedYear;
        if (nextMonth > 12) {
          nextMonth = 1;
          year++;
        }
        final endOfMonth = DateTime(year, nextMonth, 0, 23, 59, 59);
        final count = _getRegistrationsUpTo(endOfMonth, allEvents);
        spots.add(FlSpot(i.toDouble(), count.toDouble()));
      }
    }
    return spots;
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

  Widget _buildRevenueStat(List<EventModel> events) {
    double totalRevenue = 0;
    for (var e in events) {
      totalRevenue += e.price * e.registeredUserIds.length;
    }

    String revenueStr = '\$${totalRevenue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';

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
                      'Revenue Collected',
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

  Widget _buildAttendanceStat(List<EventModel> events) {
    int totalConfirmed = 0;
    int totalPending = 0;
    for (var e in events) {
      totalConfirmed += e.registeredUserIds.length;
      totalPending += e.pendingUserIds.length;
    }
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
