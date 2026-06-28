/// A person to notify when a crash is detected.
class EmergencyContact {
  final String name;
  final String phone; // E.164 preferred, e.g. +9055...

  const EmergencyContact({required this.name, required this.phone});

  Map<String, dynamic> toJson() => {'name': name, 'phone': phone};

  factory EmergencyContact.fromJson(Map<String, dynamic> j) => EmergencyContact(
        name: j['name'] as String,
        phone: j['phone'] as String,
      );
}
