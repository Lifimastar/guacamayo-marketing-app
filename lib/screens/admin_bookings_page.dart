import 'package:flutter/material.dart';
import 'package:guacamayo_marketing_app/screens/admin_deliverables_page.dart';
import 'package:guacamayo_marketing_app/widgets/booking_card_content.dart';
import '../utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking.dart';
import '../style/app_colors.dart';

class AdminBookingsPage extends StatefulWidget {
  const AdminBookingsPage({super.key});

  @override
  State<AdminBookingsPage> createState() => _AdminBookingsPageState();
}

class _AdminBookingsPageState extends State<AdminBookingsPage> {
  final _supabase = Supabase.instance.client;
  List<Booking> _allBookings = [];
  bool _isLoading = true;
  String? _errorMessage;

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

  @override
  void initState() {
    super.initState();
    _fetchAllBookings();
  }

  // obtener todos los bookings
  Future<void> _fetchAllBookings() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<Map<String, dynamic>> bookingJsonList = await _supabase
          .from('bookings')
          .select('*, services(*), profiles(id, name, role)')
          .order('booked_at', ascending: false);
      if (!mounted) return;

      _allBookings =
          bookingJsonList.map((json) => Booking.fromJson(json)).toList();
      _allBookings.sort((a, b) => b.bookedAt.compareTo(a.bookedAt));
    } on PostgrestException catch (e) {
      if (!mounted) return;
      logger.e('Error fetching all bookings: ${e.message}', error: e);
      setState(() {
        _errorMessage = 'Error al cargar todas las reservas: ${e.message}';
      });
    } catch (e) {
      if (!mounted) return;
      logger.e('Unexpected error fetching all bookings: $e', error: e);
      setState(() {
        _errorMessage =
            'Ocurrió un error inesperado al cargar todas las reservas: ${e.toString()}';
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

      final index = _allBookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        final updatedBookings = List<Booking>.from(_allBookings);
        updatedBookings[index] = _allBookings[index].copyWith(
          status: newStatus,
        );
        setState(() {
          _allBookings = updatedBookings;
        });
        final serviceName =
            bookingToUpdate.service?.name ?? 'Servicio Desconocido';
        final customerName =
            bookingToUpdate.userProfile?.name ?? 'Cliente Desconocido';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Estado de la reserva para "$serviceName" (Cliente: $customerName actualizado a "${_getStatusText(newStatus)}".',
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
          content: Text('Ocurrió un error inesperado al actualizar estado: ${e.toString()}'),
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
        _allBookings.removeWhere((b) => b.id == bookingId);
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

  // Metodo para obtener el texto legible del estado
  String _getStatusText(String status) {
    switch (status) {
      case 'checkout_pending':
        return 'Pago Pendiente';
      case 'pending':
        return 'Pendiente';
      case 'confirmed':
        return 'Confirmada';
      case 'in_progress':
        return 'En Progreso';
      case 'completed':
        return 'Completada';
      case 'cancelled':
        return 'Cancelada';
      case 'payment_failed':
        return 'Pago Fallido';
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Panel de Administracion de Reservas')),
      body:
          _isLoading && _allBookings.isEmpty
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
              : _allBookings.isEmpty
              ? Center(
                child:
                    _isLoading
                        ? const Text('Cargando reservas...')
                        : const Text('No hay reservas pendientes.'),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: _allBookings.length,
                itemBuilder: (context, index) {
                  final booking = _allBookings[index];
                  final serviceName =
                      booking.service?.name ?? 'Servicio Desconocido';
                  final customerName =
                      booking.userProfile?.name ?? 'Cliente Desconocido';
                  final isDeleting = _isDeletingBooking[booking.id] ?? false;

                  return Card(
                    child: BookingCardContent(
                      booking: booking,
                      isAdminView: true,
                      onEntregablesTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => AdminDeliverablesPage(
                                  bookingId: booking.id,
                                ),
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
                              : () => _deleteBooking(
                                booking.id,
                                serviceName,
                                customerName,
                              ),
                      isProcessingBookingAction: _isDeletingBooking,
                    ),
                  );
                },
              ),
    );
  }
}
