import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service.dart';

final featuredServicesProvider = FutureProvider<List<Service>>((ref) async {
  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('services')
      .select('*')
      .eq('is_active', true)
      .eq('is_featured', true)
      .limit(5);

  return (response as List).map((json) => Service.fromJson(json)).toList();
});
