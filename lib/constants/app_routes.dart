class AppRoutes {
  // intial routes
  static const splash = '/splash';

  // authentication routes
  static const login = '/login';
  static const role = '/role';
  static const studentSingup = '/student-signup';
  static const organizationSignup = '/organization-signup';
  static const emailVerification = '/verify-email';
  static const approval = '/approval';
  static const resetPassword = '/reset-password';
  static const teacherSignup = '/teacher-signup';

  // comman routes
  static const notifications = '/settings';

  // Studnets routes name
  static const joinInCoaching = '/join-coaching';
  static const studentDashboard = '/student-dashboard';
  static const String coachingCode = '/coaching-code';
  static const String studentProfile = '/student-profile';
  static const String studentWallet = '/student-wallet';
  static const String studentTest = '/student-test';
  static const String studentLeaderboard = '/student-leaderboard';
  static const String editStudentInfo = '/student-edit-info';
  static const String studentnotifications = '/student/notifications';
  static const String testDetailsForStudent = '/student/tests';
  static const String enrolledStudents = '/student/enrolled-student';
  static const String testDetaistTostudents = '/students/test-detials';

  // dynamic routes
  static const String testLeaderborad = '/student/test-leaderboard';
  static const String testDetails = '/test-details';
  static const String studentDetails = '/teacher/student-details';
  static const String takeTest = '/test-taken';

  // teacher routes name
  static const teacherDashboard = '/teacher-dashboard';
  static const teacherShowStudent = '/teacher-show-student';
  static const teacherProfile = '/teacher-profile';
  static const teacherWallet = '/teacher-wallet';
  static const createNewTests = '/create-new-tests';
  static const editTeacherinfo = '/edit-teacher-info';
  static const studentsAttandance = '/teacher/students-attendance';
  static const teachertests = '/teacher/tests';
  static const editTest = '/teacher/edit-test';
  static const teachertestLeaderborad = '/teacher/test-leaderboard';
  static const teacherNotifications = '/teacher-notifications';
  static const teachersApproval = '/teacher-approval';

  //common routes
  static const organization = '/organization';
  static const String settings = '/settings';
  static const String reviewQuestion = '/review-question';
  static const String changePassword = '/change-password';
  static const String addMoney = '/add-money';
  static const String widthrawal = '/widthraw-money';
}
