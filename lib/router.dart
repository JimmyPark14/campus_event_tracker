import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
export 'screens/account_verification.dart';
export 'screens/alerts.dart';
import 'screens.dart';


import '../providers/auth_provider.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

GoRouter createAppRouter(AuthProvider authProvider) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isAuth = authProvider.isAuthenticated;
      final role = authProvider.userProfile?.role;
      final isLoggingIn = state.uri.path == '/login' || 
                          state.uri.path == '/organizer-login' || 
                          state.uri.path == '/sign-up' ||
                          state.uri.path == '/organization-setup' ||
                          state.uri.path == '/welcome-organizer';

      if (!isAuth) {
        return isLoggingIn ? null : '/login';
      }

      /*
      final isPhoneVerified = authProvider.userProfile?.isPhoneVerified ?? false;
      final isEmailVerified = authProvider.userProfile?.isEmailVerified ?? false;
      final isVerified = isPhoneVerified || isEmailVerified;
      final isVerificationRoute = state.uri.path == '/account-verification';

      // Require verification (DISABLED FOR TESTING)
      if (!isVerified && state.uri.path != '/organization-setup' && !isVerificationRoute && !isLoggingIn) {
        return '/account-verification';
      }
      
      // If logging in but not verified, send to verification instead of home
      if (isLoggingIn && !isVerified) {
        return '/account-verification';
      }

      // If already verified and trying to access verification screen, send home
      if (isVerified && isVerificationRoute) {
        return role == 'organizer' ? '/organizer/dashboard' : '/home';
      }
      */

      // Allow passing through organization setup even if auth is true but profile might not be fully synced yet
      if (state.uri.path == '/organization-setup') return null;

      if (isLoggingIn) {
        return role == 'organizer' ? '/organizer/dashboard' : '/home';
      }

      if (role == 'student' && state.uri.path.startsWith('/organizer') && !state.uri.path.startsWith('/organizer-profile')) {
        return '/home';
      }

      if (role == 'organizer') {
        final isStudentRoute = state.uri.path.startsWith('/home') || 
                               state.uri.path.startsWith('/my-events') ||
                               state.uri.path.startsWith('/alerts') ||
                               state.uri.path.startsWith('/profile');
        if (isStudentRoute) {
          return '/organizer/dashboard';
        }
      }

      return null;
    },
    routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const Login(),
    ),
    GoRoute(
      path: '/organizer-login',
      builder: (context, state) => const OrganizerLogin(),
    ),
    GoRoute(
      path: '/sign-up',
      builder: (context, state) => const SignUp(),
    ),
    GoRoute(
      path: '/terms',
      builder: (context, state) => const TermsOfService(),
    ),
    GoRoute(
      path: '/privacy',
      builder: (context, state) => const PrivacyPolicy(),
    ),
    GoRoute(
      path: '/pro-tips',
      builder: (context, state) => const ProTips(),
    ),
    GoRoute(
      path: '/welcome-organizer',
      builder: (context, state) => const WelcomeOrganizer(),
    ),
    GoRoute(
      path: '/export-data',
      builder: (context, state) => ExportDataScreen(
        eventId: state.uri.queryParameters['eventId'],
      ),
    ),
    GoRoute(
      path: '/file-viewer',
      builder: (context, state) => FileViewerScreen(
        format: state.uri.queryParameters['format'] ?? 'CSV',
        filePath: state.uri.queryParameters['filePath'] ?? '',
      ),
    ),
    GoRoute(
      path: '/discover',
      builder: (context, state) => const DiscoverEvents(),
    ),
    GoRoute(
      path: '/account-verification',
      builder: (context, state) => const AccountVerificationScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return BottomNavHost(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const Home(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/my-events',
              builder: (context, state) => const MyEvents(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/alerts',
              builder: (context, state) => const Alerts(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const StudentProfileSettings(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/event-detail/:id',
      builder: (context, state) => EventDetail(id: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: '/rsvp-confirm',
      builder: (context, state) => const RsvpConfirm(),
    ),
    GoRoute(
      path: '/digital-ticket/:id',
      builder: (context, state) => DigitalTicket(eventId: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: '/leaderboard',
      builder: (context, state) => const LeaderboardScreen(),
    ),
    GoRoute(
      path: '/event-chat/:id',
      builder: (context, state) => EventChatScreen(eventId: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: '/feedback-submitted',
      builder: (context, state) => const FeedbackSubmitted(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const Alerts(),
    ),
    GoRoute(
      path: '/organizer/event-detail/:id',
      builder: (context, state) => OrganizerEventDetail(id: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: '/organizer-profile/:id',
      builder: (context, state) => OrganizerProfileDetail(id: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: '/organizer/create-event',
      builder: (context, state) => const CreateEvent(),
    ),
    GoRoute(
      path: '/organizer/edit-event/:id',
      builder: (context, state) => CreateEvent(eventId: state.pathParameters['id']),
    ),
    GoRoute(
      path: '/organization-setup',
      builder: (context, state) => const OrganizationSetup(),
    ),
    GoRoute(
      path: '/ready-to-lead',
      builder: (context, state) => const ReadyToLead(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return BottomNavHostOrganizer(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/organizer/dashboard',
              builder: (context, state) => const OrganizerDashboard(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/organizer/events',
              builder: (context, state) => const OrganizerEvents(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/organizer/analytics',
              builder: (context, state) => const OverallAnalytics(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/organizer/profile',
              builder: (context, state) => const OrganizerProfileSettings(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/organizer/all-live-events',
      builder: (context, state) => const AllLiveEventsScreen(),
    ),

    GoRoute(
      path: '/notifications',
      builder: (context, state) => const Alerts(),
    ),
    GoRoute(
      path: '/attendance-checklist',
      builder: (context, state) => AttendanceChecklist(
        eventId: state.uri.queryParameters['eventId'],
      ),
    ),
    GoRoute(
      path: '/check-in-confirmation',
      builder: (context, state) => CheckInConfirmation(
        participantName: state.uri.queryParameters['name'],
        participantId: state.uri.queryParameters['id'],
        avatarUrl: state.uri.queryParameters['avatarUrl'],
      ),
    ),
    GoRoute(
      path: '/check-in-successful',
      builder: (context, state) => const CheckInSuccessful(),
    ),
    GoRoute(
      path: '/event-analytics/:id',
      builder: (context, state) => EventAnalytics(eventId: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: '/participant-roster',
      builder: (context, state) => ParticipantRoster(
        eventId: state.uri.queryParameters['eventId'],
      ),
    ),
    GoRoute(
      path: '/payment-verify',
      builder: (context, state) => PaymentVerify(
        eventId: state.uri.queryParameters['eventId'],
      ),
    ),
    GoRoute(
      path: '/refund-requests',
      builder: (context, state) => OrganizerRefundRequests(
        eventId: state.uri.queryParameters['eventId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/student-payment/:id',
      builder: (context, state) => StudentPayment(eventId: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: '/settings/student-billing',
      builder: (context, state) => const StudentPaymentBilling(),
    ),
    GoRoute(
      path: '/post-event-feedback/:id',
      builder: (context, state) => PostEventFeedback(eventId: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: '/qr-scan-check-in',
      builder: (context, state) => const QrScanCheckIn(),
    ),
    GoRoute(
      path: '/qr-scan-error',
      builder: (context, state) => QrScanError(
        participantName: state.uri.queryParameters['name'],
        participantId: state.uri.queryParameters['id'],
        avatarUrl: state.uri.queryParameters['avatarUrl'],
      ),
    ),
    GoRoute(
      path: '/qr-scan-success',
      builder: (context, state) => QrScanSuccess(
        participantName: state.uri.queryParameters['name'],
        participantId: state.uri.queryParameters['id'],
        avatarUrl: state.uri.queryParameters['avatarUrl'],
      ),
    ),
    GoRoute(
      path: '/settings/account',
      builder: (context, state) => const StudentAccountSettings(),
    ),
    GoRoute(
      path: '/settings/notifications',
      builder: (context, state) => const StudentNotificationPreferences(),
    ),
    GoRoute(
      path: '/settings/privacy',
      builder: (context, state) => const StudentPrivacySecurity(),
    ),
    GoRoute(
      path: '/settings/help',
      builder: (context, state) => const StudentHelpSupport(),
    ),
    GoRoute(
      path: '/organizer/settings/account',
      builder: (context, state) => const OrganizerAccountSettings(),
    ),
    GoRoute(
      path: '/organizer/settings/event-preferences',
      builder: (context, state) => const EventPreferences(),
    ),
    GoRoute(
      path: '/organizer/settings/team',
      builder: (context, state) => const TeamManagement(),
    ),
    GoRoute(
      path: '/organizer/settings/billing',
      builder: (context, state) => const PaymentBilling(),
    ),
    GoRoute(
      path: '/billing-history',
      builder: (context, state) => const BillingHistory(),
    ),
    GoRoute(
      path: '/organizer/settings/notifications',
      builder: (context, state) => const OrganizerNotificationPreferences(),
    ),
    GoRoute(
      path: '/organizer/settings/privacy',
      builder: (context, state) => const OrganizerPrivacySecurity(),
    ),
    GoRoute(
      path: '/organizer/settings/help',
      builder: (context, state) => const OrganizerHelpSupport(),
    ),
  ],
);
}
