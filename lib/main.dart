import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';
import 'constants.dart';
import 'state/app_state.dart';
import 'models/resume_record.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/capture_screen.dart';
import 'screens/review_screen.dart';
import 'screens/records_list_screen.dart';
import 'screens/record_detail_screen.dart';
import 'screens/sync_screen.dart';
import 'screens/qr_result_screen.dart';

import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize(); // no-op if not configured
  final appState = AppState();
  await appState.load();
  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: const FairTrackApp(),
    ),
  );
}

class FairTrackApp extends StatelessWidget {
  const FairTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: SupabaseService.currentUser != null ? '/home' : '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const SplashScreen());
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/register':
            return MaterialPageRoute(builder: (_) => const RegisterScreen());
          case '/home':
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          case '/capture':
            return MaterialPageRoute(builder: (_) => const CaptureScreen());
          case '/review':
            final record = settings.arguments as ResumeRecord;
            return MaterialPageRoute(
                builder: (_) => ReviewScreen(record: record));
          case '/records':
            return MaterialPageRoute(builder: (_) => const RecordsListScreen());
          case '/detail':
            final record = settings.arguments as ResumeRecord;
            return MaterialPageRoute(
                builder: (_) => RecordDetailScreen(record: record));
          case '/sync':
            return MaterialPageRoute(builder: (_) => const SyncScreen());
          case '/qr_result':
            final record = settings.arguments as ResumeRecord;
            return MaterialPageRoute(
                builder: (_) => QrResultScreen(record: record));
          default:
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                body: Center(
                  child: Text('Page not found: ${settings.name}',
                      style: GoogleFonts.inter(color: Colors.white)),
                ),
              ),
            );
        }
      },
    );
  }
}
