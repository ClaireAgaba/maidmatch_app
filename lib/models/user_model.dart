class UserModel {
  final String id;
  final String type; // 'admin', 'maid', 'homeowner'
  final String phone;
  final String name;
  final String? email;
  final String? profilePhotoUrl;
  final String status; // 'active', 'pending', 'suspended'
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  UserModel({
    required this.id,
    required this.type,
    required this.phone,
    required this.name,
    this.email,
    this.profilePhotoUrl,
    required this.status,
    required this.createdAt,
    this.metadata,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      type: map['type'] ?? '',
      phone: map['phone'] ?? '',
      name: map['name'] ?? '',
      email: map['email'],
      profilePhotoUrl: map['profilePhotoUrl'],
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as DateTime?) ?? DateTime.now(),
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'phone': phone,
      'name': name,
      'email': email,
      'profilePhotoUrl': profilePhotoUrl,
      'status': status,
      'createdAt': createdAt,
      'metadata': metadata,
    };
  }
}
