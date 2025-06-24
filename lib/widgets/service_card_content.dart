import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/service.dart';
import '../providers/favorites_provider.dart';
import '../style/app_colors.dart';
import 'package:logger/logger.dart';

class ServiceCardContent extends ConsumerWidget {
  final Service service;
  ServiceCardContent({super.key, required this.service});

  final logger = Logger();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteServiceIds = ref.watch(favoritesProvider);
    final isFavorite = favoriteServiceIds.contains(service.id);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen de Portada
              if (service.coverImageUrl != null &&
                  service.coverImageUrl!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child:
                      service.coverImageUrl!.toLowerCase().endsWith('.svg')
                          ? SvgPicture.network(
                            service.coverImageUrl!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.contain,

                            placeholderBuilder:
                                (BuildContext context) => Container(
                                  height: 150,
                                  color: AppColors.lightGrey,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                          )
                          : Image.network(
                            service.coverImageUrl!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                // Placeholder mientras carga
                                height: 150,
                                color: AppColors.lightGrey,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              // Placeholder si la imagen no carga o URL inválida
                              logger.w(
                                'Failed to load image: ${service.coverImageUrl}',
                                error: error,
                              );

                              return Container(
                                height: 150,
                                color: AppColors.mediumGrey,
                                child: Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    size: 50,
                                    color: colorScheme.error,
                                  ),
                                ),
                              );
                            },
                          ),
                ),
                const SizedBox(height: 16),
              ],
              // Placeholder si no hay imagen (o URL vacía)
              if (service.coverImageUrl == null ||
                  service.coverImageUrl!.isEmpty) ...[
                Container(
                  height: 150,
                  color: AppColors.lightGrey,
                  child: Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 50,
                      color: AppColors.mediumGrey,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Nombre del Servicio
              Text(
                service.name,
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Descripción (si existe)
              if (service.description != null &&
                  service.description!.isNotEmpty) ...[
                Text(
                  service.description!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withAlpha((255 * 0.8).round()),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],

              // Precio (destacado)
              Text(
                'Precio: \$${service.price.toStringAsFixed(2)}',
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.statusCompleted,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Duración (si existe)
              if (service.duration != null) ...[
                Text(
                  'Duración: ${service.duration} horas',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withAlpha((255 * 0.7).round()),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.redAccent : Colors.grey[400],
                size: 28,
              ),
              onPressed: () {
                ref.read(favoritesProvider.notifier).toggleFavorite(service.id);
              },
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withAlpha((255 * 0.7).round()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
