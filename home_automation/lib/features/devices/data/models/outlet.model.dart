class OutletModel {
  final int id;
  final String ip;
  final String label;
  final bool isTaken;

  OutletModel({
    required this.id,
    required this.ip,
    required this.label,
    this.isTaken = false,
  });

  // Add this method
  OutletModel copyWith({
    int? id,
    String? ip,
    String? label,
    bool? isTaken,
  }) {
    return OutletModel(
      id: id ?? this.id,
      ip: ip ?? this.ip,
      label: label ?? this.label,
      isTaken: isTaken ?? this.isTaken,
    );
  }

  factory OutletModel.fromJson(Map<String, dynamic> json) {
    return OutletModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()), // Ensure id is parsed as int
      ip: json['ip'] ?? '', // Provide a default value if null
      label: json['label'] ?? '', // Provide a default value if null
      isTaken: json['isTaken'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': label,
      'ip': ip,
      'isTaken': isTaken,
    };
  }
}