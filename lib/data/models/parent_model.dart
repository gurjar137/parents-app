class ParentModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String avatarUrl;
  final String relationship; // "Father", "Mother", "Guardian"
  final String status;
  final String? schoolId;
  final List<String> childrenIds;

  const ParentModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    this.relationship = 'Parent / Guardian',
    this.status = 'active',
    this.schoolId,
    required this.childrenIds,
  });

  ParentModel copyWith({
    String? name,
    String? phone,
    String? avatarUrl,
    String? relationship,
  }) {
    return ParentModel(
      id: id,
      name: name ?? this.name,
      email: email, // Email changes must use official Supabase Auth flow
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      relationship: relationship ?? this.relationship,
      status: status,
      schoolId: schoolId,
      childrenIds: childrenIds,
    );
  }

  factory ParentModel.fromMap(Map<String, dynamic> map, String fallbackId) {
    return ParentModel(
      id: map['id'] ?? map['auth_user_id'] ?? fallbackId,
      name: map['full_name'] ?? map['parent_name'] ?? map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? map['mobile_number'] ?? '',
      avatarUrl: map['avatar_url'] ?? '',
      relationship: map['relationship'] ?? 'Parent / Guardian',
      status: map['status'] ?? 'active',
      schoolId: map['school_id'],
      childrenIds: List<String>.from(map['children_ids'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'auth_user_id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl,
      'relationship': relationship,
      'status': status,
      'school_id': schoolId,
      'children_ids': childrenIds,
      'created_at': DateTime.now().toIso8601String(),
    };
  }
}
