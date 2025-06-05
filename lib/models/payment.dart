class Payment {
  final String id;
  final String bookingId;
  final String userId;
  final double amount;
  final String currency;
  final String status;
  final String? paymentGateway;
  final String? gatewayPaymentId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Payment({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.status,
    this.paymentGateway,
    this.gatewayPaymentId,
    required this.createdAt,
    this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id == null) {
      throw FormatException('Payment JSON missing required field "id": $json');
    }
    final bookingId = json['booking_id'];
    if (bookingId == null) {
      throw FormatException(
        'Payment JSON missing required field "booking_id": $json',
      );
    }
    final userId = json['user_id'];
    if (userId == null) {
      throw FormatException(
        'Payment JSON missing required field "user_id": $json',
      );
    }
    final amountJson = json['amount'];
    if (amountJson == null) {
      throw FormatException(
        'Payment JSON missing required field "amount": $json',
      );
    }
    final currency = json['currency'];
    if (currency == null) {
      throw FormatException(
        'Payment JSON missing required field "currency": $json',
      );
    }
    final status = json['status'];
    if (status == null) {
      throw FormatException(
        'Payment JSON missing required field "status": $json',
      );
    }
    final createdAtJson = json['created_at'];
    if (createdAtJson == null) {
      throw FormatException(
        'Payment JSON missing required field "created_at": $json',
      );
    }

    return Payment(
      id: id as String,
      bookingId: bookingId as String,
      userId: userId as String,
      amount: (amountJson as num).toDouble(),
      currency: currency as String,
      status: status as String,
      paymentGateway: json['payment_gateway'] as String?,
      gatewayPaymentId: json['gateway_payment_id'] as String?,
      createdAt: DateTime.parse(createdAtJson as String),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
    );
  }

  Payment copyWith({
    String? id,
    String? bookingId,
    String? userId,
    double? amount,
    String? currency,
    String? status,
    String? paymentGateway,
    String? gatewayPaymentId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paymentGateway: paymentGateway ?? this.paymentGateway,
      gatewayPaymentId: gatewayPaymentId ?? this.gatewayPaymentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson({bool includeId = false}) {
    final Map<String, dynamic> json = {
      'booking_id': bookingId,
      'user_id': userId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'payment_gateway': paymentGateway,
      'gateway_payment_id': gatewayPaymentId,
    };
    if (includeId) {
      json['id'] = id;
    }
    return json;
  }

  @override
  String toString() {
    return 'Payment(id: ${id.substring(0, 4)}..., Booking: ${bookingId.substring(0, 4)}..., Amount: $amount $currency, Status: $status)';
  }
}
