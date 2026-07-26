class Vehicle {
  final int? id;
  final String name; // e.g. "Toyota Innova"
  final String number; // e.g. "TN 10 AB 1234"
  final bool active;

  Vehicle({this.id, required this.name, required this.number, this.active = true});

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'number': number,
        'active': active ? 1 : 0,
      };

  factory Vehicle.fromMap(Map<String, dynamic> m) => Vehicle(
        id: m['id'] as int?,
        name: m['name'] as String,
        number: m['number'] as String,
        active: (m['active'] as int? ?? 1) == 1,
      );
}
