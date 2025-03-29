class HouseholdMemberModel {
  final String id;
  final String name;
  final String? profileId;
  final Map<String, List<double>> faceData;
  final DateTime createdAt;

  HouseholdMemberModel({
    required this.id,
    required this.name,
    this.profileId,
    required this.faceData,
    required this.createdAt,
  });

  factory HouseholdMemberModel.fromJson(Map<String, dynamic> json) {
    Map<String, List<double>> convertedFaceData = {};
    Map<String, dynamic> rawFaceData = json['faceData'] as Map<String, dynamic>;
    
    rawFaceData.forEach((key, value) {
      if (value is Map<String, dynamic> && value.containsKey('vector')) {
        convertedFaceData[key] = (value['vector'] as List<dynamic>)
            .map((n) => (n as num).toDouble())
            .toList();
      } else if (value is List<dynamic>) {
        convertedFaceData[key] = value
            .map((n) => (n as num).toDouble())
            .toList();
      }
    });

    return HouseholdMemberModel(
      id: json['id'] as String,
      name: json['name'] as String,
      profileId: json['profileId'] as String?,
      faceData: convertedFaceData,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profileId': profileId,
      'faceData': faceData,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
