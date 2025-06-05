class Profile {
  final String id;
  final String name;
  final String role;

  Profile({required this.id, required this.name, required this.role});

  factory Profile.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id == null) {
      throw FormatException('Profile JSON missing required field "id": $json');
    }

    return Profile(
      id: id as String,
      name: json['name'] as String? ?? 'Usuario',
      role: json['role'] as String? ?? 'client',
    );
  }

  Profile copyWith({String? id, String? name, String? role}) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'role': role};
  }
}
