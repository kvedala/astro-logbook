import 'package:astro_log/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'sign_in.dart';
import 'observations_gallery_page.dart';

/// Page to display after signing in
class SignedInPage extends StatefulWidget {
  _SignedInPageState createState() => _SignedInPageState();
}

class _SignedInPageState extends State<SignedInPage>
    with SingleTickerProviderStateMixin {
  TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
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
        title: Text(FirebaseAuth.instance.currentUser.displayName),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Text(
                "Observations",
                style: TextStyle(fontSize: 18),
              ),
            ),
            Tab(
              child: Text(
                "Photography",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
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
        children: [
          ObservationsGallary(),
          PhotographyGallary(),
        ],
      ),
      floatingActionButton: _bottomButtons(context),
    );
  }

  Widget _bottomButtons(BuildContext context) {
    return _tabController.index == 0
        ? FloatingActionButton(
            heroTag: "add_observation",
            child: Icon(Icons.add_rounded),
            onPressed: () =>
                Navigator.pushNamed(context, AddObservationPageRoute),
          )
        : FloatingActionButton(
            shape: StadiumBorder(),
            onPressed: null,
            backgroundColor: Colors.redAccent,
            child: Icon(
              Icons.edit,
              size: 20.0,
            ),
          );
  }
}
