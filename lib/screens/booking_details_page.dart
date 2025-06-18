import 'package:flutter/material.dart';
import 'package:guacamayo_marketing_app/screens/checkout_page.dart';
import 'package:guacamayo_marketing_app/screens/leave_review_page.dart';
import 'package:guacamayo_marketing_app/widgets/booking_status_timeline.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/booking.dart';
import '../models/deliverable.dart';
import '../style/app_colors.dart';
import '../utils/logger.dart';

import 'admin_deliverables_page.dart';
import 'user_deliverables_page.dart';

class BookingDetailsPage extends StatefulWidget {
  final String bookingId;
  final bool isAdminView;
  const BookingDetailsPage({
    super.key,
    required this.bookingId,
    this.isAdminView = false,
  });

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  final _supabase = Supabase.instance.client;
  Booking? _booking;
  List<Deliverable> _deliverables = [];
  bool _isLoading = true;
  String? _errorMessage;

  final List<String> _statusOrder = [
    'checkout_pending',
    'pending',
    'confirmed',
    'in_progress',
    'completed',
  ];

  @override
  void initState() {
    super.initState();
    _fetchBookingDetails();
  }

  // FetchBookingDetail
  Future<void> _fetchBookingDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bookingResponse =
          await _supabase
              .from('bookings')
              .select('*, services(*), profiles(id, name, role), reviews(id)')
              .eq('id', widget.bookingId)
              .single();

      if (!mounted) return;

      _booking = Booking.fromJson(bookingResponse);

      final deliverablesResponse = await _supabase
          .from('deliverables')
          .select('*')
          .eq('booking_id', widget.bookingId)
          .order('uploaded_at', ascending: false);

