import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'checklist.dart';
import 'equipment.dart';
import 'equipment_gallery.dart';
import 'list_of_objects.dart';
import 'observations_gallery_page.dart';
import 'routes.dart';
import 'settings_page.dart';
import 'weather_page.dart';

/// Container to define tab properties
///
/// * [icon] widget to display for the tab
/// * [name] title to display on top
/// * [display] the main content to display in the scaffold body
/// * [floaterFunc] to define the function of the floating button
class MyTab {
  final Icon icon;
  final String name;
  final Widget display;
  final void Function(BuildContext)? floaterFunc;

  /// Container to define tab properties
  ///
  /// * [icon] widget to display for the tab
  /// * [name] title to display on top
  /// * [display] the main content to display in the scaffold body
  /// * [floaterFunc] to define the function of the floating button
  const MyTab(this.icon, this.name, this.display, [this.floaterFunc]);
}

final tabNames = [
  MyTab(
    const Icon(Icons.comment),
    "Observations",
    const ObservationsGallary(),
    (BuildContext context) =>
        Navigator.pushNamed(context, MyRoutes.addObservationPageRoute),
  ),
  MyTab(
    const Icon(Ionicons.telescope),
    "Equipment",
    const EquipmentGallery(),
    (BuildContext context) async => await Equipment.addEquipment(context),
  ),
  MyTab(
    const Icon(Icons.library_add_check),
    "Checklist",
    CheckList(),
    CheckList.addCheckListItem,
  ),
  const MyTab(
    Icon(Icons.list),
    "List of Objects",
    ListOfObjects(),
  ),
  // MyTab(
  //   Icon(Icons.photo_camera),
  //   "Settings",
  //   SettingsPage(),
  // ),
  const MyTab(
    Icon(Icons.wb_sunny),
    "Weather Page",
    WeatherPage(),
  ),
  const MyTab(
    Icon(Icons.settings),
    "Settings Page",
    SettingsPage(),
  ),
];

Widget drawer(BuildContext context, StreamController<MyTab> display) {
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        DrawerHeader(
          decoration: BoxDecoration(
            color: Colors.grey[700]!,
          ),
          padding: const EdgeInsets.fromLTRB(5.0, 16.0, 16.0, 0.0),
          child: Image.asset(
              'images/original_files/logo_transparent_background.png',
              height: 100),
        ),
        ListTile(
          leading: const Icon(Icons.account_circle, size: 40),
          title: Text(FirebaseAuth.instance.currentUser!.displayName ??
              "No display name available"),
          subtitle: Text(FirebaseAuth.instance.currentUser!.email ??
              "No public email available"),
        ),
        ...tabNames
            .map(
              (e) => ListTile(
                leading: e.icon,
                title: Text(e.name),
                onTap: () {
                  Navigator.pop(context);
                  display.add(e);
                },
              ),
            )
            .toList(growable: false),
        // const SizedBox.expand(),
        ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Sign Out"),
            onTap: () {
              FirebaseAuth.instance.signOut().then((value) {
                while (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                Navigator.popAndPushNamed(context, MyRoutes.signInPageRoute);
              });
            }),
        FutureBuilder(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) => !snapshot.hasData
              ? const SizedBox()
              : AboutListTile(
                  icon: const Icon(Icons.info),
                  applicationName: snapshot.data!.appName,
                  applicationVersion:
                      'v${snapshot.data!.version}(${snapshot.data!.buildNumber})',
                  applicationIcon: Image.asset('images/logo.png', height: 100),
                  applicationLegalese: '© 2021 Krishna Vedala',
                ),
        ),
      ],
    ),
  );
}
