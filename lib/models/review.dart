import 'profile.dart';
import 'service.dart';

class Review {
  final String id;
  final String bookingId;
  final String serviceId;
  final String reviewerId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final bool isVisible;

  final Profile? reviewerProfile;
  final Service? service;

  Review({
    required this.id,
    required this.bookingId,
    required this.serviceId,
    required this.reviewerId,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.isVisible,
    this.reviewerProfile,
    this.service,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id == null) {
      throw FormatException('Review JSON missing required field "id": $json');
    }
    final bookingId = json['booking_id'];
    if (bookingId == null) {
      throw FormatException(
        'Review JSON missing required field "booking_id": $json',
      );
    }
    final serviceId = json['service_id'];
    if (serviceId == null) {
      throw FormatException(
        'Review JSON missing required field "service_id": $json',
      );
    }
    final reviewerId = json['reviewer_id'];
    if (reviewerId == null) {
      throw FormatException(
        'Review JSON missing required field "reviewer_id": $json',
      );
    }
    final rating = json['rating'];
    if (rating == null) {
      throw FormatException(
        'Review JSON missing required field "rating": $json',
      );
    }
    final createdAtJson = json['created_at'];
    if (createdAtJson == null) {
      throw FormatException(
        'Review JSON missing required field "created_at": $json',
      );
    }
    final isVisible = json['is_visible'];
    if (isVisible == null) {
      throw FormatException(
        'Review JSON missing required field "is_visible": $json',
      );
    }

    final profileJson = json['profiles'];
    final associatedProfile =
        profileJson != null && profileJson is Map<String, dynamic>
            ? Profile.fromJson(profileJson)
            : null;

    final serviceJson = json['services'];
    final associatedService =
        serviceJson != null && serviceJson is Map<String, dynamic>
            ? Service.fromJson(serviceJson)
            : null;

    return Review(
      id: id as String,
      bookingId: bookingId as String,
      serviceId: serviceId as String,
      reviewerId: reviewerId as String,
      rating: rating as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(createdAtJson as String),
      isVisible: isVisible as bool,
      reviewerProfile: associatedProfile,
      service: associatedService,
    );
  }

  Review copyWith({
    String? id,
    String? bookingId,
    String? serviceId,
    String? reviewerId,
    int? rating,
    String? comment,
    DateTime? createdAt,
    bool? isVisible,
    Profile? reviewerProfile,
    Service? service,
  }) {
    return Review(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      serviceId: serviceId ?? this.serviceId,
      reviewerId: reviewerId ?? this.reviewerId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      isVisible: isVisible ?? this.isVisible,
      reviewerProfile: reviewerProfile ?? this.reviewerProfile,
      service: service ?? this.service,
    );
  }

  Map<String, dynamic> toJson({bool includeId = false}) {
    final Map<String, dynamic> json = {
      'booking_id': bookingId,
      'service_id': serviceId,
      'reviewer_id': reviewerId,
      'rating': rating,
      'comment': comment,
      'is_visible': isVisible,
    };
    if (includeId) {
      json['id'] = id;
    }
    return json;
  }

  @override
  String toString() {
    final reviewerName = reviewerProfile?.name ?? reviewerId.substring(0, 4);
    final serviceName = service?.name ?? serviceId.substring(0, 4);
    return 'Review(id: ${id.substring(0, 4)}..., Service: $serviceName, Reviewer: $reviewerName, Rating: $rating)';
  }
}
