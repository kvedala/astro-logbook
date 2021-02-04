import 'package:astro_log/add_observation.dart';
import 'package:astro_log/main.dart';
import 'package:astro_log/signed_in.dart';
import 'package:flutter/material.dart';

import 'sign_in.dart';

// const String HomePageRoute = '/';
const String SignInPageRoute = '/';
const String SignedInPageRoute = '/signed-in';
const String GalleryPageRoute = '/gallery';
const String AddObservationPageRoute = '/add-observation';

final Map<String, Widget Function(BuildContext)> routeMap = {
  // HomePageRoute: (BuildContext context) => MyHomePage(
  //       title: 'Astronomy Log Book',
  //     ),
  SignInPageRoute: (BuildContext context) => SignInPage(),
  SignedInPageRoute: (BuildContext context) => SignedInPage(),
  // GalleryPageRoute: (BuildContext context) => GallaryPage(),
  AddObservationPageRoute: (BuildContext context) => AddObservationPage(),
};
