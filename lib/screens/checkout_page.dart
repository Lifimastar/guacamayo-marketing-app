import 'package:flutter/material.dart';
import '../utils/logger.dart';
import '../models/booking.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/config.dart';
import '../style/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service.dart';

class CheckoutPage extends StatefulWidget {
  final Booking booking;
  final Service service;
  const CheckoutPage({super.key, required this.booking, required this.service});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _supabase = Supabase.instance.client;
  bool _isProcessingPayment = false;
  bool _isCancelling = false;
  String? _paymentErrorMessage;

  Future<Map<String, dynamic>> _createPaymentIntent(
    String bookingId,
    double amount,
    String currency,
  ) async {
    final url = Uri.parse(paymentIntentBackendUrl);

    final headers = {
      'Content-Type': 'application/json',
      'apikey': supabaseAnonKey,
    };

    final body = json.encode({
      'bookingId': bookingId,
      'amount': (amount * 100).toInt(),
      'currency': currency,
      'metadata': {'booking_id': bookingId, 'user_id': widget.booking.userId},
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        logger.w(
          'Backend error creating Payment Intent: ${response.statusCode} - ${response.body}',
        );
        try {
          final errorJson = json.decode(response.body);
          if (errorJson != null && errorJson['message'] != null) {
            throw Exception(
              'Failed to create Payment Intent from backend: ${errorJson['message']}',
            );
          }
        } catch (e) {
          throw Exception(
            'Failed to create Payment Intent from backend: ${response.body}',
          );
        }
        throw Exception(
          'Failed to create Payment Intent from backend (unknown error format)',
        );
      }
    } catch (e) {
      logger.e('HTTP error creating Payment Intent: $e', error: e);
      throw Exception('Error calling backend to create Payment Intent: $e');
    }
  }

  Future<void> _initPaymentSheet() async {
    setState(() {
      _isProcessingPayment = true;
      _paymentErrorMessage = null;
    });

    try {
      final paymentIntentData = await _createPaymentIntent(
        widget.booking.id,
        widget.booking.totalPrice,
        'usd', 
      );

      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentData['paymentIntent'],
          customerEphemeralKeySecret: paymentIntentData['ephemeralKey'],
          customerId: paymentIntentData['customer'],
          merchantDisplayName: 'Guacamayo Marketing',
        ),
      );

      _displayPaymentSheet();
    } on Exception catch (e) {
      if (!mounted) return; 
      logger.e('Error initializing Payment Sheet: $e', error: e);
      setState(() {
        _paymentErrorMessage = 'Error al preparar el pago: ${e.toString()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al preparar el pago: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessingPayment = false;
      });
    }
  }

  Future<void> _displayPaymentSheet() async {
    setState(() {
      _isProcessingPayment = true;
    });

    try {
      await stripe.Stripe.instance.presentPaymentSheet();

      logger.i('Payment Sheet presented successfully.');
      if (!mounted) return; 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pago exitoso! Procesando...'),
          backgroundColor: Colors.green,
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return; 
        Navigator.pop(context);
      });
    } on Exception catch (e) {
      logger.e('Error displaying Payment Sheet: $e', error: e);
      String message = 'Error en el pago: ${e.toString()}';
      if (e is stripe.StripeException) {
        message = 'Error en el pago: ${e.error.localizedMessage}';
        logger.e(
          'Stripe Exception: ${e.error.code} - ${e.error.localizedMessage}',
        );
      }
      setState(() {
        _paymentErrorMessage = message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isProcessingPayment = false;
      });
    }
  }

  // Metodo para cancelar la reserva
  Future<void> _cancelBooking() async {
    if (!mounted) return;
    setState(() {
      _isCancelling = true;
    });

    try {
      // actualizar el estado de la reserva a 'cancelled' en la base de datos
      await _supabase
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', widget.booking.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reserva cancelada.'),
          backgroundColor: AppColors.mediumGrey,
        ),
      );
      Navigator.pop(context);
    } on PostgrestException catch (e) {
      if (!mounted) return;
      logger.e('Error cancelling booking: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cancelar la reserva: ${e.message}'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      logger.e('Unexpected error cancelling booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ocurrio un error inesperado al cancelar: ${e.toString()}',
          ),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isCancelling = false;
      });
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
    final service = widget.service;

    return Scaffold(
      appBar: AppBar(title: const Text('Finalizar Reserva y Pagar')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Resumen de la Reserva',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Servicio: ${service.name}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Precio: \$${widget.booking.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),

                        const SizedBox(height: 8),
                        Text(
                          'Estado Inicial: ${_getStatusText(widget.booking.status)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                const Text(
                  'Información de Pago',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 20),

                if (_paymentErrorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      _paymentErrorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),

                ElevatedButton(
                  onPressed: _isProcessingPayment ? null : _initPaymentSheet,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child:
                      _isProcessingPayment
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3.0,
                            ),
                          )
                          : const Text('Pagar con Tarjeta'),
                ),

                const SizedBox(height: 20),
                // Boton Cancelar Reserva
                TextButton(
                  onPressed:
                      (_isProcessingPayment || _isCancelling)
                          ? null
                          : _cancelBooking,
                  child:
                      _isCancelling
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(),
                          )
                          : const Text(
                            'Cancelar Reserva',
                            style: TextStyle(color: AppColors.errorColor),
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
