import 'package:flutter/widgets.dart';

class BottomNavItem {
  final String label;
  final String route;
  final Widget page;

  const BottomNavItem({
    required this.label,
    required this.route,
    required this.page,
  });
}