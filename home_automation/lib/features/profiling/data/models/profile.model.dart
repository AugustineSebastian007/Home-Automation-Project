class ProfileModel {
  final String id;
  final String name;
  final List<String> deviceIds;
  final bool isActive;

  ProfileModel({
    required this.id,
    required this.name,
    required this.deviceIds,
    this.isActive = false,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      deviceIds: List<String>.from(json['deviceIds'] as List),
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'deviceIds': deviceIds,
      'isActive': isActive,
    };
  }

  ProfileModel copyWith({
    String? id,
    String? name,
    List<String>? deviceIds,
    bool? isActive,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      deviceIds: deviceIds ?? this.deviceIds,
      isActive: isActive ?? this.isActive,
    );
  }
}