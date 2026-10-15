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
  });

  /// Factory to parse authoritative database record from public.schools
  factory SchoolBrandModel.fromMap(Map<String, dynamic> map, {String fallbackName = 'School Portal'}) {
    final rawName = (map['name'] ?? map['school_name'] ?? map['title'])?.toString().trim();
    final cleanName = (rawName != null && rawName.isNotEmpty) ? rawName : fallbackName;

    final rawLogo = (map['logo_url'] ?? map['logo'] ?? map['avatar_url'])?.toString().trim();
    final cleanLogo = (rawLogo != null && rawLogo.isNotEmpty) ? rawLogo : '';

    final rawAffiliation = (map['affiliation'] ?? map['board'] ?? map['board_name'])?.toString().trim();
    final cleanAffiliation = (rawAffiliation != null && rawAffiliation.isNotEmpty)
        ? rawAffiliation
        : 'Affiliated Institution';

    final rawMotto = (map['motto'] ?? map['tagline'] ?? map['description'])?.toString().trim();
    final cleanMotto = (rawMotto != null && rawMotto.isNotEmpty)
        ? rawMotto
        : 'Excellence in Education & Character';

    final rawAddress = (map['address'] ?? map['location'] ?? map['city'])?.toString().trim() ?? '';
    final rawPhone = (map['phone'] ?? map['contact_number'] ?? map['mobile'])?.toString().trim() ?? '';
    final rawEmail = (map['email'] ?? map['contact_email'])?.toString().trim() ?? '';

    return SchoolBrandModel(
      schoolName: cleanName,
      logoUrl: cleanLogo,
      primaryColor: const Color(0xFF10182D),
      secondaryColor: const Color(0xFF4F46E5),
      affiliation: cleanAffiliation,
      motto: cleanMotto,
      address: rawAddress,
      phone: rawPhone,
      email: rawEmail,
    );
  }

  /// Neutral initial state (never defaults to Xavier Academy or KPS)
  factory SchoolBrandModel.defaultNeutral({String schoolName = 'School Portal'}) {
    return SchoolBrandModel(
      schoolName: schoolName,
      logoUrl: '',
      primaryColor: const Color(0xFF10182D),
      secondaryColor: const Color(0xFF4F46E5),
      affiliation: 'Authorized School Portal',
      motto: 'Excellence in Education',
      address: '',
      phone: '',
      email: '',
    );
  }
}
