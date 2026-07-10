import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/event_provider.dart';

class PaymentBilling extends StatefulWidget {
  const PaymentBilling({super.key});

  @override
  State<PaymentBilling> createState() => _PaymentBillingState();
}

class _PaymentBillingState extends State<PaymentBilling> {
  final TextEditingController _bankNameController = TextEditingController();
  bool _isSavingName = false;

  @override
  void dispose() {
    _bankNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final uid = authProvider.firebaseUser?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          'Payment History',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, userSnapshot) {
          return ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              Text(
                'DUITNOW QR',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildDuitNowSection(context),
              
              const SizedBox(height: 48),
              
              Text(
                'PAYMENT HISTORY',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildPaymentHistorySection(context, uid),
            ],
          );
        }
      ),
    );
  }

  Widget _buildDuitNowSection(BuildContext context) {
    final userProfile = context.watch<AuthProvider>().userProfile;
    final hasQr = userProfile != null && userProfile.duitNowQrBase64.isNotEmpty;

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bank Account Verification Name',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _bankNameController..text = (userProfile?.bankAccountName ?? ''),
            decoration: InputDecoration(
              hintText: 'Enter exact name as it appears on receipts',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: _isSavingName ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ) : IconButton(
                icon: const Icon(Icons.save),
                onPressed: () => _saveBankName(context),
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (hasQr)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: MemoryImage(base64Decode(userProfile.duitNowQrBase64)),
                  fit: BoxFit.contain,
                ),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.qr_code_2, size: 48, color: Colors.grey),
              ),
            ),
          ElevatedButton.icon(
            onPressed: () => _uploadDuitNowQr(context),
            icon: const Icon(Icons.upload),
            label: Text(hasQr ? 'Update DuitNow QR (Max 1MB)' : 'Upload DuitNow QR (Max 1MB)'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveBankName(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.firebaseUser?.uid;
    if (uid != null) {
      setState(() { _isSavingName = true; });
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'bankAccountName': _bankNameController.text.trim(),
      });
      await authProvider.reloadProfile();
      if (context.mounted) {
        setState(() { _isSavingName = false; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bank account name saved')));
      }
    }
  }

  Future<void> _uploadDuitNowQr(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final picker = ImagePicker();
    final primaryColor = Theme.of(context).colorScheme.primary;
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Crop DuitNow QR',
              toolbarColor: primaryColor,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true),
          IOSUiSettings(
            title: 'Crop DuitNow QR',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
        maxWidth: 400, // Slightly larger for better QR scannability
        maxHeight: 400,
        compressQuality: 70,
      );

      if (croppedFile != null) {
        final bytes = await File(croppedFile.path).readAsBytes();
        final base64String = base64Encode(bytes);

        final uid = authProvider.firebaseUser?.uid;
        if (uid != null) {
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'duitNowQrBase64': base64String,
          });
          await authProvider.reloadProfile();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('DuitNow QR saved successfully')));
          }
        }
      }
    }
  }

  Widget _buildPaymentHistorySection(BuildContext context, String uid) {
    final eventProvider = context.watch<EventProvider>();
    final now = DateTime.now();
    
    // Filter events: created by this organizer, requires payment, and has ended
    final pastPaidEvents = eventProvider.events.where((e) {
      if (e.organizerId != uid) return false;
      if (e.price <= 0) return false;
      
      // Determine if event has ended
      try {
        final endTimeStr = e.time.split(' - ').length > 1 ? e.time.split(' - ')[1] : e.time;
        // Parse endTime assuming format like "2:00 PM"
        final format = DateFormat("hh:mm a");
        final endTime = format.parse(endTimeStr);
        final endDateTime = DateTime(e.date.year, e.date.month, e.date.day, endTime.hour, endTime.minute);
        
        return endDateTime.isBefore(now);
      } catch (err) {
        // Fallback: just use date
        return e.date.isBefore(DateTime(now.year, now.month, now.day));
      }
    }).toList();

    // Sort by most recent first
    pastPaidEvents.sort((a, b) => b.date.compareTo(a.date));

    if (pastPaidEvents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('No payment history available yet. Events must be paid and ended to appear here.', textAlign: TextAlign.center),
        ),
      );
    }

    return Column(
      children: pastPaidEvents.map((event) {
        final confirmedCount = event.registeredUserIds.length;
        final totalCollected = confirmedCount * event.price;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'RM${totalCollected.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.primary
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('MMM d, yyyy').format(event.date),
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.people, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      '$confirmedCount paid',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
