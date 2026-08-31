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
