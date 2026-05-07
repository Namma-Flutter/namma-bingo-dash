import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
import 'const/app_colors.dart';
import 'screens/connections_screen.dart';
import 'screens/home_screen.dart';
import 'screens/enhanced_profile_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/qr_generator_screen.dart';
import 'screens/shell_screen.dart';
import 'screens/webview_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  runApp(const ProviderScope(child: MyApp()));
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => ShellScreen(child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/connections',
          builder: (context, state) => const ConnectionsScreen(),
        ),
        GoRoute(
          path: '/qr-generator',
          builder: (context, state) => const QrGeneratorScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const EnhancedProfileScreen(),
    ),
    GoRoute(
      path: '/camera',
      builder: (context, state) =>
          CameraScreen(args: state.extra as Map<String, dynamic>?),
    ),
    GoRoute(
      path: '/webview',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return NammaWebView(
          url: extra?['url'] ?? 'https://nammaflutter.com/',
          title: extra?['title'] ?? 'Namma Flutter',
        );
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Bingo QR Connector',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          brightness: Brightness.dark,
          surface: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 4,
            textStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardBackground,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
