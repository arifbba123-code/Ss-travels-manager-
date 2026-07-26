class Driver {
  final int? id;
  final String name;
  final String phone;
  final bool active;

  Driver({this.id, required this.name, required this.phone, this.active = true});

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'active': active ? 1 : 0,
      };

  factory Driver.fromMap(Map<String, dynamic> m) => Driver(
        id: m['id'] as int?,
        name: m['name'] as String,
        phone: m['phone'] as String,
        active: (m['active'] as int? ?? 1) == 1,
      );
}
