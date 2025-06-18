import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:guacamayo_marketing_app/screens/service_details_page.dart';
import 'package:guacamayo_marketing_app/widgets/empty_state_widget.dart';
import 'package:guacamayo_marketing_app/widgets/service_card_content.dart';
import 'package:guacamayo_marketing_app/widgets/service_card_skeleton.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service.dart';
import '../utils/logger.dart';

class ServicesCatalogPage extends StatefulWidget {
  const ServicesCatalogPage({super.key});

  @override
  State<ServicesCatalogPage> createState() => _ServicesCatalogPageState();
}

class _ServicesCatalogPageState extends State<ServicesCatalogPage> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  List<Service> _services = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchServices();
    _searchController.addListener(() {
      if (_searchController.text != _searchQuery) {
        setState(() {
          _searchQuery = _searchController.text;
        });
        _fetchServices();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchServices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      var query = _supabase.from('services').select('*');

      if (_searchQuery.isNotEmpty) {
        query = query.ilike('name', '%$_searchQuery%');
      }

      final List<Map<String, dynamic>> data = await query.order(
        'created_at',
        ascending: true,
      );

      _services = data.map((json) => Service.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      logger.e('Error fetching services: ${e.message}', error: e);
      setState(() {
        _errorMessage = 'Error al cargar los servicios: ${e.message}';
      });
    } catch (e) {
      logger.e('Unexpected error fetching services: $e', error: e);
      setState(() {
        _errorMessage =
            'Ocurrio un error inesperado al cargar los servicios: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- Logica de la UI ---
    Widget buildContent() {
      if (_isLoading && _services.isEmpty) {
        // Muestra 3 esqueletos mientras carga
        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: 3,
          itemBuilder:
              (context, index) => const Card(child: ServiceCardSkeleton()),
        );
      }

      if (_errorMessage != null) {
        return EmptyStateWidget(
          icon: Icons.cloud_off_rounded,
          title: 'Error de Conexion',
          message: _errorMessage!,
          action: ElevatedButton.icon(
            onPressed: _fetchServices,
            icon: const Icon(Icons.refresh),
            label: const Text('Reitentar'),
          ),
        );
      }

      if (_services.isEmpty) {
        return const EmptyStateWidget(
          icon: Icons.search_off_rounded,
          title: 'No se encontraron servicios',
          message:
              'Prueba a cambiar los términos de búsqueda o revisa el catálogo completo.',
        );
      }

      // Muestra la lista de servicios real
      return AnimationLimiter(
        child: ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: _services.length,
          itemBuilder: (context, index) {
            final service = _services[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
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
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo de Servicios')),
      body: Column(
        children: [
          // --- BARRA DE BUSQUEDA ---
          Padding(
            padding: EdgeInsetsGeometry.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar servicios...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ),
          // --- LISTA DE RESULTADOS ---
          Expanded(child: buildContent()),
        ],
      ),
    );
  }
}
