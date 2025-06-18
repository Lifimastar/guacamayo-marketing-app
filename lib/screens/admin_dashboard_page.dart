import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guacamayo_marketing_app/providers/dashboard_provider.dart';
import 'package:guacamayo_marketing_app/style/app_colors.dart';
import 'package:guacamayo_marketing_app/widgets/dashboard_metric_card.dart';
import 'package:guacamayo_marketing_app/widgets/dashboard_skeleton.dart';
import 'package:guacamayo_marketing_app/widgets/empty_state_widget.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard de Administrador')),
      body: statsAsync.when(
        loading: () => const DashboardSkeleton(),
        error: (err, stack) {
          return EmptyStateWidget(
            icon: Icons.cloud_off_outlined,
            title: 'Error al Cargar Datos',
            message:
                'No se pudieron obtener las estadisticas. Verifica tu conexion e intentalo de nuevo.',
            action: ElevatedButton.icon(
              onPressed: () => ref.refresh(dashboardStatsProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          );
        },
        data: (stats) {
          return RefreshIndicator(
            onRefresh: () => ref.refresh(dashboardStatsProvider.future),
            child: GridView.count(
              padding: const EdgeInsets.all(16.0),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.9,
              children: [
                DashboardMetricCard(
                  icon: Icons.attach_money_rounded,
                  title: 'Ingresos del Mes',
                  value: '\$${stats.monthlyRevenue.toStringAsFixed(2)}',
                  color: AppColors.guacamayoGreen,
                ),
                DashboardMetricCard(
                  icon: Icons.pending_actions_rounded,
                  title: 'Reservas Pendientes',
                  value: stats.pendingBookingsCount.toString(),
                  color: AppColors.statusPending,
                ),
                DashboardMetricCard(
                  icon: Icons.people_alt_rounded,
                  title: 'Usuarios Totales',
                  value: stats.totalUsersCount.toString(),
                  color: AppColors.statusConfirmed,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
