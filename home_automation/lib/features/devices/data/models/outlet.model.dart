class OutletModel {
  final String id;
  final String label;
  final String ip;
  final bool isTaken;

  OutletModel({
    required this.id,
    required this.label,
    required this.ip,
    this.isTaken = false,
  });

  // Add this method
  OutletModel copyWith({
    String? id,
    String? label,
    String? ip,
    bool? isTaken,
  }) {
    return OutletModel(
      id: id ?? this.id,
      label: label ?? this.label,
      ip: ip ?? this.ip,
      isTaken: isTaken ?? this.isTaken,
    );
  }

  factory OutletModel.fromJson(Map<String, dynamic> json, String docId) {
    return OutletModel(
      id: json['id'].toString(),
      label: json['name'],
      ip: json['ip'],
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