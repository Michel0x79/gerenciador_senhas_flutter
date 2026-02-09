class PasswordEntry {
  final int? id;
  final String serviceName;
  final String username;
  final String encryptedPassword;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PasswordEntry({
    this.id,
    required this.serviceName,
    required this.username,
    required this.encryptedPassword,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serviceName': serviceName,
      'username': username,
      'encryptedPassword': encryptedPassword,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory PasswordEntry.fromMap(Map<String, dynamic> map) {
    return PasswordEntry(
      id: map['id'],
      serviceName: map['serviceName'],
      username: map['username'],
      encryptedPassword: map['encryptedPassword'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  PasswordEntry copyWith({
    int? id,
    String? serviceName,
    String? username,
    String? encryptedPassword,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PasswordEntry(
      id: id ?? this.id,
      serviceName: serviceName ?? this.serviceName,
      username: username ?? this.username,
      encryptedPassword: encryptedPassword ?? this.encryptedPassword,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
