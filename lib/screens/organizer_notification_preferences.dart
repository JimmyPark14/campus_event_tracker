import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class OrganizerNotificationPreferences extends StatefulWidget {
  const OrganizerNotificationPreferences({super.key});

  @override
  State<OrganizerNotificationPreferences> createState() => _OrganizerNotificationPreferencesState();
}

class _OrganizerNotificationPreferencesState extends State<OrganizerNotificationPreferences> {
  late Map<String, bool> _prefs;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final userPrefs = context.read<AuthProvider>().userProfile?.preferences ?? {};
    _prefs = {
      'Push Notifications': userPrefs['Push Notifications'] ?? true,
      'Email Notifications': userPrefs['Email Notifications'] ?? true,
      'New Attendee Signups': userPrefs['New Attendee Signups'] ?? true,
      'Event Reminders': userPrefs['Event Reminders'] ?? true,
      'Daily Summaries': userPrefs['Daily Summaries'] ?? false,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          'Notifications',
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
          _buildSectionHeader('Delivery Methods'),
          _buildSwitchTile('Push Notifications', 'Receive alerts on your device'),
          _buildSwitchTile('Email Notifications', 'Receive updates via email'),
          const SizedBox(height: 24),
          _buildSectionHeader('Event Alerts'),
          _buildSwitchTile('New Attendee Signups', 'When someone RSVPs'),
          _buildSwitchTile('Event Reminders', '24 hours before your events'),
          const SizedBox(height: 12),
          _buildSwitchTile('Daily Summaries', 'Summary of ticket sales and stats'),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: _isLoading ? null : () async {
              setState(() => _isLoading = true);
              try {
                final authProvider = context.read<AuthProvider>();
                final uid = authProvider.firebaseUser?.uid;
                if (uid != null) {
                  await FirebaseFirestore.instance.collection('users').doc(uid).set({
                    'preferences': {
                      'Push Notifications': _prefs['Push Notifications'],
                      'Email Notifications': _prefs['Email Notifications'],
                      'New Attendee Signups': _prefs['New Attendee Signups'],
                      'Event Reminders': _prefs['Event Reminders'],
                      'Daily Summaries': _prefs['Daily Summaries'],
                    }
                  }, SetOptions(merge: true));
                  await authProvider.reloadProfile();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notification preferences saved successfully')),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving preferences: $e')),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isLoading 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
        value: _prefs[title] ?? false,
        activeThumbColor: Theme.of(context).colorScheme.primary,
        onChanged: (bool val) {
          setState(() {
            _prefs[title] = val;
          });
        },
      ),
    );
  }
}
