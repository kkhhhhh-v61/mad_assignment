class States {
  final String id;
  final String name;

  States({required this.id, required this.name});

  factory States.fromJson(Map<String, dynamic> json) {
    return States(
      id: json['id']?.toString() ?? "",
      name: json['name']?.toString() ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

class AppUser {
  final String id;
  final String email;
  final String role;
  final String name;
  final String phone;
  final String address;

  AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
    required this.phone,
    required this.address,
  });

  factory AppUser.fromJson(Map<String, dynamic> json, String email) {
    return AppUser(
      id: json['id']?.toString() ?? "",
      email: email,
      role: json['role']?.toString() ?? "customer",
      name: json['name']?.toString() ?? "",
      phone: json['phone']?.toString() ?? "",
      address: json['address']?.toString() ?? "",
    );
  }
}