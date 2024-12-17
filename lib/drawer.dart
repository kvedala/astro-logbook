import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'checklist.dart';
import 'equipment.dart';
import 'equipment_gallery.dart';
import 'generated/l10n.dart';
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
  final String Function(BuildContext) name;
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
    (context) => S.current.observations,
    const ObservationsGallary(),
    (BuildContext context) =>
        Navigator.pushNamed(context, MyRoutes.addObservationPageRoute),
  ),
  MyTab(
    const Icon(Ionicons.telescope),
    (context) => S.current.equipment,
    const EquipmentGallery(),
    (BuildContext context) async => await Equipment.addEquipment(context),
  ),
  MyTab(
    const Icon(Icons.library_add_check),
    (context) => S.current.checklist,
    CheckList(),
    CheckList.addCheckListItem,
  ),
  MyTab(
    const Icon(Icons.list),
    (context) => S.current.listOfObjects,
    const ListOfObjects(),
  ),
  // MyTab(
  //   Icon(Icons.photo_camera),
  //   "Settings",
  //   SettingsPage(),
  // ),
  MyTab(
    const Icon(Icons.wb_sunny),
    (context) => S.current.weatherPage,
    const WeatherPage(),
  ),
  MyTab(
    const Icon(Icons.settings),
    (context) => S.current.settingsPage,
    const SettingsPage(),
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
              S.current.noDisplayNameAvailable),
          subtitle: Text(FirebaseAuth.instance.currentUser!.email ??
              S.current.noPublicEmailAvailable),
        ),
        ...tabNames.map(
          (e) => ListTile(
            leading: e.icon,
            title: Text(e.name(context)),
            onTap: () {
              Navigator.pop(context);
              display.add(e);
            },
          ),
        ),
        // const SizedBox.expand(),
        ListTile(
            leading: const Icon(Icons.logout),
            title: Text(S.current.signOut),
            onTap: () {
              FirebaseAuth.instance.signOut().then((value) async {
                while (!context.mounted) {
                  await Future.delayed(const Duration(milliseconds: 100));
                }
                if (!context.mounted) {
                  Exception("Context not mounted");
                  return;
                }
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
