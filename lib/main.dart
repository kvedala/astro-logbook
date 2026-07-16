import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'generated/l10n.dart';
import 'routes.dart';
import 'sign_in.dart';
import 'firebase_options.dart';
// import 'uploadobjects.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kIsWeb) {
      try {
        FacebookAuth.i.webAndDesktopInitialize(
          appId: "437381314078679",
          cookie: true,
          xfbml: true,
          version: "v12.0",
        );
      } catch (e) {
        debugPrint('Facebook init error: $e');
      }
    }
    await S.load(Locale.fromSubtags(languageCode: 'en'));
  } catch (e) {
    debugPrint('Initialization error: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'astro_log',
      darkTheme: ThemeData.from(
        colorScheme: ColorScheme.dark(
          primary: Colors.red[900]!,
          secondary: Colors.red[500]!,
          tertiary: Colors.red[200]!,
          onSurface: Colors.red,
        ),
        textTheme: TextTheme(
          displayLarge: TextStyle(color: Colors.red[900]),
          displayMedium: TextStyle(color: Colors.red[900]),
          displaySmall: TextStyle(color: Colors.red[900]),
          headlineLarge: TextStyle(color: Colors.red[900]),
          headlineMedium: TextStyle(color: Colors.red[900]),
          headlineSmall: TextStyle(color: Colors.red[900]),
          titleLarge: TextStyle(color: Colors.red[900]),
          titleMedium: TextStyle(color: Colors.red[900]),
          titleSmall: TextStyle(color: Colors.red[900]),
          bodyLarge: TextStyle(color: Colors.red[900]),
          bodyMedium: TextStyle(color: Colors.red[900]),
          bodySmall: TextStyle(color: Colors.red[900]),
          labelLarge: TextStyle(color: Colors.red[900]),
          labelMedium: TextStyle(color: Colors.red[900]),
          labelSmall: TextStyle(color: Colors.red[900]),
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.dark,
      routes: MyRoutes.routeMap,
      navigatorObservers: kIsWeb
          ? []
          : [
              FirebaseAnalyticsObserver(
                analytics: FirebaseAnalytics.instance,
              ),
            ],
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
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
