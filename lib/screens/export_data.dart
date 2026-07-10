import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../providers/event_provider.dart';
import '../models/event_model.dart';

class ExportDataScreen extends StatefulWidget {
  final String? eventId;
  const ExportDataScreen({super.key, this.eventId});

  @override
  State<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  // Selection states
  bool _includeParticipants = true;
  bool _includeAttendance = true;
  bool _includeFinancials = false;
  bool _includeFeedback = false;

  String _selectedDateRange = 'Last 30 Days';
  final List<String> _dateRanges = ['Last 7 Days', 'Last 30 Days', 'This Semester', 'All Time', 'Custom Range'];

  String _selectedFormat = 'CSV';
  final List<String> _formats = ['CSV', 'PDF'];

  bool _isDownloading = false;
  bool _isEmailing = false;

  void _handleAction(String action) async {
    setState(() {
      if (action == 'download') _isDownloading = true;
      if (action == 'email') _isEmailing = true;
    });

    String message = '';
    
    try {
      final eventProvider = context.read<EventProvider>();
      List<EventModel> eventsToExport = [];
      
      if (widget.eventId != null) {
        final event = eventProvider.getEventById(widget.eventId!);
        if (event != null) eventsToExport.add(event);
      } else {
        eventsToExport = eventProvider.events; // For demo purposes, we'll just get all events. Ideally, we filter by organizer.
      }
      
      List<List<dynamic>> csvRows = [];
      csvRows.add(['Event Name', 'Participant Name', 'Email', 'Status']);
      
      for (var event in eventsToExport) {
        for (var uid in event.registeredUserIds) {
          final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          if (doc.exists) {
            final data = doc.data()!;
            final name = data['name'] ?? 'Unknown';
            final email = data['email'] ?? 'Unknown';
            final status = event.attendedUserIds.contains(uid) ? 'Attended' : 'Registered';
            csvRows.add([event.title, name, email, status]);
          }
        }
      }

      String? filePath;

      if (_selectedFormat == 'CSV') {
        String csvData = Csv().encode(csvRows);
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/CampusEventTracker_Export.csv');
        await file.writeAsString(csvData);
        filePath = file.path;
      } else if (_selectedFormat == 'PDF') {
        final pdf = pw.Document();
        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Event Data Export', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 20),
                  pw.TableHelper.fromTextArray(
                    headers: csvRows.first,
                    data: csvRows.sublist(1),
                    border: pw.TableBorder.all(),
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    cellAlignment: pw.Alignment.centerLeft,
                  ),
                ],
              );
            },
          ),
        );
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/CampusEventTracker_Export.pdf');
        await file.writeAsBytes(await pdf.save());
        filePath = file.path;
      }

      if (action == 'download') {
        message = 'Export generated successfully!';
        if (mounted) {
          context.push('/file-viewer?filePath=$filePath&format=$_selectedFormat');
        }
        return;
      } else {
        if (filePath != null) {
          await SharePlus.instance.share(ShareParams(files: [XFile(filePath)], text: 'Campus Event Tracker Export'));
          message = 'Share dialog opened.';
        }
      }
    } catch (e) {
      message = 'Failed to generate export: $e';
    }
    if (!mounted) return;

    setState(() {
      _isDownloading = false;
      _isEmailing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    if (action == 'email') {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Theme.of(context).colorScheme.onSurface,
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.eventId == null ? 'Overall Data Export' : 'Event Data Export',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.eventId == null
                          ? 'Select Overall Data to Export'
                          : 'Select Event Data to Export',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCheckboxTile(
                      title: 'Participant List',
                      subtitle: 'Names, emails, and registration dates',
                      value: _includeParticipants,
                      onChanged: (val) => setState(() => _includeParticipants = val ?? false),
                    ),
                    _buildCheckboxTile(
                      title: 'Attendance Records',
                      subtitle: 'Check-in times and attendance status',
                      value: _includeAttendance,
                      onChanged: (val) => setState(() => _includeAttendance = val ?? false),
                    ),
                    _buildCheckboxTile(
                      title: 'Financial Overview',
                      subtitle: 'Ticket sales, refunds, and revenue',
                      value: _includeFinancials,
                      onChanged: (val) => setState(() => _includeFinancials = val ?? false),
                    ),
                    _buildCheckboxTile(
                      title: 'Post-Event Feedback',
                      subtitle: 'Survey responses and ratings',
                      value: _includeFeedback,
                      onChanged: (val) => setState(() => _includeFeedback = val ?? false),
                    ),
                    
                    const SizedBox(height: 32),
                    Text(
                      'Date Range',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      value: _selectedDateRange,
                      items: _dateRanges,
                      onChanged: (val) => setState(() => _selectedDateRange = val!),
                    ),

                    const SizedBox(height: 32),
                    Text(
                      'Export Format',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      value: _selectedFormat,
                      items: _formats,
                      onChanged: (val) => setState(() => _selectedFormat = val!),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Action Area
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (_isDownloading || _isEmailing) ? null : () => _handleAction('email'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isEmailing
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.email_outlined, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Send via Email',
                                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: (_isDownloading || _isEmailing) ? null : () => _handleAction('download'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isDownloading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Theme.of(context).colorScheme.primary,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.download_outlined, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Download to Device',
                                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
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
      ),
    );
  }

  Widget _buildCheckboxTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: value ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        activeColor: Theme.of(context).colorScheme.primary,
        checkColor: Theme.of(context).colorScheme.onPrimary,
        controlAffinity: ListTileControlAffinity.trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
          value: value,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.onSurfaceVariant),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
        ),
      ),
    );
  }
}
