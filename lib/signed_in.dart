import 'package:astro_log/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'sign_in.dart';
import 'observations_gallery_page.dart';

/// Page to display after signing in
class SignedInPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      // user not logged in
      Navigator.popAndPushNamed(context, SignInPageRoute);
      // return null;
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(FirebaseAuth.instance.currentUser.displayName),
          centerTitle: true,
          bottom: TabBar(tabs: [
            Text(
              "Observations",
              style: TextStyle(fontSize: 18),
            ),
            Text(
              "Photography",
              style: TextStyle(fontSize: 18),
            ),
          ]),
          actions: [
            IconButton(
                icon: Icon(Icons.logout),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (googleSignIn != null) {
                    if (await googleSignIn.isSignedIn())
                      await googleSignIn.signOut();
                  }
                  Navigator.pushNamedAndRemoveUntil(
                      context, SignInPageRoute, (route) => false);
                })
          ],
        ),
        body: TabBarView(
          children: [
            ObservationsGallary(),
            PhotographyGallary(),
          ],
        ),
      ),
    );
  }
}
