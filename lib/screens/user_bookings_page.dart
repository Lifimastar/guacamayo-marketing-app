import 'package:flutter/material.dart';
import 'package:guacamayo_marketing_app/screens/leave_review_page.dart';
import 'package:guacamayo_marketing_app/screens/user_deliverables_page.dart';
import 'package:guacamayo_marketing_app/widgets/booking_card_content.dart';
import '../utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking.dart';
import '../style/app_colors.dart';

class UserBookingsPage extends StatefulWidget {
  const UserBookingsPage({super.key});

  @override
  State<UserBookingsPage> createState() => _UserBookingsPageState();
}

class _UserBookingsPageState extends State<UserBookingsPage> {
  final _supabase = Supabase.instance.client;
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _currentUserId;
  RealtimeChannel? _bookingsChannel;
  final Map<String, bool> _isProcessingBookingAction = {};

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _fetchUserBookings();
    _setupBookingsSubscription();
  }

  @override
  void dispose() {
    if (_bookingsChannel != null) {
      _supabase.removeChannel(_bookingsChannel!);
    }
    super.dispose();
  }

  Future<void> _fetchUserBookings() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final userId = _currentUserId;
    if (userId == null) {
      setState(() {
        _errorMessage = 'Error: Usuario no autenticado.';
        _isLoading = false;
      });
      return;
    }
    try {
      final List<Map<String, dynamic>> bookingDataList = await _supabase
          .from('bookings')
          .select('*, services(*), reviews(id)')
          .eq('user_id', userId)
          .order('booked_at', ascending: false);
      if (!mounted) return;
      _bookings =
          bookingDataList.map((json) => Booking.fromJson(json)).toList();
    } catch (e) {
      logger.e('Unexpected error fetching user bookings: $e', error: e);
      setState(() {
        _errorMessage =
            'Ocurrió un error inesperado al cargar las reservas: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Metodo para configurar la suscripcion a Supabase Realtime para bookings
  void _setupBookingsSubscription() {
    if (_currentUserId == null) return;

    _bookingsChannel = _supabase.channel(
      'public:bookings:user_$_currentUserId',
    );
    _bookingsChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _currentUserId!,
          ),
          callback: (payload) {
            logger.i(
              'UserBookingsPage Realtime: Booking updated - ${payload.newRecord}',
            );
            final updatedBookingJson = payload.newRecord;
            if (mounted) {
              try {
                final updatedBooking = Booking.fromJson(updatedBookingJson);
                setState(() {
                  final index = _bookings.indexWhere(
                    (b) => b.id == updatedBooking.id,
                  );
                  if (index != -1) {
                    final oldServiceData = _bookings[index].service;
                    _bookings[index] = updatedBooking.copyWith(
                      service: updatedBooking.service ?? oldServiceData,
                    );
                    logger.i(
                      'UserBookingsPage: Updated booking ${updatedBooking.id} to status ${updatedBooking.status}',
                    );
                  } else {
                    logger.i(
                      'UserBookingsPage: Received update for a booking not in local list: ${updatedBooking.id}',
                    );
                    _fetchUserBookings();
                  }
                });
              } catch (e) {
                logger.i(
                  'UserBookingsPage Realtime: Error parsing updated booking - $e',
                );
              }
            }
          },
        )
        .subscribe();
  }

  // Metodo para cancelar reserva
  Future<void> _cancelBookingByUser(
    String bookingId,
    String serviceName,
  ) async {
    if (!mounted) return;
    setState(() {
      _isProcessingBookingAction[bookingId] = true;
    });
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Cancelacion'),
          content: Text(
            'Estas seguro de que quieres cancelar tu reserva para "$serviceName"?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.errorColor,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Si, Cancelar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
        return;
      }
    }

    try {
      await _supabase
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', bookingId);
      if (!mounted) return;

      logger.i('Booking $bookingId cancelled succesfully.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reserva cancelada con exito.'),
          backgroundColor: AppColors.successColor,
        ),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      logger.e('Error cancelling booking by user: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cancelar reserva: ${e.message}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      logger.e('Unexpected error cancelling booking by user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ocurrio un error inesperado: ${e.toString()}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingBookingAction.remove(bookingId);
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
      appBar: AppBar(title: const Text('Mis Reservas')),
      body:
          _isLoading && _bookings.isEmpty
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
              : _bookings.isEmpty
              ? Center(
                child:
                    _isLoading
                        ? const Text('Cargando reservas...')
                        : const Text('No has realizado ninguna reserva aún.'),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: _bookings.length,
                itemBuilder: (context, index) {
                  final booking = _bookings[index];
                  final serviceName = booking.service?.name ?? 'este servicio';

                  return Card(
                    child: BookingCardContent(
                      booking: booking,
                      isAdminView: false,
                      onEntregablesTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    UserDeliverablesPage(bookingId: booking.id),
                          ),
                        );
                      },
                      onLeaveReviewTap:
                          (booking.status == 'completed' && !booking.hasReview)
                              ? () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            LeaveReviewPage(booking: booking),
                                  ),
                                );
                                _fetchUserBookings();
                              }
                              : null,
                      // callback para cancelar
                      onCancelBookingTap:
                          (booking.status == 'checkout_pending' ||
                                  booking.status == 'pending' ||
                                  booking.status == 'confirmed')
                              ? () =>
                                  _cancelBookingByUser(booking.id, serviceName)
                              : null,
                      isProcessingBookingAction: _isProcessingBookingAction,
                    ),
                  );
                },
              ),
    );
  }
}
