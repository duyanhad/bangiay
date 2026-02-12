class AppUser {
  final String id;
  final String email;
  final String name;
  final String role;

  final String? phone;
  final String? address;

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.address,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      role: (json['role'] ?? 'user').toString(),
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
    );
  }
}

class AuthResult {
  final String token;
  final AppUser user;

  const AuthResult({required this.token, required this.user});

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      token: (json['token'] ?? '').toString(),
      user: AppUser.fromJson((json['user'] ?? {}) as Map<String, dynamic>),
    );
  }
}
