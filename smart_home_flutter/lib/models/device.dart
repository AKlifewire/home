class Device {
  final String id;
  final String name;
  final String type;
  final Map<String, dynamic> status;
  final String owner;
  final DateTime createdAt;
  final DateTime updatedAt;

  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.owner,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      status: json['status'] != null 
          ? Map<String, dynamic>.from(json['status'])
          : {},
      owner: json['owner'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'status': status,
      'owner': owner,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Device copyWith({
    String? id,
    String? name,
    String? type,
    Map<String, dynamic>? status,
    String? owner,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      owner: owner ?? this.owner,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}