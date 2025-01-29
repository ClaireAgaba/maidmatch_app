class MaidApplicationModel {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String location;
  final NextOfKin nextOfKin;
  final List<String> skills;
  final Map<String, String> documentUrls;
  final String? profilePhotoUrl;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime submittedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? reviewComment;
  final Map<String, dynamic>? medicalInfo;

  MaidApplicationModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.location,
    required this.nextOfKin,
    required this.skills,
    required this.documentUrls,
    this.profilePhotoUrl,
    required this.status,
    required this.submittedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewComment,
    this.medicalInfo,
  });

  factory MaidApplicationModel.fromMap(Map<String, dynamic> map, String id) {
    return MaidApplicationModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      location: map['location'] ?? '',
      nextOfKin: NextOfKin.fromMap(map['nextOfKin'] ?? {}),
      skills: List<String>.from(map['skills'] ?? []),
      documentUrls: Map<String, String>.from(map['documentUrls'] ?? {}),
      profilePhotoUrl: map['profilePhotoUrl'],
      status: map['status'] ?? 'pending',
      submittedAt: (map['submittedAt'] as DateTime?) ?? DateTime.now(),
      reviewedBy: map['reviewedBy'],
      reviewedAt: map['reviewedAt'] as DateTime?,
      reviewComment: map['reviewComment'],
      medicalInfo: map['medicalInfo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'phone': phone,
      'location': location,
      'nextOfKin': nextOfKin.toMap(),
      'skills': skills,
      'documentUrls': documentUrls,
      'profilePhotoUrl': profilePhotoUrl,
      'status': status,
      'submittedAt': submittedAt,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt,
      'reviewComment': reviewComment,
      'medicalInfo': medicalInfo,
    };
  }
}

class NextOfKin {
  final String name;
  final String phone;
  final String relationship;

  NextOfKin({
    required this.name,
    required this.phone,
    required this.relationship,
  });

  factory NextOfKin.fromMap(Map<String, dynamic> map) {
    return NextOfKin(
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      relationship: map['relationship'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'relationship': relationship,
    };
  }
}
