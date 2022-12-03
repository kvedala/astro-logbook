import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import 'routes.dart';
import 'sign_in.dart';
import 'firebase_options.dart';
// import 'uploadobjects.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // await uploadMessier();
  // await uploadNGC();

  // check if is running on Web
  if (kIsWeb) {
    // initialiaze the facebook javascript SDK
    FacebookAuth.i.webAndDesktopInitialize(
      appId: "437381314078679",
      cookie: true,
      xfbml: true,
      version: "v12.0",
    );
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // debugShowCheckedModeBanner: false,
      title: 'Astronomy Log Book',
      // theme: ThemeData(
      //   primarySwatch: Colors.blue,
      // ),
      darkTheme: ThemeData(
        useMaterial3: true,
        textTheme: Theme.of(context).textTheme.apply(
            bodyColor: Colors.red,
            displayColor: Colors.red,
            decorationColor: Colors.red),
        primaryIconTheme: const IconThemeData(color: Colors.red),
        // accentIconTheme: IconThemeData(color: Colors.red),
        // floatingActionButtonTheme: FloatingActionButtonThemeData(),
        brightness: Brightness.dark,
        // buttonColor: ButtonThemeData(textTheme: ButtonTextTheme.accent),
        iconTheme: const IconThemeData(color: Colors.red),
        inputDecorationTheme: const InputDecorationTheme(
            labelStyle: TextStyle(color: Colors.red)),
        unselectedWidgetColor: Colors.red,

        colorScheme: ColorScheme.dark(
          primary: Colors.red.shade800,
          secondary: Colors.red.shade600,
        ),
        appBarTheme: AppBarTheme(
          toolbarTextStyle: Theme.of(context)
              .textTheme
              .apply(
                  bodyColor: Colors.red,
                  displayColor: Colors.red,
                  decorationColor: Colors.red)
              .bodyMedium,
          titleTextStyle: Theme.of(context)
              .textTheme
              .apply(
                  bodyColor: Colors.red,
                  displayColor: Colors.red,
                  decorationColor: Colors.red)
              .titleLarge,
        ),
        tabBarTheme: const TabBarTheme(
          labelColor: Colors.red,
          indicator:
              UnderlineTabIndicator(borderSide: BorderSide(color: Colors.red)),
        ),
      ),
      themeMode: ThemeMode.dark,
      // home: MyHomePage(title: 'Astronomy Log Book'),
      initialRoute: MyRoutes.signInPageRoute,
      routes: MyRoutes.routeMap,
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
    );
  }
}

class MyHomePage extends StatelessWidget {
  final String? title;

  const MyHomePage({super.key, this.title});
  @override
  Widget build(BuildContext context) {
    // FirebaseAuth.instance.currentUser == null
    //     ? Navigator.pushNamed(context, SignInPageRoute)
    //     : Navigator.pushNamed(context, SignedInPageRoute);
    return const SignInPage();
  }
}
