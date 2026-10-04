import 'package:flutter/material.dart';

class SchoolBrandModel {
  final String schoolName;
  final String logoUrl;
  final Color primaryColor;
  final Color secondaryColor;
  final String affiliation;
  final String motto;

  const SchoolBrandModel({
    required this.schoolName,
    required this.logoUrl,
    required this.primaryColor,
    required this.secondaryColor,
    required this.affiliation,
    required this.motto,
  });
}
