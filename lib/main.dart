import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:whatsapp_flutter/views/contactprofile_view.dart';
import 'firebase_options.dart';
import 'bindings/app_bindings.dart';
import 'views/login_view.dart';
import 'views/signup_view.dart';
import 'views/home_view.dart';
import 'views/chat_view.dart';
import 'views/contacts_view.dart';
import 'views/profile_view.dart';
import 'views/splash_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    // For Android, use debug provider in development
    androidProvider: AndroidProvider.debug,
    // For iOS, use device check provider
    appleProvider: AppleProvider.deviceCheck,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'Chat App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.teal,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            fontFamily: 'Roboto',
          ),
          initialBinding: AppBindings(),
          initialRoute: '/splash',
          getPages: [
            GetPage(name: '/splash', page: () => const SplashView()),
            GetPage(name: '/login', page: () => LoginView()),
            GetPage(name: '/signup', page: () => const SignupView()),
            GetPage(name: '/home', page: () => const HomeView()),
            GetPage(name: '/chat', page: () => const ChatView()),
            GetPage(name: '/contacts', page: () => ContactsView()),
            GetPage(name: '/profile', page: () => const ProfileView()),
            GetPage(
              name: '/contact_profile',
              page: () => const ContactProfileView(),
            ),
          ],
        );
      },
    );
  }
}
