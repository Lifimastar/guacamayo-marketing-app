class Service {
  final String id;
  final String name;
  final String? description;
  final double price;
  final int? duration;
  final bool isActive;
  final String? coverImageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Service({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.duration,
    required this.isActive,
    this.coverImageUrl,
    required this.createdAt,
    this.updatedAt,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id == null) {
      throw FormatException('Service JSON missing required field "id": $json');
    }
    final name = json['name'];
    if (name == null) {
      throw FormatException(
        'Service JSON missing required field "name": $json',
      );
    }
    final priceJson = json['price'];
    if (priceJson == null) {
      throw FormatException(
        'Service JSON missing required field "price": $json',
      );
    }
    final isActiveJson = json['is_active'];
    if (isActiveJson == null) {
      throw FormatException(
        'Service JSON missing required field "is_active": $json',
      );
    }
    final createdAtJson = json['created_at'];
    if (createdAtJson == null) {
      throw FormatException(
        'Service JSON missing required field "created_at": $json',
      );
    }

    return Service(
      id: id as String,
      name: name as String,
      description: json['description'] as String?,
      price: (priceJson as num).toDouble(),
      duration: json['duration'] as int?,
      isActive: isActiveJson as bool,
      coverImageUrl: json['cover_image_url'] as String?,
      createdAt: DateTime.parse(createdAtJson as String),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
    );
  }

  Service copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    int? duration,
    bool? isActive,
    String? coverImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Service(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      duration: duration ?? this.duration,
      isActive: isActive ?? this.isActive,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'duration': duration,
      'is_active': isActive,
      'cover_image_url': coverImageUrl,
    };
  }

  @override
  String toString() {
    return 'Service(id: $id, name: $name, price: $price, isActive: $isActive)';
  }
}
