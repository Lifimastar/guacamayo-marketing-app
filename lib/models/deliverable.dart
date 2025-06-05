class Deliverable {
  final String id;
  final String bookingId;
  final String title;
  final String? description;
  final String? fileUrl;
  final String? storagePath;
  final DateTime uploadedAt;
  final String? uploadedBy;

  Deliverable({
    required this.id,
    required this.bookingId,
    required this.title,
    this.description,
    this.fileUrl,
    this.storagePath,
    required this.uploadedAt,
    this.uploadedBy,
  });

  factory Deliverable.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id == null) {
      throw FormatException(
        'Deliverable JSON missing required field "id": $json',
      );
    }
    final bookingId = json['booking_id'];
    if (bookingId == null) {
      throw FormatException(
        'Deliverable JSON missing required field "booking_id": $json',
      );
    }
    final title = json['title'];
    if (title == null) {
      throw FormatException(
        'Deliverable JSON missing required field "title": $json',
      );
    }
    final uploadedAtJson = json['uploaded_at'];
    if (uploadedAtJson == null) {
      throw FormatException(
        'Deliverable JSON missing required field "uploaded_at": $json',
      );
    }

    return Deliverable(
      id: id as String,
      bookingId: bookingId as String,
      title: title as String,
      description: json['description'] as String?,
      fileUrl: json['file_url'] as String?,
      storagePath: json['storage_path'] as String?,
      uploadedAt: DateTime.parse(uploadedAtJson as String),
      uploadedBy: json['uploaded_by'] as String?,
    );
  }

  Deliverable copyWith({
    String? id,
    String? bookingId,
    String? title,
    String? description,
    String? fileUrl,
    String? storagePath,
    DateTime? uploadedAt,
    String? uploadedBy,
  }) {
    return Deliverable(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      title: title ?? this.title,
      description: description ?? this.description,
      fileUrl: fileUrl ?? this.fileUrl,
      storagePath: storagePath ?? this.storagePath,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      uploadedBy: uploadedBy ?? this.uploadedBy,
    );
  }

  Map<String, dynamic> toJson({bool includeId = false}) {
    final Map<String, dynamic> json = {
      'booking_id': bookingId,
      'title': title,
      'description': description,
      'file_url': fileUrl,
      'storage_path': storagePath,
    };
    if (includeId) {
      json['id'] = id;
    }
    return json;
  }

  @override
  String toString() {
    return 'Deliverable(id: ${id.substring(0, 4)}..., Title: $title, Booking: ${bookingId.substring(0, 4)}...)';
  }
}
