import 'package:flutter/material.dart';

class UserContact {
  final String name;
  final Color color;
  final String? imageUrl;

  UserContact({
    required this.name,
    required this.color,
    this.imageUrl,
  });
}