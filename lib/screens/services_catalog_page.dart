import 'package:flutter/material.dart';
import 'package:guacamayo_marketing_app/screens/service_details_page.dart';
import 'package:guacamayo_marketing_app/widgets/service_card_content.dart';
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
  List<Service> _services = [];
  bool _isLoading = true;
  String? _errorMessage;

  Future<void> _fetchServices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<Map<String, dynamic>> data = await _supabase
          .from('services')
          .select('*')
          .order('created_at', ascending: true);

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
  void initState() {
    super.initState();
    _fetchServices();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo de Servicios')),
      body:
          _isLoading && _services.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                child: Text(
                  _errorMessage!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
              : _services.isEmpty
              ? Center(
                child:
                    _isLoading
                        ? const Text('Cargando servicios...')
                        : const Text(
                          'No hay servicios disponibles en este momento.',
                        ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: _services.length,
                itemBuilder: (context, index) {
                  final service = _services[index];
                  return Card(
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
                  );
                },
              ),
    );
  }
}
