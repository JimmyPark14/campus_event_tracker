import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:screen_brightness/screen_brightness.dart';
import '../providers/auth_provider.dart';
import '../providers/event_provider.dart';
import '../providers/registration_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DigitalTicket extends StatelessWidget {
  final String eventId;

  const DigitalTicket({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().firebaseUser;
    final userProfile = context.watch<AuthProvider>().userProfile;
    final event = context.watch<EventProvider>().getEventById(eventId);

    if (user == null || event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your Ticket')),
        body: const Center(child: Text('Ticket not found')),
      );
    }

    final matrixNumber = user.email?.split('@').first ?? 'UNKNOWN';
    final userId = user.uid;
    final qrData = '${event.id}|$userId';
    final name = (userProfile?.name == null || userProfile!.name.isEmpty) ? 'Student' : userProfile.name;
    final isPending = event.pendingUserIds.contains(userId);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceBright,
      appBar: AppBar(
        backgroundColor: Theme.of(
          context,
        ).colorScheme.surfaceBright.withValues(alpha: 0.9),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Your Ticket',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          children: [
            // Ticket Card Container
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Event Info Banner (Top)
                  Container(
                    width: double.infinity,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary, // Vibrant header
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'ADMIT ONE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          event.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.calendar_month,
                              size: 16,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${DateFormat('MMMM d, yyyy').format(event.date)} • ${event.time}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Perforation Line
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(height: 24, color: Colors.white),
                      // Cutouts
                      Positioned(
                        left: -12,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceBright,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        right: -12,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceBright,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Dashed Line
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Row(
                          children: List.generate(
                            30,
                            (index) => Expanded(
                              child: Container(
                                height: 2,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Bottom part
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Extra Info Details (Organizer, Category, Price)
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoColumn(
                                'Organizer',
                                event.organizerName,
                              ),
                            ),
                            Expanded(
                              child: _buildInfoColumn('Status', 'Confirmed'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoColumn(
                                'Ticket Type',
                                'General Admission',
                              ),
                            ),
                            Expanded(
                              child: _buildInfoColumn(
                                'Price',
                                event.displayPrice,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Divider(color: Colors.grey.shade200),
                        const SizedBox(height: 24),

                        // QR Code
                        Builder(
                          builder: (ctx) {
                            if (isPending) {
                              return Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.pending_actions, size: 48, color: Colors.orange.shade700),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Payment Pending',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Your DuitNow payment is currently being verified by the organizer. Once approved, your ticket QR code will appear here.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.black87),
                                    ),
                                  ],
                                ),
                              );
                            }

                            bool isDimmed = false;
                            String? overlayText;
                            if (event.isCancelled) {
                              isDimmed = true;
                              overlayText = event.price > 0 ? 'REFUNDED' : 'CANCELLED';
                            } else if (event.isEventEnded || event.date.isBefore(DateTime.now())) {
                              isDimmed = true;
                              overlayText = 'EVENT ENDED';
                            }

                            return GestureDetector(
                              onTap: () {
                                if (event.isCancelled) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('This event has been cancelled.')));
                                } else if (event.isEventEnded || event.date.isBefore(DateTime.now())) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('This event has already ended.')));
                                } else {
                                  _showEnlargedQr(context, qrData, event.title, matrixNumber, name);
                                }
                              },
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Opacity(
                                        opacity: isDimmed ? 0.1 : 1.0,
                                        child: QrImageView(
                                          data: qrData,
                                          version: QrVersions.auto,
                                          backgroundColor: Colors.white,
                                        ),
                                      ),
                                      if (overlayText != null)
                                        Transform.rotate(
                                          angle: -0.5,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withValues(alpha: 0.9),
                                              border: Border.all(color: Colors.white, width: 3),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              overlayText,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 24,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 4,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Student ID
                        Text(
                          'ID: $matrixNumber',
                          style: const TextStyle(
                            color: Colors.black54,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Student Name
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.person,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Location Block
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  event.location,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Instructions Text
            if (!isPending)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                child: Text(
                  'Please present this QR code to the event organizer for check-in. Maximize screen brightness for faster scanning.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              
            if (!isPending && event.price > 0 && event.registeredUserIds.contains(user.uid))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: StreamBuilder<DocumentSnapshot>(
                  stream: context.read<RegistrationProvider>().getRegistrationStream(event.id, user.uid),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox.shrink();
                    
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    final refundRequested = data['refundRequested'] == true;
                    final refundStatus = data['refundStatus'] as String?;
                    
                    if (refundRequested) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: refundStatus == 'approved' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: refundStatus == 'approved' ? Colors.green : Colors.orange),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              refundStatus == 'approved' ? Icons.check_circle : Icons.pending_actions,
                              color: refundStatus == 'approved' ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              refundStatus == 'approved' ? 'Refund Approved' : 'Refund Requested',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: refundStatus == 'approved' ? Colors.green.shade700 : Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final isPastDeadline = DateTime.now().isAfter(event.date.subtract(const Duration(hours: 24)));

                    return ElevatedButton.icon(
                      onPressed: () {
                        if (isPastDeadline) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Refunds are unavailable less than 24 hours before the event.')),
                          );
                          return;
                        }

                        final reasonController = TextEditingController();
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Request Refund'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                                  ),
                                  child: const Text(
                                    'Notice: All approved refunds are subject to a 25% processing fee deduction from the original payment amount. You will receive 75% of your payment.',
                                    style: TextStyle(color: Colors.red, fontSize: 13),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: reasonController,
                                  decoration: const InputDecoration(
                                    labelText: 'Reason for refund',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 3,
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  if (reasonController.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Please provide a reason')));
                                    return;
                                  }
                                  Navigator.pop(ctx);
                                  try {
                                    await context.read<EventProvider>().requestRefund(event.id, user.uid, reasonController.text.trim());
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Refund request submitted')));
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error, foregroundColor: Theme.of(context).colorScheme.onError),
                                child: const Text('Submit Request'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.money_off),
                      label: const Text('Request Refund'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPastDeadline 
                          ? Theme.of(context).colorScheme.surfaceContainerHighest
                          : Theme.of(context).colorScheme.errorContainer,
                        foregroundColor: isPastDeadline
                          ? Theme.of(context).colorScheme.outline
                          : Theme.of(context).colorScheme.onErrorContainer,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.black45,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _showEnlargedQr(BuildContext context, String qrData, String eventTitle, String matrixNumber, String studentName) async {
    try {
      await ScreenBrightness().setApplicationScreenBrightness(1.0);
    } catch (e) {
      debugPrint('Failed to set brightness: $e');
    }

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                eventTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  backgroundColor: Colors.white,
                  size: 250,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                studentName,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ID: $matrixNumber',
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      await ScreenBrightness().resetApplicationScreenBrightness();
    } catch (e) {
      debugPrint('Failed to reset brightness: $e');
    }
  }
}
