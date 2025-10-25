import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/di/injection_container.dart';
import 'features/vehicle/presentation/providers/vehicle_provider.dart';
import 'features/charging_stats/presentation/providers/charging_stats_provider.dart';
import 'features/charging_stats/presentation/providers/smart_charging_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'utils/app_theme.dart';
import 'web/web_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // If .env file doesn't exist, use default values
    print('Warning: .env file not found. Using default values.');
  }

  // Initialize Firebase (optional - will fall back to mock data if not configured)
  try {
    await Firebase.initializeApp();
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization skipped: $e');
    print('Using mock data mode for charging stats');
  }

  // Initialize dependency injection
  await initializeDependencies();

  // Set preferred orientations (skip on web as it's not applicable)
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  runApp(const TessieApp());
}

class TessieApp extends StatelessWidget {
  const TessieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => sl<AuthProvider>()),
        ChangeNotifierProvider(create: (_) => sl<VehicleProvider>()),
        ChangeNotifierProvider(create: (_) => sl<ChargingStatsProvider>()),
        ChangeNotifierProvider(create: (_) => SmartChargingProvider()),
      ],
      child: MaterialApp(
        title: 'Tessie',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: kIsWeb
            ? const WebShell(child: SplashScreen())
            : const SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _controller.forward();

    // Check authentication and navigate appropriately
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.initializeAuth();

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.darkBackground,
              AppTheme.cardBackground,
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryBlue.withOpacity(0.2),
                        ),
                        child: const Icon(
                          Icons.electric_car,
                          size: 80,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Tessie',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Control your Tesla',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
