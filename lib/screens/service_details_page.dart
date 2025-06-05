import 'package:flutter/material.dart';
import 'package:guacamayo_marketing_app/screens/checkout_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service.dart';
import '../models/booking.dart';
import '../models/review.dart';
import '../style/app_colors.dart';
import '../utils/logger.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ServiceDetailsPage extends StatefulWidget {
  final Service service;
  const ServiceDetailsPage({super.key, required this.service});

  @override
  State<ServiceDetailsPage> createState() => _ServiceDetailsPageState();
}

class _ServiceDetailsPageState extends State<ServiceDetailsPage> {
  final _supabase = Supabase.instance.client;
  List<Review> _reviews = [];
  bool _isLoadingReviews = true;
  String? _reviewsErrorMessage;
  bool _isProcessingBooking = false;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    if (!mounted) return;
    setState(() {
      _isLoadingReviews = true;
      _reviewsErrorMessage = null;
    });

    try {
      final List<Map<String, dynamic>> data = await _supabase
          .from('reviews')
          .select('*, profiles(id, name)')
          .eq('service_id', widget.service.id)
          .eq('is_visible', true)
          .order('created_at', ascending: false);
      if (!mounted) return;
      _reviews = data.map((json) => Review.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      if (!mounted) return;
      logger.e('Error fetching reviews: ${e.message}', error: e);
      setState(() {
        _reviewsErrorMessage = 'Error al cargar las resenas: ${e.message}';
      });
    } catch (e) {
      if (!mounted) return;
      logger.e('Unexpected error fetching reviews: $e', error: e);
      setState(() {
        _reviewsErrorMessage =
            'Ocurrio un error inesperado al cargar las resenas: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingReviews = false;
        });
      }
    }
  }

  Future<void> _createBooking() async {
    if (!mounted) return;
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, inicia sesión para reservar un servicio.'),
          backgroundColor: AppColors.statusPending,
        ),
      );
      return;
    }

    setState(() {
      _isProcessingBooking = true;
    });

    try {
      final List<Map<String, dynamic>> existingPendingBookings = await _supabase
          .from('bookings')
          .select(
            'id, user_id, service_id, booked_at, status, total_price, notes, start_date, end_date, payment_id, services(*), reviews(id)',
          )
          .eq('user_id', userId)
          .eq('service_id', widget.service.id)
          .eq('status', 'checkout_pending');

      if (!mounted) {
        setState(() {
          _isProcessingBooking = false;
        });
        return;
      }

      Booking? bookingToCheckout;

      if (existingPendingBookings.isNotEmpty) {
        final existingBookingJson = existingPendingBookings.first;
        logger.i('Existing pending booking JSON: $existingBookingJson');
        final existingBooking = Booking.fromJson(existingBookingJson);

        bool? continueWithExisting = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Reserva Pendiente Encontrada'),
              content: Text(
                'Ya tienes una reserva para "${widget.service.name}" pendiente de pago. ¿Deseas continuar con el pago de esta reserva o crear una nueva?',
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Crear Nueva'),
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                ),
                ElevatedButton(
                  child: const Text('Continuar Pago'),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                ),
              ],
            );
          },
        );

        if (continueWithExisting == true) {
          bookingToCheckout = existingBooking;
        } else if (continueWithExisting == null) {
          setState(() {
            _isProcessingBooking = false;
          });
          return;
        }
      }
      if (!mounted) return;
      if (bookingToCheckout == null) {
        bool? confirmedNewBooking = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Confirmar Reserva'),
              content: Text(
                '¿Estás seguro de que quieres reservar "${widget.service.name}" por \$${widget.service.price.toStringAsFixed(2)}? Procederás al pago.',
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                ),
                TextButton(
                  child: const Text('Confirmar'),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                ),
              ],
            );
          },
        );
        if (confirmedNewBooking != true) {
          setState(() {
            _isProcessingBooking = false;
          });
          return;
        }

        final Map<String, dynamic> bookingData = {
          'user_id': userId,
          'service_id': widget.service.id,
          'booked_at': DateTime.now().toIso8601String(),
          'status': 'checkout_pending',
          'total_price': widget.service.price,
          'notes': '',
        };
        final Map<String, dynamic> insertedBookingJson =
            await _supabase
                .from('bookings')
                .insert(bookingData)
                .select(
                  'id, user_id, service_id, booked_at, status, total_price, notes, start_date, end_date, payment_id, services(*), reviews(id)',
                )
                .single();
        if (!mounted) {
          setState(() {
            _isProcessingBooking = false;
          });
          return;
        }
        bookingToCheckout = Booking.fromJson(insertedBookingJson);
      }

      if (!mounted) {
        setState(() {
          _isProcessingBooking = false;
        });
        return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => CheckoutPage(
                booking: bookingToCheckout!,
                service: bookingToCheckout.service ?? widget.service,
              ),
        ),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      logger.e('PostgrestException in _createBooking: ${e.message}', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al iniciar la reserva: ${e.message}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      logger.e('Unexpected error in _createBooking: $e', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ocurrió un error inesperado al iniciar reserva: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingBooking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double averageRating = 0.0;
    if (_reviews.isNotEmpty) {
      final totalRating = _reviews.fold(0, (sum, item) => sum + item.rating);
      averageRating = totalRating / _reviews.length;
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.service.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Seccion de Imagen de Portada
            Container(
              height: 250,
              width: double.infinity,
              color: AppColors.lightGrey,
              child:
                  (widget.service.coverImageUrl != null &&
                          widget.service.coverImageUrl!.isNotEmpty)
                      ? (widget.service.coverImageUrl!.toLowerCase().endsWith(
                            '.svg',
                          )
                          ? SvgPicture.network(
                            widget.service.coverImageUrl!,
                            fit: BoxFit.contain,
                            placeholderBuilder:
                                (BuildContext context) => Center(
                                  child: CircularProgressIndicator(
                                    color: colorScheme.primary,
                                  ),
                                ),
                          )
                          : Image.network(
                            widget.service.coverImageUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                          : null,
                                  color: colorScheme.primary,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              logger.w(
                                'Failed to load service image: ${widget.service.coverImageUrl}',
                                error: error,
                              );
                              return Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  size: 60,
                                  color: colorScheme.error,
                                ),
                              );
                            },
                          ))
                      : Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 60,
                          color: AppColors.mediumGrey,
                        ),
                      ),
            ),
            const SizedBox(height: 24),

            // Seccion de Detalles del Servicio
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre del Servicio y Calificacion Promedio
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.service.name,
                          style: textTheme.headlineMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (!_isLoadingReviews && _reviews.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 24,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  averageRating.toStringAsFixed(1),
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${_reviews.length} resena${_reviews.length == 1 ? '' : 's'}',
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Precio
                  Text(
                    '\$${widget.service.price.toStringAsFixed(2)}',
                    style: textTheme.displaySmall?.copyWith(
                      color: AppColors.guacamayoGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Duracion (si existe)
                  if (widget.service.duration != null) ...[
                    Text(
                      'Duración estimada: ${widget.service.duration} horas',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface.withAlpha(
                          (255 * 0.8).round(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Descripcion
                  if (widget.service.description != null &&
                      widget.service.description!.isNotEmpty) ...[
                    Text(
                      'Descripción del Servicio',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.service.description!,
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Boton de Reserva
                  Center(
                    child: ElevatedButton.icon(
                      onPressed:
                          widget.service.isActive && !_isProcessingBooking
                              ? () => _createBooking()
                              : null,
                      icon: const Icon(Icons.shopping_cart_checkout),
                      label: Text(
                        widget.service.isActive
                            ? 'Reservar y Pagar'
                            : 'Servicio No Disponible',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        textStyle: textTheme.labelLarge,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Seccion de Resenas
            Container(
              color: AppColors.lightGrey,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reseñas y Calificaciones',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _isLoadingReviews
                      ? const Center(child: CircularProgressIndicator())
                      : _reviewsErrorMessage != null
                      ? Center(
                        child: Text(
                          _reviewsErrorMessage!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                      : _reviews.isEmpty
                      ? const Center(
                        child: Text('Este servicio aún no tiene reseñas.'),
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _reviews.length,
                        itemBuilder: (context, index) {
                          final review = _reviews[index];
                          final reviewerName =
                              review.reviewerProfile?.name ?? 'Anónimo';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        reviewerName,
                                        style: textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: List.generate(5, (
                                          startIndex,
                                        ) {
                                          return Icon(
                                            startIndex < review.rating
                                                ? Icons.star
                                                : Icons.star_border,
                                            color: Colors.amber,
                                            size: 20,
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (review.comment != null &&
                                      review.comment!.isNotEmpty)
                                    Text(
                                      review.comment!,
                                      style: textTheme.bodyMedium,
                                    ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Reseñado el: ${review.createdAt.toLocal().toString().split('.')[0]}',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
