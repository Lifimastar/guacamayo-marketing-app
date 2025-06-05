import 'package:flutter/material.dart';
import 'package:guacamayo_marketing_app/screens/admin_edit_service_page.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/service.dart';
import '../style/app_colors.dart';

class AdminServicesPage extends StatefulWidget {
  const AdminServicesPage({super.key});

  @override
  State<AdminServicesPage> createState() => _AdminServicesPageState();
}

class _AdminServicesPageState extends State<AdminServicesPage> {
  final _supabase = Supabase.instance.client;
  List<Service> _services = [];
  bool _isLoading = true;
  String? _errorMessage;

  final Map<String, bool> _isDeletingService = {};

  Logger logger = Logger();

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  // Metodo para obtener todos los servicios
  Future<void> _fetchServices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<Map<String, dynamic>> data = await _supabase
          .from('services')
          .select('*')
          .order('name', ascending: true);

      _services = data.map((json) => Service.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      logger.e('Error fetching services for admin: ${e.message}', error: e);
      setState(() {
        _errorMessage = 'Error al cargar los servicios: ${e.message}';
      });
    } catch (e) {
      logger.e('Unexpected error fetching services for admin: $e', error: e);
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

  // Metodo para navegar a la pantalla de editar/crear servicio
  Future<void> _navigateToEditServicePage({Service? service}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminEditServicePage(service: service),
      ),
    );
    _fetchServices();
  }

  // metodo para activar/desactivar servicio
  Future<void> _toggleServiceActiveStatus(Service service) async {
    final newStatus = !service.isActive;
    final actionText = newStatus ? 'activar' : 'desactivar';

    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Confirmar ${actionText.replaceFirst(actionText[0], actionText[0].toUpperCase())} Servicio',
          ),
          content: Text(
            '¿Estás seguro de que quieres $actionText el servicio "${service.name}"?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                actionText.replaceFirst(
                  actionText[0],
                  actionText[0].toUpperCase(),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _supabase
          .from('services')
          .update({'is_active': newStatus})
          .eq('id', service.id);

      if (!mounted) return;
      setState(() {
        final index = _services.indexWhere((s) => s.id == service.id);
        if (index != -1) {
          _services[index] = service.copyWith(isActive: newStatus);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Servicio ${actionText}do con exito.'),
          backgroundColor: AppColors.successColor,
        ),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      logger.e('Error toggling service active status: ${e.message}', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al $actionText el servicio: ${e.message}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      logger.e('Unexpected error toggling service active status: $e', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ocurrio un error inesperado al $actionText el servicio $e',
          ),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Metodo para eliminar un servicio
  Future<void> _deleteService(String serviceId, String serviceName) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text(
            '¿Estás seguro de que quieres eliminar el servicio "$serviceName"? Esta acción no se puede deshacer. Si el servicio tiene reservas asociadas, la eliminacion fallara.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isDeletingService[serviceId] = true;
    });

    try {
      await _supabase.from('services').delete().eq('id', serviceId);

      if (!mounted) return;

      setState(() {
        _services.removeWhere((service) => service.id == serviceId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Servicio eliminado con éxito.'),
          backgroundColor: AppColors.successColor,
        ),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      logger.e('Error deleting service: ${e.message}', error: e);
      String errorMessage = 'Error al eliminar servicio: ${e.message}';
      if (e.code == '23503' &&
          e.message.contains('violates foreign key constraint') &&
          e.message.contains('bookings_service_id_fkey')) {
        errorMessage =
            'Error: No se puede eliminar. El servicio tiene reservas asociadas. Considere desactivarlo.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      logger.e('Unexpected error deleting service: $e', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ocurrió un error inesperado al eliminar servicio: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isDeletingService.remove(serviceId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion de Servicios'),
        actions: [
          // anadir nuevo servicio
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Añadir Nuevo Servicio',
            onPressed: _isLoading ? null : () => _navigateToEditServicePage(),
          ),
        ],
      ),
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
                        : const Text('No hay servicios configurados.'),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: _services.length,
                itemBuilder: (context, index) {
                  final service = _services[index];
                  final isDeleting = _isDeletingService[service.id] ?? false;

                  return Card(
                    child: ListTile(
                      title: Text(
                        service.name,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Precio: \$${service.price.toStringAsFixed(2)}',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.statusCompleted,
                            ),
                          ),
                          // boton/texto para activar/desactivar
                          Row(
                            children: [
                              Text('Activo: ', style: textTheme.bodySmall),
                              Switch(
                                value: service.isActive,
                                onChanged:
                                    (_isLoading || isDeleting)
                                        ? null
                                        : (bool value) {
                                          _toggleServiceActiveStatus(service);
                                        },
                                activeColor: AppColors.guacamayoGreen,
                              ),
                            ],
                          ),
                          if (service.description != null &&
                              service.description!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                service.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall,
                              ),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.edit_outlined,
                              color: colorScheme.primary,
                            ),
                            tooltip: 'Editar Servicio',
                            onPressed:
                                (_isLoading || isDeleting)
                                    ? null
                                    : () => _navigateToEditServicePage(
                                      service: service,
                                    ),
                          ),
                          IconButton(
                            icon:
                                isDeleting
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.0,
                                        color: Colors.red,
                                      ),
                                    )
                                    : Icon(
                                      Icons.delete_outline,
                                      color: colorScheme.error,
                                    ),
                            tooltip: 'Eliminar Servicio',
                            onPressed:
                                (_isLoading || isDeleting)
                                    ? null
                                    : () => _deleteService(
                                      service.id,
                                      service.name,
                                    ),
                          ),
                        ],
                      ),
                      onTap:
                          (_isLoading || isDeleting)
                              ? null
                              : () =>
                                  _navigateToEditServicePage(service: service),
                    ),
                  );
                },
              ),
    );
  }
}
