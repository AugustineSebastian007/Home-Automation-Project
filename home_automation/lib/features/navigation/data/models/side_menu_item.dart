import 'package:flutter/material.dart';

class SideMenuItem {

  final IconData icon;
  String? label;
  String? route;
  final VoidCallback onPressed;

  SideMenuItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.onPressed,
  });
}