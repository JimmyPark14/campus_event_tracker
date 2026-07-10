import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../widgets/user_list_sheet.dart';
import '../providers/auth_provider.dart';
import '../providers/event_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/dynamic_avatar.dart';

class OrganizerProfileSettings extends StatelessWidget {
  const OrganizerProfileSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final userProfile = context.watch<AuthProvider>().userProfile;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Profile & Settings',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 16.0,
          top: 24.0,
          right: 16.0,
          bottom: 96.0,
        ),
        child: Column(
          children: [
            // Hero Profile Area
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  DynamicAvatar(
                    name: userProfile?.name,
                    avatarUrl: userProfile?.avatarUrl,
                    radius: 64,
                    fontSize: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userProfile?.name ?? 'Loading...',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userProfile?.email ?? 'Loading...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Lead Event Organizer',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Divider(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Consumer<EventProvider>(
                    builder: (context, eventProvider, _) {
                      final userId = userProfile?.uid ?? '';
                      final eventCount = eventProvider
                          .getOrganizerEvents(userId)
                          .length;
                      final events = eventProvider.getOrganizerEvents(userId);
                      final avgRating = events.isEmpty
                          ? 0.0
                          : events.fold<double>(
                                  0,
                                  (sum, e) => sum + e.averageRating,
                                ) /
                                events.length;

                      return Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                final followers = userProfile?.followers ?? [];
                                UserListSheet.show(
                                  context,
                                  title: 'Followers',
                                  userIds: followers,
                                  emptyMessage:
                                      'You don\'t have any followers yet.',
                                );
                              },
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.people_outline,
                                        size: 16,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${userProfile?.followers.length ?? 0}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Followers',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 32,
                            color: Theme.of(
                              context,
                            ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '$eventCount',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                ),
                                Text(
                                  'Events Hosted',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 32,
                            color: Theme.of(
                              context,
                            ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  avgRating > 0
                                      ? avgRating.toStringAsFixed(1)
                                      : '-',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 14,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.secondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Rating',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Appearance
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    ),
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
                    child: SwitchListTile(
                      title: Text(
                        'Dark Mode',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        'Toggle application theme',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      secondary: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.tertiaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.dark_mode,
                          color: Theme.of(
                            context,
                          ).colorScheme.onTertiaryContainer,
                          size: 20,
                        ),
                      ),
                      value: themeProvider.isDarkMode,
                      onChanged: (value) {
                        final authProvider = context.read<AuthProvider>();
                        themeProvider.toggleTheme(
                          value,
                          authProvider.firebaseUser?.uid,
                        );
                      },
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Settings List
            _buildSettingsGroup(
              context,
              title: 'Settings & Support',
              items: [
                _SettingsItem(
                  icon: Icons.manage_accounts,
                  iconBgColor: Theme.of(context).colorScheme.primaryContainer,
                  iconColor: Theme.of(context).colorScheme.onPrimaryContainer,
                  title: 'Account Settings',
                  subtitle: 'Update personal information',
                  route: '/organizer/settings/account',
                ),
                _SettingsItem(
                  icon: Icons.event_available,
                  iconBgColor: Theme.of(context).colorScheme.secondaryContainer,
                  iconColor: Theme.of(context).colorScheme.onSecondaryContainer,
                  title: 'Event Preferences',
                  subtitle: 'Default settings for new events',
                  route: '/organizer/settings/event-preferences',
                ),
                _SettingsItem(
                  icon: Icons.groups,
                  iconBgColor: Theme.of(context).colorScheme.tertiaryContainer,
                  iconColor: Theme.of(context).colorScheme.onTertiaryContainer,
                  title: 'Team Management',
                  subtitle: 'Manage co-organizers and staff',
                  route: '/organizer/settings/team',
                ),
                _SettingsItem(
                  icon: Icons.payments,
                  iconBgColor: Theme.of(
                    context,
                  ).colorScheme.surfaceTint.withValues(alpha: 0.2),
                  iconColor: Theme.of(context).colorScheme.surfaceTint,
                  title: 'QR & Payment History',
                  subtitle: 'Upload QR code & check history',
                  route: '/organizer/settings/billing',
                ),
                _SettingsItem(
                  icon: Icons.notifications_active,
                  iconBgColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.5),
                  iconColor: Theme.of(context).colorScheme.primary,
                  title: 'Notification Preferences',
                  subtitle: 'Manage alerts and emails',
                  route: '/organizer/settings/notifications',
                ),
                _SettingsItem(
                  icon: Icons.shield,
                  iconBgColor: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer.withValues(alpha: 0.5),
                  iconColor: Theme.of(context).colorScheme.secondary,
                  title: 'Privacy & Security',
                  subtitle: 'Passwords, 2FA, data sharing',
                  route: '/organizer/settings/privacy',
                ),
                _SettingsItem(
                  icon: Icons.help_center,
                  iconBgColor: Theme.of(context).colorScheme.surfaceTint,
                  iconColor: Theme.of(context).colorScheme.onPrimary,
                  title: 'Help & Support',
                  subtitle: 'FAQs, contact us, app guide',
                  route: '/organizer/settings/help',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Log Out
            ElevatedButton.icon(
              onPressed: () async {
                await context.read<AuthProvider>().signOut();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Log Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                ),
                elevation: 1,
                textStyle: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
            const SizedBox(height: 100), // Bottom padding for nav
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(
    BuildContext context, {
    required String title,
    required List<_SettingsItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
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
            child: ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  onTap: () => context.push(item.route),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: item.iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.icon, color: item.iconColor, size: 22),
                  ),
                  title: Text(
                    item.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    item.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String route;

  _SettingsItem({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.route,
  });
}
