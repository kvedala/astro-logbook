import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'observations_gallery_page.dart';

class SignedInPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(FirebaseAuth.instance.currentUser.displayName),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(child: ObservationsGallary()),
          Expanded(child: PhotographyGallary()),
        ],
      ),
    );
  }
}
