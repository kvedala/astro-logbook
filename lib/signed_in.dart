import 'dart:async';

import 'package:flutter/material.dart';

import 'drawer.dart';
import 'generated/l10n.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final display = StreamController<MyTab>();
    display.add(tabNames[0]);

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).astronomyLogBook),
      ),
      drawer: drawer(context, display),
      body: StreamBuilder(
        stream: display.stream,
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
  }
}
