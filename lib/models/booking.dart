import 'service.dart';
import 'profile.dart';

class Booking {
  final String id;
  final String userId;
  final String serviceId;
  final DateTime bookedAt;
  final String status;
  final double totalPrice;
  final String? notes;
  final DateTime? startDate;
  final DateTime? endDate;
  final Service? service;
  final Profile? userProfile;
  final Map<String, dynamic>? reviewData;
  final String? paymentId;

  Booking({
    required this.id,
    required this.userId,
    required this.serviceId,
    required this.bookedAt,
    required this.status,
    required this.totalPrice,
    this.notes,
    this.startDate,
    this.endDate,
    this.service,
    this.userProfile,
    this.reviewData,
    this.paymentId,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id == null) {
      throw FormatException('Booking JSON missing required field "id": $json');
    }
    final userId = json['user_id'];
    if (userId == null) {
      throw FormatException(
        'Booking JSON missing required field "user_id": $json',
      );
    }
    final serviceId = json['service_id'];
    if (serviceId == null) {
      throw FormatException(
        'Booking JSON missing required field "service_id": $json',
      );
    }
    final bookedAtJson = json['booked_at'];
    if (bookedAtJson == null) {
      throw FormatException(
        'Booking JSON missing required field "booked_at": $json',
      );
    }
    final status = json['status'];
    if (status == null) {
      throw FormatException(
        'Booking JSON missing required field "status": $json',
      );
    }
    final totalPriceJson = json['total_price'];
    if (totalPriceJson == null) {
      throw FormatException(
        'Booking JSON missing required field "total_price": $json',
      );
    }

    final serviceJson = json['services'];
    final associatedService =
        serviceJson != null && serviceJson is Map<String, dynamic>
            ? Service.fromJson(serviceJson)
            : null;

    final profileJson = json['profiles'];
    final associatedProfile =
        profileJson != null && profileJson is Map<String, dynamic>
            ? Profile.fromJson(profileJson)
            : null;

    final reviewJson = json['reviews'];
    Map<String, dynamic>? associatedReviewData;

    if (reviewJson != null && reviewJson is Map<String, dynamic>) {
      associatedReviewData = reviewJson;
    }

    return Booking(
      id: id as String,
      userId: userId as String,
      serviceId: serviceId as String,
      bookedAt: DateTime.parse(bookedAtJson as String),
      status: status as String,
      totalPrice: (totalPriceJson as num).toDouble(),
      notes: json['notes'] as String?,
      startDate:
          json['start_date'] != null
              ? DateTime.parse(json['start_date'] as String)
              : null,
      endDate:
          json['end_date'] != null
              ? DateTime.parse(json['end_date'] as String)
              : null,
      service: associatedService,
      userProfile: associatedProfile,
      reviewData: associatedReviewData,
      paymentId: json['payment_id'] as String?,
    );
  }

  bool get hasReview => reviewData != null;
  bool get hasPayment => paymentId != null;

  Booking copyWith({
    String? id,
    String? userId,
    String? serviceId,
    DateTime? bookedAt,
    String? status,
    double? totalPrice,
    String? notes,
    DateTime? startDate,
    DateTime? endDate,
    Service? service,
    Profile? userProfile,
    Map<String, dynamic>? reviewData,
    String? paymentId,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      serviceId: serviceId ?? this.serviceId,
      bookedAt: bookedAt ?? this.bookedAt,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      notes: notes ?? this.notes,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      service: service ?? this.service,
      userProfile: userProfile ?? this.userProfile,
      reviewData: reviewData ?? this.reviewData,
      paymentId: paymentId ?? this.paymentId,
    );
  }

  Map<String, dynamic> toJson({bool includeId = false}) {
    final Map<String, dynamic> json = {
      'user_id': userId,
      'service_id': serviceId,
      'booked_at': bookedAt.toIso8601String(),
      'status': status,
      'total_price': totalPrice,
      'notes': notes,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'payment_id': paymentId,
    };
    if (includeId) {
      json['id'] = id;
    }
    return json;
  }

  @override
  String toString() {
    final serviceName = service?.name ?? 'ID: ${serviceId.substring(0, 4)}...';
    final customerName = userProfile?.name ?? userId.substring(0, 4);
    return 'Booking(id: ${id.substring(0, 4)}..., Service: $serviceName, Customer: $customerName, Status: $status, HasReview: $hasReview, HasPayment: $hasPayment)';
  }
}
