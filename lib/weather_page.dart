import 'dart:async';

import 'package:flutter/material.dart';
import 'package:location/location.dart' as gps;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WeatherPage extends StatelessWidget {
  const WeatherPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loader = StreamController<int>();
    return Stack(
      children: [
        Center(
          child: StreamBuilder(
            stream: loader.stream,
            builder: (context, snap) => !snap.hasData || snap.data == 100
                ? const SizedBox()
                : Column(
                    children: [
                      LinearProgressIndicator(value: snap.data! / 100),
                      Text('Loading: ${snap.data}%'),
                    ],
                  ),
          ),
        ),
        InAppWebView(
          initialFile: 'assets/astrospheric.html',
          onLoadStop: (controller, url) => getCurrentPosition.then(
            (position) => controller.evaluateJavascript(
                source: 'm_AstrosphericEmbed.Create("AstrosphericContainer", '
                    '${position.latitude}, ${position.longitude});'),
          ),
          initialSettings: InAppWebViewSettings(
            // useShouldOverrideUrlLoading: true,
            allowsInlineMediaPlayback: true,
            sharedCookiesEnabled: true,
            transparentBackground: true,
            applicationNameForUserAgent:
                'Astronomy Logbook (https://github.com/kvedala/astro-logbook)',
          ),
          onProgressChanged: (controller, progress) => loader.add(progress),
        ),
      ],
    );
  }

  /// Get current address from GPS coordinates
  static Future<gps.LocationData> get getCurrentPosition async {
    final location = gps.Location();
    if (!await location.requestService()) {
      return Future.error(Exception('Location service not available.'));
    }

    final permission = await location.requestPermission();
    if (permission == gps.PermissionStatus.granted ||
        permission == gps.PermissionStatus.grantedLimited) {
      return await location.getLocation();
    }

    return Future.error(Exception('Location permission not granted.'));
  }
}
