class TeacherModel {
  final String fullName;
  final String email;
  final String phone;
  final String dob;
  final String gender;
  final String about;
  final String skills;
  final String teacherImageUrl;
  final String coachingImageUrl;
  final String coachingName;
  final String coachingCode;
  final String coachingAddress;

  TeacherModel({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.dob,
    required this.gender,
    required this.about,
    required this.skills,
    required this.teacherImageUrl,
    required this.coachingImageUrl,
    required this.coachingName,
    required this.coachingCode,
    required this.coachingAddress,
  });

  factory TeacherModel.fromMap(Map<String, dynamic> map) {
    String suggInfo = 'Add in';
    return TeacherModel(
      fullName: map['fullName'],
      email: map['email'],
      phone: map['phone'],
      dob: map['dob'] ?? suggInfo,
      gender: map['gender'] ?? suggInfo,
      about: map['about'] ?? suggInfo,
      skills: map['skills'] ?? suggInfo,
      teacherImageUrl: map['teacherImageUrl'] ?? suggInfo,
      coachingImageUrl: map['coachingImageUrl'] ?? suggInfo,
      coachingName: map['coachingName'] ?? suggInfo,
      coachingCode: map['coachingCode'] ?? suggInfo,
      coachingAddress: map['coachingAddress'] ?? suggInfo,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'dob': dob,
      'gender': gender,
      'about': about,
      'skills': skills,
      'teacherImageUrl': teacherImageUrl,
      'coachingImageUrl': coachingImageUrl,
      'coachingName': coachingName,
      'coachingCode': coachingCode,
      'coachingAddress': coachingAddress,
    };
  }

  TeacherModel copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? dob,
    String? gender,
    String? about,
    String? skills,
    String? teacherImageUrl,
    String? coachingImageUrl,
    String? coachingName,
    String? coachingCode,
    String? coachingAddress,
  }) {
    return TeacherModel(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      about: about ?? this.about,
      skills: skills ?? this.skills,
      teacherImageUrl: teacherImageUrl ?? this.teacherImageUrl,
      coachingImageUrl: coachingImageUrl ?? this.coachingImageUrl,
      coachingName: coachingName ?? this.coachingName,
      coachingCode: coachingCode ?? this.coachingCode,
      coachingAddress: coachingAddress ?? this.coachingAddress,
    );
  }
}
