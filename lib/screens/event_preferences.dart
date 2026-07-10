import 'package:flutter/material.dart';

class EventPreferences extends StatefulWidget {
  const EventPreferences({super.key});

  @override
  State<EventPreferences> createState() => _EventPreferencesState();
}

class _EventPreferencesState extends State<EventPreferences> {
  bool _requireRsvp = true;
  bool _makePublic = true;
  bool _sendReminders = true;
  late final TextEditingController _capacityController;

  @override
  void initState() {
    super.initState();
    _capacityController = TextEditingController(text: '100');
  }

  @override
  void dispose() {
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          'Event Preferences',
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
          _buildSectionHeader('Default Settings'),
          _buildSwitchTile(
            'Require RSVP by default',
            'Attendees must register to join',
            _requireRsvp,
            (val) => setState(() => _requireRsvp = val),
          ),
          const SizedBox(height: 8),
          _buildSwitchTile(
            'Make events public',
            'Show events on the discover page',
            _makePublic,
            (val) => setState(() => _makePublic = val),
          ),
          const SizedBox(height: 8),
          _buildSwitchTile(
            'Send 24h reminders',
            'Automatically email attendees',
            _sendReminders,
            (val) => setState(() => _sendReminders = val),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Capacity & Limits'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _capacityController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Default Event Capacity',
              prefixIcon: Icon(Icons.people_alt_outlined, color: Theme.of(context).colorScheme.primary),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
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

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
        value: value,
        activeThumbColor: Theme.of(context).colorScheme.primary,
        onChanged: onChanged,
      ),
    );
  }
}
