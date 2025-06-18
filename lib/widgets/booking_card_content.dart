import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/logger.dart';
import '../utils/booking_status_utils.dart';
import '../models/booking.dart';
import '../style/app_colors.dart';

class BookingCardContent extends StatelessWidget {
  final Booking booking;
  final VoidCallback onEntregablesTap;
  final VoidCallback? onLeaveReviewTap;
  final bool isAdminView;
  final List<String>? bookingStatuses;
  final Map<String, bool>? isUpdatingStatus;
  final Function(String, String)? onStatusChange;
  final Map<String, bool>? isProcessingBookingAction;
  final VoidCallback? onCancelBookingTap;
  final VoidCallback? onDeleteBookingTap;

  const BookingCardContent({
    super.key,
    required this.booking,
    required this.onEntregablesTap,
    this.onLeaveReviewTap,
    this.isAdminView = false,
    this.bookingStatuses,
    this.isUpdatingStatus,
    this.onStatusChange,
    this.isProcessingBookingAction,
    this.onCancelBookingTap,
    this.onDeleteBookingTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final service = booking.service;
    final customerProfile = booking.userProfile;
    // Determinar si esta reserva especifica esta en proceso de alguna accion
    final bool isProcessingThisBooking =
        (isProcessingBookingAction?[booking.id] ?? false);
    final bool isUpdatingStatusForThisBooking =
        (isUpdatingStatus?[booking.id] ?? false);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen del Servicio (si existe)
          if (service?.coverImageUrl != null &&
              service!.coverImageUrl!.isNotEmpty) ...[
            Align(
              alignment: isAdminView ? Alignment.centerLeft : Alignment.center,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4.0),
                child:
                    service.coverImageUrl!.toLowerCase().endsWith('.svg')
                        ? SvgPicture.network(
                          service.coverImageUrl!,
                          height: 80,
                          width: 80,
                          fit: BoxFit.contain,
                          placeholderBuilder:
                              (BuildContext context) => Container(
                                height: 80,
                                width: 80,
                                color: AppColors.lightGrey,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                        )
                        : Image.network(
                          service.coverImageUrl!,
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            logger.w(
                              'Failed to load image for booking ${booking.id}: ${service.coverImageUrl}',
                              error: error,
                            );
                            return Container(
                              height: 80,
                              width: 80,
                              color: AppColors.mediumGrey,
                              child: Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  size: 30,
                                  color: colorScheme.error,
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ID de la Reserva (solo en vista de Admin)
          if (isAdminView) ...[
            Text(
              'Reserva ID: ${booking.id.substring(0, 8)}...',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withAlpha((255 * 0.6).round()),
              ),
            ),
            const SizedBox(height: 4),
          ],

          // Nombre del Servicio
          Text(
            'Servicio: ${service?.name ?? 'Cargando...'}',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Nombre del Cliente (solo en vista de Admin)
          if (isAdminView) ...[
            Text(
              'Cliente: ${customerProfile?.name ?? 'Cargando...'}',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withAlpha((255 * 0.8).round()),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Estado de la reserva
          Text(
            'Estado: ${BookingStatusUtils.getStatusText(booking.status)}',
            style: textTheme.bodyLarge?.copyWith(
              color: BookingStatusUtils.getStatusColor(booking.status),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Precio de la reserva
          Text(
            'Precio: \$${booking.totalPrice.toStringAsFixed(2)}',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.statusCompleted,
            ),
          ),
          const SizedBox(height: 8),

          // Fecha de la reserva
          Text(
            'Fecha Reservada: ${booking.bookedAt.toLocal().toString().split('.')[0]}',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withAlpha((255 * 0.6).round()),
            ),
          ),
          const SizedBox(height: 16),

          // Botones de acción (Entregables, Chat, y Reseña/Selector de Estado en Admin)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Grupo de Estado (solo en Admin) o Espacio (en Cliente)
              if (isAdminView &&
                  bookingStatuses != null &&
                  isUpdatingStatus != null &&
                  onStatusChange != null) ...[
                // Selector de Estado (en Admin)
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Estado:', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: DropdownButton<String>(
                          value: booking.status,
                          items:
                              bookingStatuses!.map((String status) {
                                return DropdownMenuItem<String>(
                                  value: status,
                                  child: Text(
                                    BookingStatusUtils.getStatusText(status),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                          onChanged:
                              isProcessingThisBooking
                                  ? null
                                  : (String? newValue) {
                                    if (newValue != null &&
                                        newValue != booking.status) {
                                      onStatusChange!(booking.id, newValue);
                                    }
                                  },
                          style: textTheme.bodyMedium,
                          underline: Container(),
                          isExpanded: true,
                          icon:
                              isUpdatingStatusForThisBooking
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.0,
                                    ),
                                  )
                                  : const Icon(Icons.arrow_drop_down),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (!isAdminView) ...[
                Expanded(child: Container()),
              ],

              // Botones de acción (Entregables, Chat, y Reseña en Cliente)
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 4.0,
                runSpacing: 4.0,
                children: [
                  TextButton(
                    onPressed: onEntregablesTap,
                    child: const Text('Entregables'),
                  ),

                  // Boton Eliminar Reserva (solo para Admin)
                  if (isAdminView && onDeleteBookingTap != null)
                    IconButton(
                      icon:
                          isProcessingThisBooking
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  color: Colors.red,
                                ),
                              )
                              : Icon(
                                Icons.delete_forever,
                                color: theme.colorScheme.error,
                              ),
                      tooltip: 'Eliminar Reserva Permanentemente',
                      onPressed:
                          isProcessingThisBooking ? null : onDeleteBookingTap,
                    ),

                  // Botones para Cliente
                  if (!isAdminView) ...[
                    // Boton Cancelar Reserva (para cliente)
                    if (onCancelBookingTap != null &&
                        (booking.status == 'checkout_pending' ||
                            booking.status == 'pending' ||
                            booking.status == 'confirmed'))
                      TextButton(
                        onPressed:
                            isProcessingThisBooking ? null : onCancelBookingTap,
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                        child:
                            isProcessingThisBooking
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                    color: Colors.red,
                                  ),
                                )
                                : const Text('Cancelar'),
                      ),

                    // Botón/Texto de Reseña (solo en vista de Cliente)
                    if (booking.status == 'completed' &&
                        !booking.hasReview) ...[
                      ElevatedButton(
                        onPressed:
                            isProcessingThisBooking ? null : onLeaveReviewTap,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          textStyle: textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child:
                            isProcessingThisBooking
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                    color: Colors.white,
                                  ),
                                )
                                : const Text('Dejar Reseña'),
                      ),
                    ],
                    if (booking.hasReview) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 12.0,
                        ),
                        child: Text(
                          'Reseñado',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.statusCompleted,
                            fontStyle: FontStyle.italic,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
