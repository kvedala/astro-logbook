import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'observations_gallery_page.dart';

class SignedInPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
