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
}
