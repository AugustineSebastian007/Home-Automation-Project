import 'package:flutter/material.dart';

class BottomBarNavItemModel {

  final IconData iconOption;
  final String label;
  final String route;
  final bool isSelected;

  const BottomBarNavItemModel ({
    required this.iconOption,
    this.label = '',
    required this.route,
    this.isSelected = false,
  });

  BottomBarNavItemModel copyWith({
  IconData? iconOption,
  String? label,
  String? route,
  bool? isSelected,
  }){
    return BottomBarNavItemModel(
      iconOption: iconOption ?? this.iconOption,
      label: label ?? this.label,
      route: route ?? this.route,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

