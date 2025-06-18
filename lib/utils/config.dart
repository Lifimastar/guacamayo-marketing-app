import 'package:flutter_dotenv/flutter_dotenv.dart';

final String supabaseUrl = dotenv.env['SUPABASE_URL']!;
final String supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']!;
final String stripePublishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY']!;
final String backendUrl = dotenv.env['BACKEND_URL']!;
