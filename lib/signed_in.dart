import 'package:astro_log/equipment.dart';
import 'package:astro_log/equipment_gallery.dart';
import 'package:astro_log/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'checklist.dart';
import 'sign_in.dart';
import 'observations_gallery_page.dart';

/// Page to display after signing in
class SignedInPage extends StatefulWidget {
  _SignedInPageState createState() => _SignedInPageState();
}

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
  final void Function(BuildContext) floaterFunc;

  /// Container to define tab properties
  ///
  /// * [icon] widget to display for the tab
  /// * [name] title to display on top
  /// * [display] the main content to display in the scaffold body
  /// * [floaterFunc] to define the function of the floating button
  MyTab(this.icon, this.name, this.display, this.floaterFunc);
}

class _SignedInPageState extends State<SignedInPage>
    with SingleTickerProviderStateMixin {
  TabController _tabController;

  static final tabNames = [
    MyTab(
        Icon(Icons.comment),
        "Observations",
        ObservationsGallary(),
        (BuildContext context) =>
            Navigator.pushNamed(context, AddObservationPageRoute)),
    MyTab(
      Icon(Icons.settings_outlined),
      "Equipment",
      EquipmentGallery(),
      (BuildContext context) async => await Equipment.addEquipment(context),
    ),
    MyTab(Icon(Icons.library_add_check), "Checklist", CheckList(),
        CheckList.addCheckListItem),
    MyTab(Icon(Icons.photo_camera), "Photography", PhotographyGallary(),
        (BuildContext context) {}),
  ];

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: tabNames.length, vsync: this, initialIndex: 0);
    _tabController.addListener(_handleTabIndex);
    SystemChrome.setEnabledSystemUIOverlays([]);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    _tabController.removeListener(_handleTabIndex);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabIndex() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      // user not logged in
      Navigator.popAndPushNamed(context, SignInPageRoute);
      // return null;
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(children: [
          Text(FirebaseAuth.instance.currentUser.displayName),
          Text(
            tabNames[_tabController.index].name,
            style: TextStyle(fontSize: 18),
          ),
        ]),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: tabNames
              .map(
                (tab) => Tab(
                  // child: Text(tab.name),
                  child: tab.icon,
                ),
              )
              .toList(),
        ),
        actions: [
          IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (googleSignIn != null) {
                  if (await googleSignIn.isSignedIn())
                    await googleSignIn.signOut();
                }
                Navigator.popAndPushNamed(context, SignInPageRoute);
              })
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: tabNames
            .map(
              (tab) => tab.display,
            )
            .toList(),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "add_${tabNames[_tabController.index].name}",
        child: Icon(Icons.add_rounded),
        onPressed: () => tabNames[_tabController.index].floaterFunc(context),
      ),
    );
  }
}
