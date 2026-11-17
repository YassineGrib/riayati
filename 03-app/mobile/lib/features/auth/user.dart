class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.linked,
    this.partnerRole,
  });
  final int id;
  final String name, email, role;
  final bool linked;
  final String? partnerRole;
  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as int,
    name: json['name'] as String,
    email: json['email'] as String,
    role: json['role'] as String,
    linked: json['linked'] as bool? ?? false,
    partnerRole: json['partner_role'] as String?,
  );
  User unlinked() =>
      User(id: id, name: name, email: email, role: role, linked: false);
}
