import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'equipment.dart';
import 'equipment_gallery.dart';
import 'list_of_objects.dart';
import 'routes.dart';
import 'checklist.dart';
import 'sign_in.dart';
import 'observations_gallery_page.dart';

/// Page to display after signing in
class SignedInPage extends StatefulWidget {
  SignedInPage({Key? key}) : super(key: key);
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
  final void Function(BuildContext)? floaterFunc;

  /// Container to define tab properties
  ///
  /// * [icon] widget to display for the tab
  /// * [name] title to display on top
  /// * [display] the main content to display in the scaffold body
  /// * [floaterFunc] to define the function of the floating button
  MyTab(this.icon, this.name, this.display, [this.floaterFunc]);
}

class _SignedInPageState extends State<SignedInPage>
    with SingleTickerProviderStateMixin, RouteAware {
  TabController? _tabController;

  static final tabNames = [
    MyTab(
      Icon(Icons.comment),
      "Observations",
      ObservationsGallary(),
      (BuildContext context) =>
          Navigator.pushNamed(context, AddObservationPageRoute),
    ),
    MyTab(
      Icon(Icons.settings_outlined),
      "Equipment",
      EquipmentGallery(),
      (BuildContext context) async => await Equipment.addEquipment(context),
    ),
    MyTab(
      Icon(Icons.library_add_check),
      "Checklist",
      CheckList(),
      CheckList.addCheckListItem,
    ),
    MyTab(
      Icon(Icons.list),
      "List of Objects",
      ListOfObjects(),
    ),
    MyTab(
      Icon(Icons.photo_camera),
      "Photography",
      PhotographyGallary(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: tabNames.length, vsync: this, initialIndex: 0);
    _tabController!.addListener(_handleTabIndex);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    _tabController!.removeListener(_handleTabIndex);
    _tabController!.dispose();
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

    FirebaseAnalytics.instance.logLogin();
    FirebaseAnalytics.instance.setUserProperty(
        name: "Name", value: FirebaseAuth.instance.currentUser!.displayName);
    FirebaseAnalytics.instance.setUserProperty(
        name: "Email", value: FirebaseAuth.instance.currentUser!.email);
    FirebaseAnalytics.instance
        .setUserId(id: FirebaseAuth.instance.currentUser!.uid);

    // ListOfObjects.saveMessierObjects();
    // ListOfObjects.saveNGCObjects();

    return Scaffold(
      appBar: AppBar(
        title: Column(children: [
          Text(FirebaseAuth.instance.currentUser!.displayName!),
          Text(
            tabNames[_tabController!.index].name,
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
              color: Colors.red,
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (googleSignIn != null) {
                  if (await googleSignIn!.isSignedIn())
                    await googleSignIn!.signOut();
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
      floatingActionButton: tabNames[_tabController!.index].floaterFunc == null
          ? null
          : FloatingActionButton(
              heroTag: "add_${tabNames[_tabController!.index].name}",
              child: Icon(Icons.add_rounded),
              onPressed: () =>
                  tabNames[_tabController!.index].floaterFunc!(context),
            ),
    );
  }
}
