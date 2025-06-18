import 'package:flutter/material.dart';
import 'package:guacamayo_marketing_app/screens/main_shell.dart';
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

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(authProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Guacamayo Marketing App',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home:
          userState.isLoading
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : userState.isAuthenticated
              ? const MainShell()
              : const AuthPage(),
    );
  }
}
