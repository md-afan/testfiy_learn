import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'providers/teachers/students_provider.dart';
import 'providers/tests_provider.dart';
import 'providers/alll_activity_provider.dart';
import 'providers/comman providers/theme_provider.dart';
import 'providers/test_list_provider.dart';
//student providers
import 'providers/students/profile_provider.dart';
import 'providers/students/rank_proivder.dart';
import "providers/students/studnet_dashboard_provider.dart";
import 'providers/students/studnets_tests_list_provider.dart';
import 'providers/comman providers/enrolled_stundets_provider.dart';

// teacher providers
import 'providers/teachers/teacher_profile_provider.dart';
import 'providers/teachers/students_provider.dart';
import 'providers/teachers/teacher_dashboard_proivder.dart';

// comman providers
import 'providers/comman providers/wallets_provider.dart';
import 'providers/comman providers/notification_provider.dart';
import 'providers/comman providers/tests_provider.dart';
import 'providers/comman providers/text_detials_provder.dart';
import 'providers/comman providers/cashfree_payment_provider.dart';
import 'providers/comman providers/cashfree_payout_provider.dart';

import './routes/app_router.dart';
import './theme/app_theme.dart';
import './services/screen_size_service.dart';
import './services/firebase_notification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAExUowQ4GSSCdMwzMnuhN-Axv6ezFtEfg",
        authDomain: "testify-learn-d58e0.firebaseapp.com",
        projectId: "testify-learn-d58e0",
        storageBucket: "testify-learn-d58e0.firebasestorage.app",
        messagingSenderId: "868279158213",
        appId: "1:868279158213:web:c133cc449778bea368f7ac",
        measurementId: "G-YJBZNG4Z3S",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }


  await FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaV3Provider('YOUR_RECAPTCHA_KEY'), // For web
    androidProvider: AndroidProvider
        .debug, // Or AndroidProvider.playIntegrity for production
    appleProvider:
        AppleProvider.debug, // Or AppleProvider.deviceCheck for production
  );

  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true, // ✅ Enables offline cache
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (e) {
    print('❌ Firestore cache error: $e');
  }

  await FirebaseNotification.init();

  runApp(
    MultiProvider(
      providers: [
        //comman providers
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => TestScreenProvider()),
        ChangeNotifierProvider(create: (_) => TestDetailsProvider()),
        ChangeNotifierProvider(create: (_) => CashfreePaymentProvider()),
        ChangeNotifierProvider(create: (_) => CashfreeWithdrawalProvider()),

        // teacher providers
        ChangeNotifierProvider(create: (_) => TestListProvider()),
        ChangeNotifierProvider(create: (_) => TeacherProfileProvider()),
        ChangeNotifierProvider(create: (_) => StudentsProvider()),
        ChangeNotifierProvider(create: (_) => TeacherDashboardProvider()),

        // students provider
        ChangeNotifierProvider(create: (_) => StudentProfileProvider()),
        ChangeNotifierProvider(create: (_) => LeaderboardProvider()),
        ChangeNotifierProvider(create: (_) => AllActivityProvider()),
        ChangeNotifierProvider(create: (_) => TestsProvider()),
        ChangeNotifierProvider(create: (_) => StudentDashboardProvider()),
        ChangeNotifierProvider(create: (_) => StudentTestListProvider()),
        ChangeNotifierProvider(create: (_) => EnrolledStudentsProvider()),
      ],
      child: LayoutBuilder(
        builder: (context, _) {
          ScreenSizeService().init(context);
          return const MyAppWrapper();
        },
      ),
    ),
  );
}

class MyAppWrapper extends StatelessWidget {
  const MyAppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GoRouter>(
      future: AppRouter.createRouter(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        return MyApp(router: snapshot.data!);
      },
    );
  }
}

class MyApp extends StatelessWidget {
  final GoRouter router;
  const MyApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context); // ✅ added

    return MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode, // ✅ dynamic theme
      debugShowCheckedModeBanner: false,
    );
  }
}
