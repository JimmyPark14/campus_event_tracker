import 'package:flutter/material.dart';

class PrivacyPolicy extends StatelessWidget {
  final bool isOrganizer;
  const PrivacyPolicy({super.key, this.isOrganizer = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(isOrganizer ? 'Organizer Privacy Policy' : 'Student Privacy Policy'),
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
                title: '1. Information We Collect from Organizers',
                content: 'We collect information you provide directly to us, such as your organization name, contact details, and event data.',
              ),
              const SizedBox(height: 24),
              _buildSection(context,
                title: '2. How We Use Organizer Information',
                content: 'We use the information we collect to verify your organization, process ticket sales, and provide analytics on your events.',
              ),
              const SizedBox(height: 24),
              _buildSection(context,
                title: '3. Attendee Data Access',
                content: 'Organizers have access to basic attendee data (name, email, student ID) for the sole purpose of event management, check-in, and communications. This data must not be sold or used for unrelated marketing.',
              ),
              const SizedBox(height: 24),
              _buildSection(context,
                title: '4. Data Security',
                content: 'We implement appropriate technical and organizational measures to protect your organization and attendee data against unauthorized access or disclosure.',
              ),
            ] else ...[
              _buildSection(context,
                title: '1. Information We Collect',
                content: 'We collect information you provide directly to us, such as your name, email address, and student ID when you create an account.',
              ),
              const SizedBox(height: 24),
              _buildSection(context,
                title: '2. How We Use Your Information',
                content: 'We use the information we collect to provide, maintain, and improve our services, as well as to communicate with you about events and updates.',
              ),
              const SizedBox(height: 24),
              _buildSection(context,
                title: '3. Data Security',
                content: 'We implement appropriate technical and organizational measures to protect your personal information against unauthorized access or disclosure.',
              ),
              const SizedBox(height: 24),
              _buildSection(context,
                title: '4. Your Rights',
                content: 'You have the right to access, correct, or delete your personal data. You can manage most of this information directly within your account settings.',
              ),
              const SizedBox(height: 24),
              _buildSection(context,
                title: '5. Refund Policy',
                content: 'All approved refunds are subject to a 25% processing fee deduction from the original payment amount. You will receive 75% of your payment. Refunds cannot be requested less than 24 hours before the event.',
              ),
            ],
            const SizedBox(height: 48),
            Center(
              child: Text(
                'If you have any questions about this Privacy Policy, please contact privacy@campuseventtracker.edu',
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