      if (!mounted) return;
      _deliverables =
          deliverablesResponse
              .map((json) => Deliverable.fromJson(json))
              .toList();
    } on PostgrestException catch (e) {
      if (!mounted) return;
      logger.e('Error fetching booking details: ${e.message}', error: e);
      setState(() {
        _errorMessage =
            'Error al cargar los detalles de la reserva ${e.message}';
      });
    } catch (e) {
      if (!mounted) return;
      logger.e('Unexpected error fetching booking details: $e', error: e);
      setState(() {
        _errorMessage = 'Ocurrio un error inesperado: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Abrir entregables
  Future<void> _openDeliverable(Deliverable deliverable) async {
    // Caso 1: El entregable es un archivo en Supabase Storage
    if (deliverable.storagePath != null &&
        deliverable.storagePath!.isNotEmpty) {
      try {
        final signedUrl = await _supabase.storage
            .from('deliverables')
            .createSignedUrl(deliverable.storagePath!, 60);

        final uri = Uri.parse(signedUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw 'No se pudo abrir la URL: $signedUrl';
        }
      } catch (e) {
        logger.e('Error al abrir el archivo de Storage: $e', error: e);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al obtener el archivo: ${e.toString()}'),
          ),
        );
      }
      // Caso 2: El entregable es una URL externa
    } else if (deliverable.fileUrl != null && deliverable.fileUrl!.isNotEmpty) {
      try {
        final uri = Uri.parse(deliverable.fileUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw 'No se pudo abrir la URL: ${deliverable.fileUrl}';
        }
      } catch (e) {
        logger.e('Error al abrir la URL del entregable: $e', error: e);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('La URL del entregable no es valida.')),
        );
      }
    }
    // Caso 3: No hay ni archivo ni URL
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Este entregable no tiene un archivo o URL para abrir.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Detalles de la Reserva')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              )
              : _booking == null
              ? const Center(
                child: Text('No se encontraron los detalles de la reserva.'),
              )
              : RefreshIndicator(
                onRefresh: _fetchBookingDetails,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Seccion de Resumen del Servicio
                    _buildServiceSummaryCard(theme, textTheme),
                    const SizedBox(height: 24),

                    // Seccion de Estado y Progreso
                    _buildStatusCard(theme, textTheme),
                    const SizedBox(height: 24),

                    // Seccion de Entregables
                    _buildDeliverablesCard(theme, textTheme),
                    const SizedBox(height: 24),

                    //Seccion de Acciones
                    if (!widget.isAdminView) _buildClientActions(context),
                    if (widget.isAdminView) _buildAdminActions(context),
                  ],
                ),
              ),
    );
  }

  // --- Widgets de Seccion (Refactorizacion) ---

  Widget _buildClientActions(BuildContext context) {
    if (_booking == null) return const SizedBox.shrink();

    // Si el pago fallo o esta pendiente, mostrar un boton para ir al checkout
    if (_booking!.status == 'payment_failed' ||
        _booking!.status == 'checkout_pending') {
      return ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => CheckoutPage(
                    booking: _booking!,
                    service: _booking!.service!,
                  ),
            ),
          );
        },
        icon: const Icon(Icons.payment),
        label: const Text('Proceder al Pago'),
      );
    }

    // Si esta completada y no tiene resena, mostrar boton para dejar resena
    if (_booking!.status == 'completed' && !(_booking!.hasReview)) {
      return ElevatedButton.icon(
        onPressed: () async {
          // Navegamos a la pagina para dejar la resena
          final reviewSubmitted = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => LeaveReviewPage(booking: _booking!),
            ),
          );

          if (reviewSubmitted == true && mounted) {
            _fetchBookingDetails();
          }
        },
        icon: const Icon(Icons.rate_review_outlined),
        label: const Text('Dejar una Reseña'),
      );
    }

    // Si no hay acciones especificas, no mostrar nada
    return const SizedBox.shrink();
  }

  // Widget para acciones del admin
  Widget _buildAdminActions(BuildContext context) {
    if (_booking == null) return const SizedBox.shrink();

    // el admin puede cambiar el estado, boton para gestionar entregables
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => AdminDeliverablesPage(bookingId: widget.bookingId),
          ),
        ).then((_) => _fetchBookingDetails());
      },
      icon: const Icon(Icons.add_to_drive),
      label: const Text('Gestionar Entregables'),
    );
  }

  Widget _buildServiceSummaryCard(ThemeData theme, TextTheme textTheme) {
    final service = _booking?.service;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen del Servicio',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            if (service != null) ...[
              Text(
                service.name,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (service.description != null)
                Text(service.description!, style: textTheme.bodyMedium),
              const SizedBox(height: 12),
              Text(
                'Precio Pagado: \$${_booking!.totalPrice.toStringAsFixed(2)}',
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.guacamayoGreen,
                ),
              ),
            ] else
              const Text('Detalles del servicio no disponible.'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme, TextTheme textTheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estado del Proyecto',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            // timeline
            BookingStatusTimeline(
              currentStatus: _booking!.status,
              allStatuses: _statusOrder,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliverablesCard(ThemeData theme, TextTheme textTheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Entregables',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final route = MaterialPageRoute(
                      builder:
                          (context) =>
                              widget.isAdminView
                                  ? AdminDeliverablesPage(
                                    bookingId: widget.bookingId,
                                  )
                                  : UserDeliverablesPage(
                                    bookingId: widget.bookingId,
                                  ),
                    );
                    await Navigator.push(context, route);
                    _fetchBookingDetails();
                  },
                  child: const Text('Ver Todos'),
                ),
              ],
            ),
            const Divider(height: 16),
            if (_deliverables.isEmpty)
              const Text('Aun no hay entregables para esta reserva.')
            else
              ..._deliverables.take(3).map((deliverable) {
                return ListTile(
                  leading: const Icon(Icons.attach_file),
                  title: Text(
                    deliverable.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    'Subido el: ${deliverable.uploadedAt.toLocal().toString().split(' ')[0]}',
                  ),
                  onTap: () {
                    _openDeliverable(deliverable);
                  },
                );
              }),
          ],
        ),
      ),
    );
  }
}
