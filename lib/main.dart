import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:guacamayo_marketing_app/providers/theme_provider.dart';
import 'package:guacamayo_marketing_app/screens/main_shell.dart';
import 'package:guacamayo_marketing_app/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/auth_page.dart';
import 'providers/auth_provider.dart';
import 'utils/config.dart';
import 'style/app_theme.dart';

final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // variables de entorno
  await dotenv.load(fileName: ".env");

  // firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    debug: true,
  );

  // stripe
  Stripe.publishableKey = stripePublishableKey;

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MainApp(),
    ),
  );
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final authState = ref.watch(authProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Guacamayo Marketing App',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      home:
          authState.isLoading
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : authState.isAuthenticated
              ? const MainShell()
              : const AuthPage(),
    );
  }
}
