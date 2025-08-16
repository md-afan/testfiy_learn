class RoleConstants {
  static const student = 'student';
  static const teacher = 'teacher';
  static const teacherAdmin = 'teacher_admin';

  static bool isTeacher(String? role) =>
      role == teacher || role == teacherAdmin;
  static bool isStudent(String? role) => role == student;
  static bool isAdmin(String? role) => role == teacherAdmin;
}
