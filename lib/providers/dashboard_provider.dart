import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dashboard_stats.dart';

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final supabase = Supabase.instance.client;

  // --- Calcular ingresos del Mes ---
  final now = DateTime.now();
  final firstDayOfMonth = DateTime(now.year, now.month, 1);
  final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

  final revenueResponse = await supabase
      .from('bookings')
      .select('total_price')
      .eq('status', 'completed')
      .gte('booked_at', firstDayOfMonth.toIso8601String())
      .lte('booked_at', lastDayOfMonth.toIso8601String());

  final double monthlyRevenue = (revenueResponse as List).fold(
    0.0,
    (sum, item) => sum + (item['total_price'] as num),
  );

  // --- Contar Reservas Pendientes ---
  final int pendingBookingsCount = await supabase
      .from('bookings')
      .count()
      .inFilter('status', ['pending', 'confirmed']);

  // --- Contar Usuarios Totales ---
  final totalUsersCount = await supabase.from('profiles').count();

  return DashboardStats(
    monthlyRevenue: monthlyRevenue,
    pendingBookingsCount: pendingBookingsCount,
    totalUsersCount: totalUsersCount,
  );
});
