import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'router.dart';
import 'theme.dart';
import 'providers/auth_provider.dart';
import 'providers/event_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/registration_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/team_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/user_cache_provider.dart';

import 'services/notification_service.dart';
import 'services/update_service.dart';
import 'widgets/update_dialog.dart';

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  
  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await NotificationService().init();

  final authProvider = AuthProvider();
  await authProvider.ensureInitialized();

  runApp(CampusEventTrackerApp(authProvider: authProvider));
}

class CampusEventTrackerApp extends StatefulWidget {
  final AuthProvider authProvider;
  const CampusEventTrackerApp({super.key, required this.authProvider});

  @override
  State<CampusEventTrackerApp> createState() => _CampusEventTrackerAppState();
}

class _CampusEventTrackerAppState extends State<CampusEventTrackerApp> {
  late final EventProvider _eventProvider;
  late final ThemeProvider _themeProvider;
  late final RegistrationProvider _registrationProvider;
  late final ChatProvider _chatProvider;
  late final TeamProvider _teamProvider;
  late final NotificationProvider _notificationProvider;
  late final UserCacheProvider _userCacheProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _eventProvider = EventProvider();
    _themeProvider = ThemeProvider();
    _registrationProvider = RegistrationProvider();
    _chatProvider = ChatProvider();
    _teamProvider = TeamProvider();
    _notificationProvider = NotificationProvider();
    _userCacheProvider = UserCacheProvider();
    _router = createAppRouter(widget.authProvider);
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    // Wait a few seconds for the app to settle and router to mount
    await Future.delayed(const Duration(seconds: 3));
    final updateService = UpdateService();
    final result = await updateService.checkForUpdates();
    
    if (result['updateAvailable'] == true) {
      final context = rootNavigatorKey.currentContext;
      if (context != null && context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false, // Prevents closing by tapping outside
          builder: (ctx) => UpdateDialog(
            apkUrl: result['apkUrl'],
            latestVersion: result['latestVersion'],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.authProvider),
        ChangeNotifierProvider.value(value: _eventProvider),
        ChangeNotifierProvider.value(value: _registrationProvider),
        ChangeNotifierProvider.value(value: _chatProvider),
        ChangeNotifierProvider.value(value: _teamProvider),
        ChangeNotifierProvider.value(value: _notificationProvider),
        ChangeNotifierProvider.value(value: _userCacheProvider),
        ChangeNotifierProxyProvider<AuthProvider, ThemeProvider>(
          create: (_) => _themeProvider,
          update: (_, auth, theme) {
            theme ??= _themeProvider;
            theme.loadFromUser(auth.userProfile);
            return theme;
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: 'Campus Event Tracker',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            scrollBehavior: MyCustomScrollBehavior(),
            routerConfig: _router,
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              final mediaQueryData = MediaQuery.of(context);
              
              // Prevent the app from scaling text too large based on phone accessibility settings
              // which can make everything look huge compared to the emulator.
              final clampedMediaQuery = mediaQueryData.copyWith(
                textScaler: mediaQueryData.textScaler.clamp(minScaleFactor: 0.8, maxScaleFactor: 1.05),
              );

              return MediaQuery(
                data: clampedMediaQuery,
                child: Column(
                children: [
                  Expanded(child: child ?? const SizedBox.shrink()),
                    StreamBuilder<List<ConnectivityResult>>(
                      stream: Connectivity().onConnectivityChanged,
                      builder: (context, snapshot) {
                        final results = snapshot.data ?? [ConnectivityResult.none];
                        final isOffline = results.every((r) => r == ConnectivityResult.none);
                        
                        if (isOffline) {
                          return Material(
                            child: Container(
                              color: Theme.of(context).colorScheme.error,
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              child: SafeArea(
                                top: false,
                                child: Text(
                                  'You are currently offline.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onError,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
