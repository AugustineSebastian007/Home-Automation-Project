import 'package:home_automation/helpers/enums.dart';

class DeviceModel {

  final String id; // Add this line
  final FlickyAnimatedIconOptions iconOption;
  final String label;
  final bool isSelected;
  final int outlet;

  const DeviceModel({
    required this.id, // Add this line
    required this.iconOption,
    required this.label,
    required this.isSelected,
    required this.outlet,
  });

  DeviceModel copyWith({
    String? id,
    FlickyAnimatedIconOptions? iconOption,
    String? label,
    bool? isSelected,
    int? outlet,
  }) {

    return DeviceModel(
      id: id ?? this.id,
      iconOption: iconOption ?? this.iconOption,
      label: label ?? this.label,
      isSelected: isSelected ?? this.isSelected,
      outlet: outlet ?? this.outlet
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, // Add this line
      'label': label,
      'iconOption': iconOption.name,
      'isSelected': isSelected,
      'outlet': outlet
    };
  }

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] ?? '', // Add this line
      iconOption: FlickyAnimatedIconOptions.values.firstWhere((o) => o.name == json['iconOption']),
      label: json['label'], 
      isSelected: json['isSelected'], 
      outlet: json['outlet']
    );
  }
}