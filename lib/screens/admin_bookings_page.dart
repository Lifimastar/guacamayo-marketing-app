import 'dart:async';
import 'package:flutter/material.dart';
import 'package:guacamayo_marketing_app/screens/admin_deliverables_page.dart';
import 'package:guacamayo_marketing_app/screens/booking_details_page.dart';
import 'package:guacamayo_marketing_app/widgets/booking_card_content.dart';
import 'package:guacamayo_marketing_app/widgets/booking_card_skeleton.dart';
import 'package:guacamayo_marketing_app/widgets/empty_state_widget.dart';
import '../utils/booking_status_utils.dart';
import '../utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking.dart';
import '../style/app_colors.dart';
import '../services/api_service.dart';

class AdminBookingsPage extends StatefulWidget {
  const AdminBookingsPage({super.key});

  @override
  State<AdminBookingsPage> createState() => _AdminBookingsPageState();
}

class _AdminBookingsPageState extends State<AdminBookingsPage> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String? _selectedStatusFilter;
  String? _errorMessage;
  Timer? _debounce;

  final List<String> _bookingStatuses = [
    'checkout_pending',
    'pending',
    'confirmed',
    'in_progress',
    'completed',
    'cancelled',
    'payment_failed',
  ];

  final Map<String, bool> _isUpdatingStatus = {};
  final Map<String, bool> _isDeletingBooking = {};
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchAdminBookings();
    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        _fetchAdminBookings();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // obtener todos los bookings
  Future<void> _fetchAdminBookings() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      dynamic query;
      final searchQuery = _searchController.text.trim();

      if (searchQuery.isNotEmpty) {
        query = _supabase
            .rpc('search_bookings', params: {'search_term': searchQuery})
            .select('*, services(*), profiles(id, name, role)');
      } else {
        query = _supabase
            .from('bookings')
            .select('*, services(*), profiles(id, name, role)');
      }

      if (_selectedStatusFilter != null) {
        query = query.eq('status', _selectedStatusFilter!);
      }

      final response = await query.order('booked_at', ascending: false);

      final bookingJsonList = List<Map<String, dynamic>>.from(response);

      if (!mounted) return;

      setState(() {
        _bookings =
            bookingJsonList.map((json) => Booking.fromJson(json)).toList();
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;
      logger.e('Error fetching admin bookings: ${e.message}', error: e);
      setState(() {
        _errorMessage = 'Error al cargar las reservas: ${e.message}';
      });
    } catch (e) {
      if (!mounted) return;
      logger.e('Unexpected error fetching admin bookings: $e', error: e);
      setState(() {
        _errorMessage = 'Ocurrió un error inesperado: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Metodo para actualizar el estado de una reserva
  Future<void> _updateBookingStatus(
    Booking bookingToUpdate,
    String newStatus,
  ) async {
    if (!mounted) return;
    final bookingId = bookingToUpdate.id;
    setState(() {
      _isUpdatingStatus[bookingId] = true;
    });

    try {
      await _supabase
          .from('bookings')
          .update({'status': newStatus})
          .eq('id', bookingId);
      if (!mounted) return;

      if (newStatus == 'confirmed' ||
          newStatus == 'in_progress' ||
          newStatus == 'completed') {
        logger.i('Estado actualizado. Disparando notificacion...');
        await _apiService.sendBookingStatusNotification(
          userId: bookingToUpdate.userId,
          bookingId: bookingToUpdate.id,
          serviceName: bookingToUpdate.service?.name ?? 'tu servicio',
          newStatusReadable: BookingStatusUtils.getStatusText(newStatus),
        );
      }

      final index = _bookings.indexWhere((b) => b.id == bookingToUpdate.id);
      if (index != -1) {
        setState(() {
          _bookings[index] = _bookings[index].copyWith(status: newStatus);
        });
        final serviceName =
            bookingToUpdate.service?.name ?? 'Servicio Desconocido';
        final customerName =
            bookingToUpdate.userProfile?.name ?? 'Cliente Desconocido';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Estado de la reserva para "$serviceName" (Cliente: $customerName actualizado a "${BookingStatusUtils.getStatusText(newStatus)}".',
            ),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    } on PostgrestException catch (e) {
      if (!mounted) return;
      logger.e('Error updating booking status: ${e.message}', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar estado: ${e.message}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      logger.e('Unexpected error updating booking status: $e', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ocurrió un error inesperado al actualizar estado: ${e.toString()}',
          ),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus.remove(bookingId);
        });
      }
    }
  }

  // Metodo para eliminar una reserva
  Future<void> _deleteBooking(
    String bookingId,
    String serviceNameForDialog,
    String customerNameForDialog,
  ) async {
    if (!mounted) return;
    setState(() {
      _isDeletingBooking[bookingId] = true;
    });
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Eliminacion PERMANENTE'),
          content: Text(
            '¿Estás ABSOLUTAMENTE seguro de que quieres eliminar la reserva para "$serviceNameForDialog" (Cliente: $customerNameForDialog, ID: ${bookingId.substring(0, 8)})? Esta acción NO se puede deshacer y eliminará el registro de la reserva.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.errorColor,
              ),
              child: const Text('Si, Eliminar Permanentemente'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      if (mounted) {
        setState(() {
          _isDeletingBooking.remove(bookingId);
        });
      }
      return;
    }

    try {
      await _supabase.from('bookings').delete().eq('id', bookingId);
      if (!mounted) return;

      setState(() {
        _bookings.removeWhere((b) => b.id == bookingId);
      });

      logger.i('Booking $bookingId deleted successfully.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reserva eliminada permanentemente.'),
          backgroundColor: AppColors.successColor,
        ),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      logger.e('Error deleting booking by admin: ${e.message}', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar reserva: ${e.message}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      logger.e('Unexpected error deleting booking by admin: $e', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ocurrio un error inesperado: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingBooking.remove(bookingId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Panel de Administracion de Reservas')),
      body: Column(
        children: [
          // Seccion de Busqueda y Filtro
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Campo de Busqueda
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Buscar por Cliente o Servicio',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _searchController.clear(),
                            )
                            : null,
                  ),
                ),
                const SizedBox(height: 16),
                // Filtro por Estado
                DropdownButtonFormField<String>(
                  value: _selectedStatusFilter,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por Estado',
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Todos los Estado'),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Todos los Estados'),
                    ),
                    ..._bookingStatuses.map((String status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(BookingStatusUtils.getStatusText(status)),
                      );
                    }),
                  ],
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedStatusFilter = newValue;
                    });
                    _fetchAdminBookings();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Lista de Reservas
          Expanded(child: _buildContent(textTheme, colorScheme)),
        ],
      ),
    );
  }

  Widget _buildContent(TextTheme textTheme, ColorScheme colorScheme) {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: 5,
        itemBuilder:
            (context, index) => const Card(child: BookingCardSkeleton()),
      );
    }

    if (_errorMessage != null) {
      return EmptyStateWidget(
        icon: Icons.error_outline,
        title: 'Error al Cargar',
        message: _errorMessage!,
        action: ElevatedButton.icon(
          onPressed: _fetchAdminBookings,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      );
    }

    if (_bookings.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.search_off,
        title: 'No se encontraron reservas',
        message: 'Prueba a cambiar los filtros o el término de búsqueda.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _bookings.length,
      itemBuilder: (context, index) {
        final booking = _bookings[index];
        final serviceName = booking.service?.name ?? 'Servicio Desconocido';
        final customerName = booking.userProfile?.name ?? 'Cliente Desconocido';
        final isDeleting = _isDeletingBooking[booking.id] ?? false;

        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => BookingDetailsPage(
                        bookingId: booking.id,
                        isAdminView: true,
                      ),
                ),
              );
            },
            child: BookingCardContent(
              booking: booking,
              isAdminView: true,
              onEntregablesTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            AdminDeliverablesPage(bookingId: booking.id),
                  ),
                );
              },
              bookingStatuses: _bookingStatuses,
              isUpdatingStatus: _isUpdatingStatus,
              onStatusChange:
                  (bookingIdFromCallback, newStatus) =>
                      _updateBookingStatus(booking, newStatus),
              onDeleteBookingTap:
                  isDeleting
                      ? null
                      : () =>
                          _deleteBooking(booking.id, serviceName, customerName),
              isProcessingBookingAction: _isDeletingBooking,
            ),
          ),
        );
      },
    );
  }
}
