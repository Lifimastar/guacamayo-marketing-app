import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:guacamayo_marketing_app/providers/favorites_provider.dart';
import 'package:guacamayo_marketing_app/screens/service_details_page.dart';
import 'package:guacamayo_marketing_app/widgets/empty_state_widget.dart';
import 'package:guacamayo_marketing_app/widgets/service_card_content.dart';
import 'package:guacamayo_marketing_app/widgets/service_card_skeleton.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteServicesAsync = ref.watch(favoriteServicesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Favoritos')),
      body: favoriteServicesAsync.when(
        loading:
            () => ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: 5,
              itemBuilder:
                  (context, index) => const Card(child: ServiceCardSkeleton()),
            ),
        error:
            (err, stack) => EmptyStateWidget(
              icon: Icons.error_outline,
              title: 'Error al Cargar',
              message:
                  'No se pudieron cargar tus favoritos. Intentalo de nuevo.',
              action: ElevatedButton.icon(
                onPressed: () => ref.refresh(favoriteServicesProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ),
        data: (services) {
          if (services.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.favorite_border,
              title: 'Aún no tienes favoritos',
              message:
                  'Explora nuestro catálogo y pulsa el corazón en los servicios que te interesen para guardarlos aquí.',
            );
          }

          return AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: Card(
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        ServiceDetailsPage(service: service),
                              ),
                            );
                          },
                          child: ServiceCardContent(service: service),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
