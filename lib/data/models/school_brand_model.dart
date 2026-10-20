import 'package:flutter/material.dart';

class SchoolBrandModel {
  final String schoolName;
  final String logoUrl;
  final Color primaryColor;
  final Color secondaryColor;
  final String affiliation;
  final String motto;
  final String address;
  final String phone;
  final String email;
  final String schoolCode;
  final String currentAcademicYear;

  const SchoolBrandModel({
    required this.schoolName,
    required this.logoUrl,
    required this.primaryColor,
    required this.secondaryColor,
    required this.affiliation,
    required this.motto,
    this.address = '',
    this.phone = '',
    this.email = '',
    this.schoolCode = '',
    this.currentAcademicYear = '',
  });

  /// School record from `parent_get_school`. Fields the school has not
  /// filled in stay empty; no affiliation, motto or contact is invented.
  factory SchoolBrandModel.fromMap(Map<String, dynamic> map, {String fallbackName = 'School Portal'}) {
    String s(dynamic v) => (v == null || v.toString() == 'null') ? '' : v.toString().trim();
    final ay = map['current_academic_year'] is Map ? Map<String, dynamic>.from(map['current_academic_year'] as Map) : const {};
    return SchoolBrandModel(
      schoolName: s(map['name']).isNotEmpty ? s(map['name']) : fallbackName,
      logoUrl: s(map['logo_url']),
      primaryColor: const Color(0xFF10182D),
      secondaryColor: const Color(0xFF4F46E5),
      affiliation: '',
      motto: '',
      address: s(map['address']),
      phone: s(map['phone']),
      email: s(map['email']),
      schoolCode: s(map['code']),
      currentAcademicYear: s(ay['name']),
    );
  }

  /// Neutral initial state (never defaults to Xavier Academy or KPS)
  factory SchoolBrandModel.defaultNeutral({String schoolName = 'School Portal'}) {
    return SchoolBrandModel(
      schoolName: schoolName,
      logoUrl: '',
      primaryColor: const Color(0xFF10182D),
      secondaryColor: const Color(0xFF4F46E5),
      affiliation: '',
      motto: '',
      address: '',
      phone: '',
      email: '',
    );
  }
}
