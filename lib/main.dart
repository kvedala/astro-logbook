import 'package:astro_log/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'sign_in.dart';
import 'signed_in.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Create the initialization Future outside of `build`:
    final Future<FirebaseApp> _initialization = Firebase.initializeApp();

    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) throw "Initialization error: ${snapshot.error}";
        if (snapshot.connectionState == ConnectionState.waiting)
          return CircularProgressIndicator();
        return MaterialApp(
          title: 'Astronomy Log Book',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          // home: MyHomePage(title: 'Astronomy Log Book'),
          initialRoute: HomePageRoute,
          routes: routeMap,
        );
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  final String title;

  MyHomePage({Key key, this.title}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return FirebaseAuth.instance.currentUser == null
        ? SignInPage()
        : SignedInPage();
  }
}
