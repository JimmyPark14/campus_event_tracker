import 'package:flutter/material.dart';
import 'terms_of_service.dart';
import 'privacy_policy.dart';

class StudentHelpSupport extends StatelessWidget {
  const StudentHelpSupport({super.key});

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
                Icon(
                  Icons.support_agent,
                  size: 48,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(height: 16),
                Text(
                  'How can we help you?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _showContactDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
              Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsOfService(isOrganizer: false)));
            },
          ),
          ListTile(
            leading: Icon(Icons.privacy_tip, color: Theme.of(context).colorScheme.primary),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicy(isOrganizer: false)));
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
          _buildFAQ(
            context,
            'How do I cancel my registration?',
            'You can cancel your registration by going to the Event Details page and tapping "Cancel Registration".',
          ),
          _buildFAQ(
            context,
            'Where can I find my digital ticket?',
            'Your digital ticket is available under "My Events". Tap the QR code icon next to the event.',
          ),
          _buildFAQ(
            context,
            'How do waitlists work?',
            'If an event is full, you can join the waitlist. If a spot opens up, you will receive a notification to claim your spot.',
          ),
          _buildFAQ(
            context,
            'How do I contact an event organizer?',
            'You can contact the organizer directly from the Event Details page by tapping on their profile.',
          ),
          _buildFAQ(
            context,
            'Can I bring a plus one?',
            'This depends on the event. Check the "Guest Policy" section in the Event Details.',
          ),
          _buildFAQ(
            context,
            'How do I change my profile information?',
            'Go to Profile & Settings, then select Account Settings to update your details.',
          ),
          _buildFAQ(
            context,
            'What if I miss an event I registered for?',
            'If you miss an event, you may be marked as a no-show. Frequent no-shows could affect your ability to register for future events.',
          ),
          _buildFAQ(
            context,
            'How do I earn points?',
            'You earn points by attending events. Make sure the organizer scans your QR code when you arrive!',
          ),
          _buildFAQ(
            context,
            'Are events free?',
            'Many campus events are free, but some may require a fee. Check the "Price" section on the Event Details page.',
          ),
          _buildFAQ(
            context,
            'Can I see my past events?',
            'Yes! Go to the "My Events" tab and switch to the "Past" view to see all the events you\'ve attended.',
          ),
          const SizedBox(height: 48),
          Center(
            child: Text(
              'App Version 1.2.4',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
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
          title: Text(
            question,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
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
                  leading: Icon(
                    Icons.email,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Email Support'),
                  subtitle: const Text('cet@support.com'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening email client...')),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.phone,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Call Us'),
                  subtitle: const Text('(+60)12-3456789'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Calling support...')),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.chat,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Live Chat'),
                  subtitle: const Text('Usually replies in 5m'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Starting live chat...')),
                    );
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
