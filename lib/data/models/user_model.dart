class UserModel {
  final String id;
  final String username;
  final String email;
  final String? jwtToken;
  final Map<String, dynamic> preferences;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.jwtToken,
    this.preferences = const {},
    this.createdAt,
  });

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? jwtToken,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      jwtToken: jwtToken ?? this.jwtToken,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'jwtToken': jwtToken,
      'preferences': preferences,
      'createdAt': createdAt?.millisecondsSinceEpoch,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      jwtToken: map['jwtToken'],
      preferences: Map<String, dynamic>.from(map['preferences'] ?? {}),
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : null,
    );
  }
}
