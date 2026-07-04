import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';

// Entry point of the application.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Notifications
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();

  // Load theme settings from SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final themeModeString = prefs.getString('theme_mode') ?? 'system';
  ThemeMode initialThemeMode;
  if (themeModeString == 'light') {
    initialThemeMode = ThemeMode.light;
  } else if (themeModeString == 'dark') {
    initialThemeMode = ThemeMode.dark;
  } else {
    initialThemeMode = ThemeMode.system;
  }

  // Sign in anonymously
  final authService = AuthService();
  final user = await authService.signInAnonymously();

  // Verify monthly reset on launch
  if (user != null) {
    await _checkMonthlyReset(user.uid);
  }

  runApp(DuezyApp(uid: user?.uid, initialThemeMode: initialThemeMode));
}

// Reset bill statuses on monthly cycle rollover.
Future<void> _checkMonthlyReset(String uid) async {
  final prefs = await SharedPreferences.getInstance();
  final now = DateTime.now();
  final currentMonthKey = '${now.year}-${now.month}';
  final lastCheckedMonth = prefs.getString('last_checked_month');

  if (lastCheckedMonth != null && lastCheckedMonth != currentMonthKey) {
    final firestoreService = FirestoreService(uid: uid);
    await firestoreService.resetAllPaidStatus();
  }

  await prefs.setString('last_checked_month', currentMonthKey);
}

// Root application widget.
class DuezyApp extends StatefulWidget {
  final String? uid;
  final ThemeMode initialThemeMode;

  const DuezyApp({
    super.key,
    this.uid,
    required this.initialThemeMode,
  });

  @override
  State<DuezyApp> createState() => _DuezyAppState();
}

class _DuezyAppState extends State<DuezyApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
  }

  Future<void> _toggleTheme() async {
    final nextMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;

    setState(() {
      _themeMode = nextMode;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'theme_mode',
      nextMode == ThemeMode.light ? 'light' : 'dark',
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DueZy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: widget.uid != null
          ? HomeScreen(
              firestoreService: FirestoreService(uid: widget.uid!),
              themeMode: _themeMode,
              onThemeToggle: _toggleTheme,
            )
          : const _AuthErrorScreen(),
    );
  }
}

// Fallback screen shown when anonymous login fails.
class _AuthErrorScreen extends StatelessWidget {
  const _AuthErrorScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withAlpha(15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_off_rounded,
                  size: 56,
                  color: theme.colorScheme.error.withAlpha(160),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Could not connect',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'DueZy needs an internet connection for the first launch '
                'to set up your account. Please check your connection '
                'and restart the app.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(140),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  main();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
