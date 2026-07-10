import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../providers/registration_provider.dart';

class PaymentVerify extends StatefulWidget {
  final String? eventId;
  const PaymentVerify({super.key, this.eventId});

  @override
  State<PaymentVerify> createState() => _PaymentVerifyState();
}

class _PaymentVerifyState extends State<PaymentVerify> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _pendingRegistrations = [];
  List<Map<String, dynamic>> _verifiedRegistrations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRegistrations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRegistrations() async {
    if (widget.eventId == null) {
      setState(() { _isLoading = false; });
      return;
    }

    try {
      final registrationProvider = context.read<RegistrationProvider>();
      final pendingDocs = await registrationProvider.getPendingRegistrations(widget.eventId!);
      final verifiedDocs = await registrationProvider.getVerifiedRegistrations(widget.eventId!);

      final List<Map<String, dynamic>> pending = [];
      final List<Map<String, dynamic>> verified = [];

      Future<void> mapDocs(List<Map<String, dynamic>> docs, List<Map<String, dynamic>> targetList) async {
        for (var data in docs) {
          final userId = data['userId'] as String;
          final receiptBase64 = data.containsKey('receiptBase64') ? data['receiptBase64'] : '';

          // Fetch user info using AuthProvider or Firestore
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            final name = userData['name'] ?? 'Unknown Student';
            final initials = name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
            
            targetList.add({
              'registrationId': userId, // In the new schema, doc ID is userId
              'userId': userId,
              'name': name,
              'initials': initials,
              'receiptBase64': receiptBase64,
              'timestamp': data['timestamp'],
              'aiVerified': data['aiVerified'] ?? false,
              'aiReason': data['aiReason'] ?? '',
            });
          }
        }
      }

      await mapDocs(pendingDocs, pending);
      await mapDocs(verifiedDocs, verified);

      if (mounted) {
        setState(() {
          _pendingRegistrations = pending;
          _verifiedRegistrations = verified;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading registrations: $e');
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  void _showVerificationDialog(Map<String, dynamic> registration, bool isPending) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(registration['name']),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Payment Receipt:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (isPending && registration['aiReason'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: registration['aiVerified'] == true ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(registration['aiVerified'] == true ? Icons.verified : Icons.warning, 
                             color: registration['aiVerified'] == true ? Colors.green : Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(child: Text(registration['aiReason'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                ),
              if (registration['receiptBase64'] != null && registration['receiptBase64'].toString().isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    base64Decode(registration['receiptBase64']),
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No receipt uploaded.'),
                ),
            ],
          ),
          actions: isPending ? [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _processVerification(registration, false);
              },
              child: Text('Reject', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _processVerification(registration, true);
              },
              child: const Text('Approve'),
            ),
          ] : [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processVerification(Map<String, dynamic> registration, bool isApproved) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final regId = registration['registrationId'];
      final userId = registration['userId'];
      
      await FirebaseFirestore.instance.collection('registrations').doc(regId).update({
        'status': isApproved ? 'confirmed' : 'rejected',
      });
      if (!mounted) return;
      await context.read<EventProvider>().verifyPayment(widget.eventId!, userId, isApproved);
      
      if (mounted) {
        Navigator.pop(context); // Close loading
        await _loadRegistrations(); // Reload list
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isApproved ? 'Payment approved successfully.' : 'Payment rejected.'),
            backgroundColor: isApproved ? Colors.green : Colors.red,
          )
        );

        // Automatically go to the next pending person
        if (_pendingRegistrations.isNotEmpty) {
          _showVerificationDialog(_pendingRegistrations.first, true);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('An error occurred')));
      }
    }
  }

  Widget _buildList(List<Map<String, dynamic>> registrations, bool isPending) {
    if (registrations.isEmpty) {
      return Center(
        child: Text(
          isPending ? 'No pending payments.' : 'No verified payments.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: registrations.length,
      itemBuilder: (context, index) {
        final reg = registrations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isPending 
                  ? Theme.of(context).colorScheme.tertiaryContainer 
                  : Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                reg['initials'], 
                style: TextStyle(
                  color: isPending ? Theme.of(context).colorScheme.onTertiaryContainer : Theme.of(context).colorScheme.onPrimaryContainer
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(child: Text(reg['name'], style: const TextStyle(fontWeight: FontWeight.bold))),
                if (isPending && reg['aiVerified'] == true)
                  const Icon(Icons.verified, color: Colors.green, size: 20),
                if (isPending && reg['aiVerified'] == false && reg['aiReason'].toString().isNotEmpty)
                  const Icon(Icons.warning, color: Colors.orange, size: 20),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID: ${(reg['userId'].hashCode.abs() % 100000000).toString().padLeft(8, '0')}'),
                if (isPending && reg['aiReason'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      reg['aiReason'], 
                      style: TextStyle(color: reg['aiVerified'] == true ? Colors.green : Colors.orange, fontSize: 12),
                    ),
                  ),
              ],
            ),
            trailing: isPending ? ElevatedButton(
              onPressed: () => _showVerificationDialog(reg, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
              child: const Text('Verify'),
            ) : TextButton(
              onPressed: () => _showVerificationDialog(reg, false),
              child: const Text('View Receipt'),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Payment Verification'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Verified'),
          ],
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_pendingRegistrations, true),
                _buildList(_verifiedRegistrations, false),
              ],
            ),
    );
  }
}
