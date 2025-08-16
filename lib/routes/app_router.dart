import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firebase_service.dart';
import '../constants/app_routes.dart';
import '../utils/secure_locally_storage.dart';

// Screens
import '../screens/comman/organization_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/role_screen.dart';
import '../screens/auth/student/student_signup_screen.dart';
import '../screens/auth/teacher/organization_signup_screen.dart';
import '../screens/auth/teacher/teacher_signup_screen.dart';
import '../screens/auth/email_verification_screen.dart';
import '../screens/auth/teacher/approval_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/students/student_dashboard.dart';
import '../screens/auth/coaching_code_screen.dart';
import '../screens/comman/notifications_screen.dart';
import '../screens/teachers/test_detials_screen.dart';
import '../screens/comman/test_leaderboard.dart';
import '../screens/comman/studnets_detiails_screen.dart';
import '../screens/students/student_main_scaffold.dart';
import '../screens/students/tests_screen.dart';
import '../screens/comman/wallet_screen.dart';
import '../screens/students/leaderboard_screen.dart';
import '../screens/students/student_profile.dart';
import '../screens/students/quiz_attend_screen.dart';
import '../screens/teachers/teacher_main_scaffold.dart';
import '../screens/teachers/teacher_dashboard.dart';
import '../screens/teachers/students_screen.dart';
import '../screens/teachers/create_test_screen.dart';
import '../screens/teachers/profile_screen.dart';
import '../screens/teachers/edit_profile_screen.dart';
import '../screens/teachers/students_attandance_screen.dart';
import '../screens/students/widgets/edit_profile_screen.dart';
import '../screens/teachers/test_screen.dart';
import '../screens/teachers/edit_test_screen.dart';
import '../services/screen_size_service.dart';
import '../screens/students/widgets/test_details_screen.dart';
import '../screens/students/enrolled_studnet_list.dart';
import '../screens/students/test_details_screen.dart';
import '../screens/comman/question_review_screen.dart';
import '../screens/comman/setting_screen.dart';
import '../screens/teachers/teachers_approval.dart';
import '../screens/comman/change_password.dart';
import '../screens/comman/payment_screen.dart';
import '../screens/comman/payout_screen.dart';

final bool isMobile = ScreenSizeService().isMobile;

class AppRouter {
  static final _publicRoutes = [
    AppRoutes.splash,
    AppRoutes.login,
    AppRoutes.role,
    AppRoutes.studentSingup,
    AppRoutes.organizationSignup,
    AppRoutes.resetPassword,
    AppRoutes.emailVerification,
    AppRoutes.teacherSignup
  ];

