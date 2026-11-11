import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'generated/l10n.dart';
import 'routes.dart';
import 'sign_in.dart';
import 'firebase_options.dart';

// import 'uploadobjects.dart';

/// Initialize Firebase and localization before launching the app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Debug builds use debug providers; release builds use platform attestation.
    if (!kIsWeb) {
      await FirebaseAppCheck.instance.activate(
        providerApple: kDebugMode
            ? const AppleDebugProvider()
            : const AppleAppAttestWithDeviceCheckFallbackProvider(),
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
      );
    }
    await S.load(Locale.fromSubtags(languageCode: 'en'));
  } catch (e) {
    debugPrint('Initialization error: $e');
  }
  runApp(const MyApp());
}

/// Configure the app's dark theme, routes and localization.
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
          : [FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: S.delegate.supportedLocales,
    );
  }
}

/// Provide a sign-in entry point for the app.
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
