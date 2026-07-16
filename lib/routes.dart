import 'package:flutter/material.dart';

import 'add_observation.dart';
import 'sign_in.dart';
import 'signed_in.dart';

class MyRoutes {
// const String HomePageRoute = '/';
  static const String signInPageRoute = '/';
  // static const String signedInPageRoute = '/signed-in';
  static const String galleryPageRoute = '/gallery';
  static const String addObservationPageRoute = '/add-observation';
  static const String homePage = '/main';
  // static const String observationGallery = '/ObservationsGallary';
  // static const String settingsPage = '/SettingsPage';

  static final Map<String, Widget Function(BuildContext)> routeMap = {
    // HomePageRoute: (BuildContext context) => MyHomePage(
    //       title: 'Astronomy Log Book',
    //     ),
    signInPageRoute: (BuildContext context) => const SignInPage(),
    // signedInPageRoute: (BuildContext context) => const SignedInPage(),
    // GalleryPageRoute: (BuildContext context) => GallaryPage(),
    addObservationPageRoute: (BuildContext context) =>
        const AddObservationPage(),
    homePage: (BuildContext context) => const HomePage(),
  };
}