  static Future<GoRouter> createRouter() async {
    return GoRouter(
      initialLocation: AppRoutes.splash,
      redirect: (context, state) async {
        final uid = await LocalStorage.getLocalStorage('uid') ?? '';
        final role = await getUserRole(uid);
        final isLoggedIn = uid.isNotEmpty;
        final isPublicRoute = _publicRoutes.contains(state.uri.path);
        final coachingCode = await LocalStorage.getLocalStorage("coachingCode");

        final user = FirebaseAuth.instance.currentUser;

        // Redirect unverified users to email verification screen
        if (user != null &&
            !user.emailVerified &&
            state.uri.path != AppRoutes.emailVerification &&
            !_publicRoutes.contains(state.uri.path)) {
          return AppRoutes.emailVerification;
        }

        // Redirect unapproved teachers to approval screen
        if (role == "teacher_admin" &&
            isLoggedIn &&
            state.uri.path != AppRoutes.approval &&
            !_publicRoutes.contains(state.uri.path)) {
          final doc = await FirebaseFirestore.instance
              .collection('teachers')
              .doc(uid)
              .get();

          final isApproved = doc.data()?['isApproved'] ?? false;
          if (!isApproved) return AppRoutes.approval;
        }

        // Allow public routes
        if (isPublicRoute) return null;

        // Redirect unauthenticated users
        if (!isLoggedIn) return AppRoutes.login;

        // Root path redirection based on role
        if (state.uri.path == '/' || state.uri.path == AppRoutes.splash) {
          if ((role == 'student' || role == "teacher"))
            return AppRoutes.joinInCoaching;
          if (role == 'teacher_admin') return AppRoutes.teacherDashboard;
          return AppRoutes.login;
        }

        // ✅ Restrict student-only routes
        if (state.uri.path.startsWith('/student') && role != 'student') {
          return role == 'teacher_admin'
              ? AppRoutes.teacherDashboard
              : AppRoutes.login;
        }

        // ✅ Restrict teacher-only routes
        if (state.uri.path.startsWith('/teacher') &&
            !(role == 'teacher' || role == 'teacher_admin')) {
          return role == 'student' ? AppRoutes.joinInCoaching : AppRoutes.login;
        }

        return null;
      },
      routes: [
        GoRoute(
            path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
        GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
        GoRoute(
            path: AppRoutes.role,
            builder: (_, __) => const RoleSelectionScreen()),
        GoRoute(
            path: AppRoutes.studentSingup,
            builder: (_, __) => const StudentSignup()),
        GoRoute(
            path: AppRoutes.organizationSignup,
            builder: (_, __) => const OrganizationSignupScreen()),
        GoRoute(
            path: AppRoutes.teacherSignup,
            builder: (_, __) => const TeacherSignup()),
        GoRoute(
            path: AppRoutes.resetPassword,
            builder: (_, __) => const ResetPasswordScreen()),
        GoRoute(
            path: AppRoutes.emailVerification,
            builder: (_, __) => const EmailVerificationScreen()),
        GoRoute(
            path: AppRoutes.approval, builder: (_, __) => const ApprovalPage()),

        GoRoute(
          path: AppRoutes.joinInCoaching,
          builder: (context, state) {
            final isTeacher = state.uri.queryParameters['isTeacher'] == 'true';
            return CoachingCodeScreen(isTeacher: isTeacher);
          },
        ),

        // Student Shell
        ShellRoute(
          builder: (context, state, child) => StudentMainScaffold(child: child),
          routes: [
            GoRoute(
                path: AppRoutes.studentDashboard,
                builder: (_, __) => const StudentDashboard()),
            GoRoute(
                path: AppRoutes.studentTest,
                builder: (_, __) => const TestScreen()),
            GoRoute(
              path: AppRoutes.studentLeaderboard,
              builder: (context, state) => const LeaderboardScreen(),
            ),
            GoRoute(
                path: AppRoutes.studentProfile,
                builder: (_, __) => const StudentProfileScreen()),
            GoRoute(
                path: AppRoutes.studentWallet,
                builder: (_, __) => const WalletScreen()),
            if (!isMobile)
              GoRoute(
                path: AppRoutes.studentnotifications,
                builder: (context, state) {
                  final role = "students";
                  return NotificationScreen(role: role);
                },
              ),
            if (!isMobile)
              GoRoute(
                path: '${AppRoutes.editStudentInfo}/:id',
                builder: (context, state) => EditStudentProfileScreen(
                  uid: state.pathParameters['id']!,
                ),
              ),
            if (!isMobile)
              GoRoute(
                path: '${AppRoutes.testLeaderborad}/:id',
                builder: (context, state) {
                  final testId = state.pathParameters['id']!;
                  final extra = state.extra as Map<String, dynamic>?;

                  return TestLeaderboardScreen(
                    testId: testId,
                    testData: extra ?? {},
                  );
                },
              ),
            if (!isMobile)
              GoRoute(
                path: '${AppRoutes.testDetailsForStudent}/:id',
                builder: (context, state) => StudentTestDetailsScreen(
                    testId: state.pathParameters['id']!),
              ),
            if (!isMobile)
              GoRoute(
                path: '${AppRoutes.enrolledStudents}/:id',
                builder: (context, state) =>
                    EnrolledStudentsScreen(testId: state.pathParameters['id']!),
              ),
            if (!isMobile)
              GoRoute(
                path: '${AppRoutes.testDetaistTostudents}/:id/:uid',
                builder: (context, state) => TestDetailsScreenToStudents(
                  testId: state.pathParameters['id']!,
                  uid: state.pathParameters['uid']!,
                ),
              )
          ],
        ),

        if (isMobile)
          GoRoute(
            path: '${AppRoutes.testDetaistTostudents}/:id/:uid',
            builder: (context, state) => TestDetailsScreenToStudents(
              testId: state.pathParameters['id']!,
              uid: state.pathParameters['uid']!,
            ),
          ),

        if (isMobile)
          GoRoute(
            path: AppRoutes.studentnotifications,
            builder: (context, state) {
              final role = "students";
              return NotificationScreen(role: role);
            },
          ),

        if (isMobile)
          GoRoute(
            path: '${AppRoutes.editStudentInfo}/:id',
            builder: (context, state) => EditStudentProfileScreen(
              uid: state.pathParameters['id']!,
            ),
          ),

        if (isMobile)
          GoRoute(
            path: '${AppRoutes.testLeaderborad}/:id',
            builder: (context, state) {
              final testId = state.pathParameters['id']!;
              final extra = state.extra as Map<String, dynamic>?;
              return TestLeaderboardScreen(
                testId: testId,
                testData: extra ?? {},
              );
            },
          ),

        if (isMobile)
          GoRoute(
            path: '${AppRoutes.testDetails}/:id',
            builder: (context, state) =>
                TestDetailsScreen(testId: state.pathParameters['id']!),
          ),

        if (isMobile)
          GoRoute(
            path: '${AppRoutes.enrolledStudents}/:id',
            builder: (context, state) =>
                EnrolledStudentsScreen(testId: state.pathParameters['id']!),
          ),

        GoRoute(
          path: '${AppRoutes.takeTest}/:id',
          builder: (context, state) {
            final quizId = state.pathParameters['id']!;
            return QuizAttendScreen(
              quizId: quizId,
            );
          },
        ),

        // Teacher Shell
        ShellRoute(
          builder: (context, state, child) => TeacherMainScaffold(child: child),
          routes: [
            GoRoute(
                path: AppRoutes.teacherDashboard,
                builder: (_, __) => const TeacherDashboard()),
            GoRoute(
                path: AppRoutes.teacherShowStudent,
                builder: (_, __) => const StudentsScreen()),
            GoRoute(
                path: AppRoutes.createNewTests,
                builder: (_, __) => const CreateTestScreen()),
            GoRoute(
                path: AppRoutes.teacherWallet,
                builder: (_, __) => const WalletScreen()),
            GoRoute(
                path: AppRoutes.teachertests,
                builder: (_, __) => const TeacherTestScreen()),
            if (!isMobile)
              GoRoute(
                path: AppRoutes.teacherNotifications,
                builder: (context, state) {
                  final role = "teachers";
                  return NotificationScreen(role: role);
                },
              ),
            if (!isMobile)
              GoRoute(
                  path: AppRoutes.teacherProfile,
                  builder: (_, __) => const TeacherProfileScreen()),
            if (!isMobile)
              GoRoute(
                path: '${AppRoutes.studentsAttandance}/:id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return StudentsAttandanceScreen(quizId: id);
                },
              ),
            if (!isMobile)
              GoRoute(
                path: '${AppRoutes.studentDetails}/:id',
                builder: (context, state) => StudentDetailsScreen(
                    studentId: state.pathParameters['id']!),
              ),
            if (!isMobile)
              GoRoute(
                path: '${AppRoutes.editTeacherinfo}/:id',
                builder: (context, state) {
                  final uid = state.pathParameters['id']!;
                  return EditTeacherInfoScreen(uid: uid);
                },
              ),
            if (!isMobile)
              GoRoute(
                path: '${AppRoutes.testDetails}/:id',
                builder: (context, state) =>
                    TestDetailsScreen(testId: state.pathParameters['id']!),
              ),
            // if (!isMobile)
            //   GoRoute(
            //     path: '${AppRoutes.teachertestLeaderborad}/:id',
            //     builder: (context, state) => TestLeaderboardScreen(),
            //   ),

            if (!isMobile)
              GoRoute(
                path: AppRoutes.teachersApproval,
                builder: (_, __) => const TeacherApprovalScreen(),
              )
          ],
        ),

        if (isMobile)
          GoRoute(
            path: AppRoutes.teacherNotifications,
            builder: (context, state) {
              final role = "teachers";
              return NotificationScreen(role: role);
            },
          ),

        if (isMobile)
          GoRoute(
              path: AppRoutes.teacherProfile,
              builder: (_, __) => const TeacherProfileScreen()),
        if (isMobile)
          GoRoute(
            path: '${AppRoutes.studentsAttandance}/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return StudentsAttandanceScreen(quizId: id);
            },
          ),
        if (isMobile)
          GoRoute(
            path: '${AppRoutes.studentDetails}/:id',
            builder: (context, state) =>
                StudentDetailsScreen(studentId: state.pathParameters['id']!),
          ),
        if (isMobile)
          GoRoute(
            path: '${AppRoutes.editTeacherinfo}/:id',
            builder: (context, state) {
              final uid = state.pathParameters['id']!;
              return EditTeacherInfoScreen(uid: uid);
            },
          ),

        // if (isMobile)
        //   GoRoute(
        //     path: '${AppRoutes.teachertestLeaderborad}/:id',
        //     builder: (context, state) => TestLeaderboardScreen(),
        //   ),

        GoRoute(
            path: '${AppRoutes.editTest}/:id',
            builder: (context, state) => EditTestScreen(
                  quizId: state.pathParameters['id']!,
                )),

        GoRoute(
            path: '${AppRoutes.reviewQuestion}/:testId/:studentId',
            builder: (context, state) => ReviewQuestionsScreen(
                  quizId: state.pathParameters['testId']!,
                  studentId: state.pathParameters['studentId']!,
                  title: state.extra as String? ?? 'Review Questions',
                )),

        GoRoute(
            path: '${AppRoutes.organization}/:id',
            builder: (context, state) => OrganizationScreen(
                  coachingCode: state.pathParameters['id']!,
                )),

        GoRoute(
          path: AppRoutes.settings,
          builder: (_, __) => SettingsPage(),
        ),

        GoRoute(
          path: AppRoutes.changePassword,
          builder: (context, state) => const ChangePasswordScreen(),
        ),

        GoRoute(
          path: AppRoutes.addMoney,
          builder: (context, state) => PaymentScreen(),
        ),

        GoRoute(path: AppRoutes.widthrawal, builder: (_, __) => PayoutScreen()),
      ],
    );
  }
}
