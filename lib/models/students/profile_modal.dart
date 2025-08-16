class StudentModel {
  final String profileImageUrl;
  final String coverImageUrl;
  final String fullName;
  final String email;
  final String phone;
  final String studentClass;
  final String city;
  final String dob;
  final String gender;
  final String skills;
  final String about;
  final List<String> coachingCodes;

  StudentModel({
    required this.profileImageUrl,
    required this.coverImageUrl,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.studentClass,
    required this.city,
    required this.dob,
    required this.gender,
    required this.skills,
    required this.about,
    required this.coachingCodes,
  });

  // copyWith method
  StudentModel copyWith({
    String? profileImageUrl,
    String? coverImageUrl,
    String? fullName,
    String? email,
    String? phone,
    String? studentClass,
    String? city,
    String? dob,
    String? gender,
    String? skills,
    String? about,
    List<String>? coachingCodes,
  }) {
    return StudentModel(
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      studentClass: studentClass ?? this.studentClass,
      city: city ?? this.city,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      skills: skills ?? this.skills,
      about: about ?? this.about,
      coachingCodes: coachingCodes ?? this.coachingCodes,
    );
  }

  // Convert to Map (Firestore use)
  Map<String, dynamic> toMap() {
    return {
      'profileImageUrl': profileImageUrl,
      'coverImageUrl': coverImageUrl,
      'fullName': fullName,
      'phone': phone,
      'class': studentClass,
      'city': city,
      'dob': dob,
      'gender': gender,
      'skills': skills,
      'about': about,
      'coachingCodes': coachingCodes
    };
  }

  // From Map (Firestore use)
  factory StudentModel.fromMap(Map<String, dynamic> map) {
    String _suggesInfo = 'Add info';
    return StudentModel(
      profileImageUrl: map['profileImageUrl'] ?? '',
      coverImageUrl: map['coverImageUrl'] ??
          'https://mohdbinsufiyan.vercel.app/assets/media/mypic.jpg',
      fullName: map['fullName'] ?? _suggesInfo,
      email: map['email'] ?? '',
      phone: map['phone'] ?? _suggesInfo,
      studentClass: map['class'] ?? _suggesInfo,
      city: map['city'] ?? _suggesInfo,
      dob: map['dob'] ?? _suggesInfo,
      gender: map['gender'] ?? _suggesInfo,
      skills: map['skills'] ?? _suggesInfo,
      about: map['about'] ?? _suggesInfo,
      coachingCodes: map['coachingCodes'] != null
          ? List<String>.from(map['coachingCodes'])
          : [],
    );
  }
}
