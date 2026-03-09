class PasswordEntry {
  final int? id;
  final String serviceName;
  final String username;
  final String encryptedPassword;
  final String? iv; // NOVO CAMPO
  final DateTime createdAt;
  final DateTime? updatedAt;

  PasswordEntry({
    this.id,
    required this.serviceName,
    required this.username,
    required this.encryptedPassword,
    this.iv, // NOVO CAMPO
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serviceName': serviceName,
      'username': username,
      'encryptedPassword': encryptedPassword,
      'iv': iv, // NOVO CAMPO
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
      iv: map['iv'], // NOVO CAMPO
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
    );
  }

  PasswordEntry copyWith({
    int? id,
    String? serviceName,
    String? username,
    String? encryptedPassword,
    String? iv,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PasswordEntry(
      id: id ?? this.id,
      serviceName: serviceName ?? this.serviceName,
      username: username ?? this.username,
      encryptedPassword: encryptedPassword ?? this.encryptedPassword,
      iv: iv ?? this.iv,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
