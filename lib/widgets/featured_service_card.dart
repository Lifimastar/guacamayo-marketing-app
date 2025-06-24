import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guacamayo_marketing_app/providers/favorites_provider.dart';
import '../models/service.dart';
import '../screens/service_details_page.dart';
import '../style/app_colors.dart';

class FeaturedServiceCard extends ConsumerWidget {
  final Service service;
  const FeaturedServiceCard({super.key, required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteServiceIds = ref.watch(favoritesProvider);
    final isFavorite = favoriteServiceIds.contains(service.id);

    return SizedBox(
      width: 180,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ServiceDetailsPage(service: service),
              ),
            );
          },
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 100,
                    width: double.infinity,
                    child: Image.network(
                      service.coverImageUrl ?? '',
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            color: AppColors.lightGrey,
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              size: 40,
                              color: AppColors.mediumGrey,
                            ),
                          ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            service.name,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Material(
                  color: Colors.black.withAlpha((255 * 0.3).round()),
                  borderRadius: BorderRadius.circular(30),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () {
                      ref
                          .read(favoritesProvider.notifier)
                          .toggleFavorite(service.id);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.redAccent : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
