// lib/widgets/dashboard_skeleton.dart
import 'package:flutter/material.dart';

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  Widget _buildPlaceholder({
    required double height,
    required double width,
    double radius = 8.0,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(20),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildMetricCardSkeleton() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildPlaceholder(height: 32, width: 32), // Icono
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPlaceholder(height: 16, width: 100), // Título
                const SizedBox(height: 8),
                _buildPlaceholder(height: 24, width: 80), // Valor
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.all(16.0),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.9,
      children: List.generate(3, (index) => _buildMetricCardSkeleton()),
    );
  }
}
