class UserModel {
  final String id;
  final String username;
  final String email;
  final String? jwtToken;
  final Map<String, dynamic> preferences;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.jwtToken,
    this.preferences = const {},
  });

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? jwtToken,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      jwtToken: jwtToken ?? this.jwtToken,
      preferences: preferences ?? this.preferences,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'jwtToken': jwtToken,
      'preferences': preferences,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      jwtToken: map['jwtToken'],
      // Safely clone Map to avoid mutability linkage
      preferences: Map<String, dynamic>.from(map['preferences'] ?? {}),
    );
  }
}
