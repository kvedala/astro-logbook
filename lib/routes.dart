import 'package:flutter/material.dart';

import 'add_observation.dart';
import 'signed_in.dart';
import 'sign_in.dart';

class MyRoutes {
// const String HomePageRoute = '/';
  static const String signInPageRoute = '/';
  static const String signedInPageRoute = '/signed-in';
  static const String galleryPageRoute = '/gallery';
  static const String addObservationPageRoute = '/add-observation';

  static final Map<String, Widget Function(BuildContext)> routeMap = {
    // HomePageRoute: (BuildContext context) => MyHomePage(
    //       title: 'Astronomy Log Book',
    //     ),
    signInPageRoute: (BuildContext context) => const SignInPage(),
    signedInPageRoute: (BuildContext context) => const SignedInPage(),
    // GalleryPageRoute: (BuildContext context) => GallaryPage(),
    addObservationPageRoute: (BuildContext context) =>
        const AddObservationPage(),
  };
}
