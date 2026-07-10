import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import 'alerts.dart';

class BottomNavHost extends StatelessWidget {
  const BottomNavHost({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      extendBody: true, // Allows the body to extend behind the floating nav bar
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            child: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _goBranch,
              backgroundColor: Colors.transparent,
              indicatorColor: Theme.of(context).colorScheme.primaryContainer,
              indicatorShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              height: 64,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  );
                }
                return Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                );
              }),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home, color: Theme.of(context).colorScheme.primary),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month, color: Theme.of(context).colorScheme.primary),
                  label: 'Events',
                ),
                NavigationDestination(
                  icon: ValueListenableBuilder<bool>(
                    valueListenable: globalHasUnreadNotifications,
                    builder: (context, hasUnread, child) {
                      return hasUnread
                          ? Badge(
                              backgroundColor: Theme.of(context).colorScheme.error,
                              smallSize: 8,
                              child: const Icon(Icons.notifications_outlined),
                            )
                          : const Icon(Icons.notifications_outlined);
                    },
                  ),
                  selectedIcon: ValueListenableBuilder<bool>(
                    valueListenable: globalHasUnreadNotifications,
                    builder: (context, hasUnread, child) {
                      return hasUnread
                          ? Badge(
                              backgroundColor: Theme.of(context).colorScheme.error,
                              smallSize: 8,
                              child: Icon(Icons.notifications, color: Theme.of(context).colorScheme.primary),
                            )
                          : Icon(Icons.notifications, color: Theme.of(context).colorScheme.primary);
                    },
                  ),
                  label: 'Alerts',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
