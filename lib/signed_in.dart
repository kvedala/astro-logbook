import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'drawer.dart';
import 'generated/l10n.dart';
import 'routes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final StreamController<MyTab> _display;

  @override
  void initState() {
    super.initState();
    _display = StreamController<MyTab>();
    _display.add(tabNames[0]);
  }

  @override
  void dispose() {
    _display.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        // Show spinner until Firebase confirms auth state
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        // Redirect to sign-in if not authenticated
        if (authSnap.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.of(context)
                  .pushReplacementNamed(MyRoutes.signInPageRoute);
            }
          });
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(S.current.astronomyLogBook),
          ),
          drawer: drawer(context, _display),
          body: StreamBuilder(
            stream: _display.stream,
            builder: (context, snap) => !snap.hasData
                ? const CircularProgressIndicator()
                : snap.data!.floaterFunc == null
                    ? snap.data!.display
                    : Scaffold(
                        body: snap.data!.display,
                        floatingActionButton: FloatingActionButton(
                          heroTag: "add_${snap.data!.name}",
                          child: const Icon(Icons.add_rounded),
                          onPressed: () => snap.data!.floaterFunc!(context),
                        ),
                      ),
          ),
        );
      },
    );
  }
}
