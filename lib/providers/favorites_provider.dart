import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:guacamayo_marketing_app/utils/logger.dart';

import '../models/service.dart';

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier(this.ref) : super({});

  final Ref ref;
  final _supabase = Supabase.instance.client;

  Future<void> loadFavorites() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      state = {};
      return;
    }

    try {
      final response = await _supabase
          .from('favorites')
          .select('service_id')
          .eq('user_id', userId);

      final favoriteIds =
          (response as List)
              .map((item) => item['service_id'] as String)
              .toSet();

      state = favoriteIds;
      logger.i('Favoritos cargados: ${state.length} items.');
    } catch (e) {
      logger.e('Error al cargar favoritos: $e');
      state = {};
    }
  }

  Future<void> addFavorite(String serviceId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || state.contains(serviceId)) return;

    state = {...state, serviceId};

    try {
      await _supabase.from('favorites').insert({
        'user_id': userId,
        'service_id': serviceId,
      });
      logger.i('Servicio $serviceId anadido a favoritos en la DB.');
    } catch (e) {
      logger.e('Error al anadir favorito en la DB: $e');
      state = state.where((id) => id != serviceId).toSet();
    }
  }

  Future<void> removeFavorite(String serviceId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || !state.contains(serviceId)) return;

    state = state.where((id) => id != serviceId).toSet();

    try {
      await _supabase.from('favorites').delete().match({
        'user_id': userId,
        'service_id': serviceId,
      });
      logger.i('Servicio $serviceId eliminado de favoritos en la DB.');
    } catch (e) {
      logger.e('Error al eliminar favorito en la DB: $e');
      state = {...state, serviceId};
    }
  }

  Future<void> toggleFavorite(String serviceId) async {
    if (state.contains(serviceId)) {
      await removeFavorite(serviceId);
    } else {
      await addFavorite(serviceId);
    }
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>(
  (ref) {
    return FavoritesNotifier(ref);
  },
);

final favoriteServicesProvider = FutureProvider<List<Service>>((ref) async {
  final supabase = Supabase.instance.client;

  final favoriteIds = ref.watch(favoritesProvider);

  if (favoriteIds.isEmpty) {
    return [];
  }

  try {
    final response = await supabase
        .from('services')
        .select('*')
        .inFilter('id', favoriteIds.toList());

    return (response as List).map((json) => Service.fromJson(json)).toList();
  } catch (e) {
    logger.e('Error al obtener los detalles de los servicios favoritos: $e');
    return [];
  }
});
