import 'package:flutter/material.dart';
import 'terms_of_service.dart';
import 'privacy_policy.dart';

class OrganizerHelpSupport extends StatelessWidget {
  const OrganizerHelpSupport({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          'Help & Support',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(Icons.support_agent, size: 48, color: Theme.of(context).colorScheme.onPrimaryContainer),
                const SizedBox(height: 16),
                Text('How can we help you?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimaryContainer)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _showContactDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Contact Us'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'POLICIES & TERMS',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.description, color: Theme.of(context).colorScheme.primary),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsOfService(isOrganizer: true)));
            },
          ),
          ListTile(
            leading: Icon(Icons.privacy_tip, color: Theme.of(context).colorScheme.primary),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicy(isOrganizer: true)));
            },
          ),
          const SizedBox(height: 32),
          Text(
            'FREQUENTLY ASKED QUESTIONS',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildFAQ(context, 'How do I refund a ticket?', 'Refunds can be issued from the Event Details page under "Transactions".'),
          _buildFAQ(context, 'Can I add co-organizers?', 'Yes! Go to Team Management to invite others to help manage your events.'),

          _buildFAQ(context, 'How do I scan QR codes for check-in?', 'Tap the QR scanner icon on your dashboard to open the built-in scanner.'),
          _buildFAQ(context, 'Can I export the attendee list?', 'Yes, you can export a CSV of all attendees from the Participant Roster page.'),
          _buildFAQ(context, 'How do I edit an event?', 'Navigate to the Event Details page of your event and tap the Edit icon in the top right corner.'),
          _buildFAQ(context, 'Can I message attendees?', 'Yes, you can send an announcement to all registered attendees from the Event Management dashboard.'),
          _buildFAQ(context, 'How do I handle walk-ins?', 'On the Participant Roster page, tap "Add Walk-in" to manually register someone at the door.'),
          _buildFAQ(context, 'What if an event is cancelled?', 'If you cancel an event, all attendees will be automatically notified. Any paid tickets will be queued for refunds.'),
          _buildFAQ(context, 'How do I track attendance statistics?', 'After your event ends, the Event Details page will display a breakdown of attendance and demographic stats.'),
          const SizedBox(height: 48),
          Center(
            child: Text('App Version 1.2.4', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQ(BuildContext context, String question, String answer) {
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
      child: Material(
        color: Colors.transparent,
        child: ExpansionTile(
          title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(answer, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Contact Support'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('How would you like to reach us?'),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.email, color: Theme.of(context).colorScheme.primary),
                  title: const Text('Email Support'),
                  subtitle: const Text('cet@support.com'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening email client...')));
                  },
                ),
                ListTile(
                  leading: Icon(Icons.phone, color: Theme.of(context).colorScheme.primary),
                  title: const Text('Call Us'),
                  subtitle: const Text('(+60)12-3456789'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Calling support...')));
                  },
                ),
                ListTile(
                  leading: Icon(Icons.chat, color: Theme.of(context).colorScheme.primary),
                  title: const Text('Live Chat'),
                  subtitle: const Text('Usually replies in 5m'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Starting live chat...')));
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
