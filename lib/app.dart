import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'utils/logger.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'KAAPAV',
      theme: KaapavTheme.lightTheme,
      darkTheme: KaapavTheme.darkTheme,
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      navigatorKey: AppRoutes.navigatorKey,
      onGenerateRoute: AppRoutes.generateRoute,
      home: _AppShell(authStatus: authState.status),
    );
  }
}

class _AppShell extends ConsumerStatefulWidget {
  final AuthStatus authStatus;
  const _AppShell({required this.authStatus});

  @override
  ConsumerState<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<_AppShell>
    with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Wire notification tap → open chat
    NotificationService.instance.onNotificationTap = (phone) {
      AppRoutes.openChatFromService(phone);
    };
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
void didChangeAppLifecycleState(AppLifecycleState state) {
  final auth = ref.read(authProvider);
  
  switch (state) {
    case AppLifecycleState.paused:
    case AppLifecycleState.inactive:
    case AppLifecycleState.hidden:
      // ✅ INSTANT LOCK when switching apps
      if (auth.status == AuthStatus.authenticated) {
        AppLogger.info('🔐 App backgrounded → locking immediately');
        ref.read(authProvider.notifier).lockApp();
      }
      break;
      
    case AppLifecycleState.resumed:
      AppLogger.info('🔐 App resumed');
      break;
      
    case AppLifecycleState.detached:
      ref.read(authProvider.notifier).lockApp();
      break;
  }
}

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _buildHome(widget.authStatus),
    );
  }

  Widget _buildHome(AuthStatus status) {
    switch (status) {
      case AuthStatus.authenticated:
        return const HomeScreen();
      case AuthStatus.locked:
      case AuthStatus.initializing:
        return const LoginScreen();
    }
  }
}