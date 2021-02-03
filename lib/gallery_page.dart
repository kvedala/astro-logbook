import 'package:astro_log/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GallaryPage extends StatelessWidget {
  final User _user;

  GallaryPage() : _user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_user.displayName + " - Gallary"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add_circle),
        onPressed: () => Navigator.pushNamed(context, AddObservationPageRoute),
      ),
    );
  }
}
