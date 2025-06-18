import 'package:flutter/material.dart';

class BookingCardSkeleton extends StatelessWidget {
  const BookingCardSkeleton({super.key});

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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Placeholder para la imagen y el nombre del servicio
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPlaceholder(height: 60, width: 60),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    _buildPlaceholder(
                      height: 20,
                      width: 200,
                    ), // Título del servicio
                    const SizedBox(height: 8),
                    _buildPlaceholder(height: 18, width: 120), // Estado
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Placeholder para precio y fecha
          _buildPlaceholder(height: 16, width: 100), // Precio
          const SizedBox(height: 8),
          _buildPlaceholder(height: 14, width: 180), // Fecha
          const SizedBox(height: 16),
          // Placeholder para los botones de acción
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [_buildPlaceholder(height: 36, width: 100)],
          ),
        ],
      ),
    );
  }
}
