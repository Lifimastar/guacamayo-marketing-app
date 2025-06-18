import 'package:flutter/material.dart';

class ServiceCardSkeleton extends StatelessWidget {
  const ServiceCardSkeleton({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Placeholder para la imagen
          _buildPlaceholder(height: 150, width: double.infinity),
          const SizedBox(height: 16),
          // Placeholder para el titulo
          _buildPlaceholder(height: 24, width: 200),
          const SizedBox(height: 12),
          // Placeholder para la descripcion
          _buildPlaceholder(height: 16, width: double.infinity),
          const SizedBox(height: 6),
          _buildPlaceholder(height: 16, width: 150),
          const SizedBox(height: 12),
          // Placeholder para el precio
          _buildPlaceholder(height: 20, width: 100),
        ],
      ),
    );
  }
}
