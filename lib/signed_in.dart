import 'dart:async';

import 'package:flutter/material.dart';

import 'drawer.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final display = StreamController<MyTab>();
    display.add(tabNames[0]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Astronomy Log Book'),
      ),
      drawer: drawer(context, display),
      body: StreamBuilder(
        stream: display.stream,
        builder: (context, snap) => !snap.hasData
            ? const CircularProgressIndicator()
            : Scaffold(
                body: snap.data!.display,
                floatingActionButton: snap.data!.floaterFunc == null
                    ? null
                    : FloatingActionButton(
                        heroTag: "add_${snap.data!.name}",
                        child: const Icon(Icons.add_rounded),
                        onPressed: () => snap.data!.floaterFunc!(context),
                      ),
              ),
      ),
    );
  }
}
