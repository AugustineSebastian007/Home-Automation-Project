class OutletModel {
  final String id;
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
    String? id,
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
      id: json['id'].toString(), // Ensure id is stored as String
      ip: json['ip'] ?? '',
      label: json['label'] ?? '',
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