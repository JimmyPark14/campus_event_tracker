import 'package:flutter/material.dart';

class TermsOfService extends StatelessWidget {
  final bool isOrganizer;
  const TermsOfService({super.key, this.isOrganizer = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(isOrganizer ? 'Organizer Terms of Service' : 'Student Terms of Service'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last Updated: June 2026',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            if (isOrganizer) ...[
              _buildSection(context,
                title: '1. Organizer Account',
                content: 'You are responsible for managing your organizer account securely. Only authorized representatives of your student organization or university department may create an organizer account.',
              ),
              const SizedBox(height: 24),
              _buildSection(context,
                title: '2. Event Creation & Management',
                content: 'Organizers must ensure that their events comply with university policies and local regulations. Organizers are responsible for accurately describing events and managing attendance.',
              ),
              const SizedBox(height: 24),
              _buildSection(context,
                title: '3. Ticket Sales',
                content: 'For paid events, organizers agree to the platform\'s fee structure.',
              ),
              const SizedBox(height: 24),
              _buildSection(context,
                title: '4. Refund Processing',
                content: 'Organizers are responsible for reviewing and processing refund requests. All approved refunds are subject to a 25% processing fee deduction from the original payment amount.',
              ),
              const SizedBox(height: 24),
              _buildSection(context,
                title: '5. Data Privacy',
                content: 'Organizers must respect the privacy of attendees and only use attendee data for event management and related communications.',
              ),
            ] else ...[
              _buildSection(context,
                title: '1. Acceptance of Terms',
                content: 'By accessing and using Campus Event Tracker, you agree to be bound by these Terms of Service. If you do not agree to all the terms and conditions, you may not access or use the platform.',
              ),
              const SizedBox(height: 24),
              _buildSection(context,
                title: '2. User Accounts',
                content: 'You are responsible for safeguarding the password that you use to access the service and for any activities or actions under your password. You agree not to disclose your password to any third party.',
              ),
              const SizedBox(height: 24),
              _buildSection(context,
                title: '3. Event Registration',
                content: 'When registering for events, you agree to provide accurate and complete information. Organizers reserve the right to cancel your registration if the information provided is found to be false.',
              ),
              const SizedBox(height: 24),
              _buildSection(context,
                title: '4. Refund Policy',
                content: 'All approved refunds are subject to a 25% processing fee deduction from the original payment amount. You will receive 75% of your payment. Refunds cannot be requested less than 24 hours before the event.',
              ),
              const SizedBox(height: 24),
              _buildSection(context,
                title: '5. Prohibited Conduct',
                content: 'You agree not to engage in any activity that interferes with or disrupts the service, or attempts to access the service using a method other than the interface and instructions we provide.',
              ),
            ],
            const SizedBox(height: 48),
            Center(
              child: Text(
                'If you have any questions about these Terms, please contact support@campuseventtracker.edu',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
