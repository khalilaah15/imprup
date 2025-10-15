class Profile {
  final String id;
  final String role;
  final String fullName;
  final String? photoProfile;
  final String? domicile;

  // Talenta Specific
  final String? birthDate;
  final String? lastEducation;
  final String? mainSkill;
  final String? whatsappNumber;
  final String? shortDescription;
  final String? status;
  final int projectsCompleted;
  final double totalRating;
  final int ratingCount;

  // Company Specific
  final String? photoBanner;
  final String? companyCategory;
  final String? companyDescription;

  Profile({
    required this.id,
    required this.role,
    required this.fullName,
    this.photoProfile,
    this.domicile,
    this.birthDate,
    this.lastEducation,
    this.mainSkill,
    this.whatsappNumber,
    this.shortDescription,
    this.status,
    this.projectsCompleted = 0,
    this.totalRating = 0.0,
    this.ratingCount = 0,
    this.photoBanner,
    this.companyCategory,
    this.companyDescription,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      role: json['role'],
      fullName: json['full_name'],
      photoProfile: json['photo_profile'],
      domicile: json['domicile'],
      birthDate: json['birth_date'],
      lastEducation: json['last_education'],
      mainSkill: json['main_skill'],
      whatsappNumber: json['whatsapp_number'],
      shortDescription: json['short_description'],
      status: json['status'],
      projectsCompleted: json['projects_completed'] ?? 0,
      totalRating: (json['total_rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['rating_count'] ?? 0,
      photoBanner: json['photo_banner'],
      companyCategory: json['company_category'],
      companyDescription: json['company_description'],
    );
  }
}