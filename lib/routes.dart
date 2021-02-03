import 'package:astro_log/add_observation.dart';
import 'package:astro_log/main.dart';
import 'package:flutter/material.dart';

import 'gallery_page.dart';
import 'sign_in.dart';

const String HomePageRoute = '/';
const String SignInPageRoute = '/';
const String GalleryPageRoute = '/gallery';
const String AddObservationPageRoute = '/add-observation';

final Map<String, Widget Function(BuildContext)> routeMap = {
  HomePageRoute: (BuildContext context) => MyHomePage(
        title: 'Astronomy Log Book',
      ),
  // SignInPageRoute: (BuildContext context) => SignInPage(),
  GalleryPageRoute: (BuildContext context) => GallaryPage(),
  AddObservationPageRoute: (BuildContext context) => AddObservationPage(),
};
