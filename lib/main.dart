import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'routes.dart';
import 'sign_in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
        textTheme: Theme.of(context).textTheme.apply(
            bodyColor: Colors.red,
            displayColor: Colors.red,
            decorationColor: Colors.red),
        primaryIconTheme: IconThemeData(color: Colors.red),
        // accentIconTheme: IconThemeData(color: Colors.red),
        // floatingActionButtonTheme: FloatingActionButtonThemeData(),
        brightness: Brightness.dark,
        // buttonColor: ButtonThemeData(textTheme: ButtonTextTheme.accent),
        iconTheme: IconThemeData(color: Colors.red),
        inputDecorationTheme:
            InputDecorationTheme(labelStyle: TextStyle(color: Colors.red)),
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
              .bodyText2,
          titleTextStyle: Theme.of(context)
              .textTheme
              .apply(
                  bodyColor: Colors.red,
                  displayColor: Colors.red,
                  decorationColor: Colors.red)
              .headline6,
        ),
        tabBarTheme: TabBarTheme(
          labelColor: Colors.red,
          indicator:
              UnderlineTabIndicator(borderSide: BorderSide(color: Colors.red)),
        ),
      ),
      themeMode: ThemeMode.dark,
      // home: MyHomePage(title: 'Astronomy Log Book'),
      initialRoute: SignInPageRoute,
      routes: routeMap,
    );
  }
}

class MyHomePage extends StatelessWidget {
  final String? title;

  MyHomePage({Key? key, this.title}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    // FirebaseAuth.instance.currentUser == null
    //     ? Navigator.pushNamed(context, SignInPageRoute)
    //     : Navigator.pushNamed(context, SignedInPageRoute);
    return SignInPage();
  }
}
