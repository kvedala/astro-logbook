import 'dart:async';

import 'package:flutter/material.dart';
import 'package:location/location.dart' as gps;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WeatherPage extends StatelessWidget {
  const WeatherPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // final loader = StreamController<int>();
    final screen = MediaQuery.of(context).size;

    return Center(
      child:
          // Column(
          //   children: [
          //     Center(
          //       child: StreamBuilder(
          //         stream: loader.stream,
          //         builder: (context, snap) => !snap.hasData || snap.data == 100
          //             ? const SizedBox()
          //             : Column(
          //                 children: [
          //                   LinearProgressIndicator(value: snap.data! / 100),
          //                   Text('Loading: ${snap.data}%'),
          //                 ],
          //               ),
          //       ),
          //     ),
          //     SingleChildScrollView(
          //       child: Expanded(
          //         child:
          InAppWebView(
        initialFile: 'assets/astrospheric.html',
        onLoadStop: (controller, url) => getCurrentPosition.then(
          (position) async {
            await controller.callAsyncJavaScript(functionBody: """
const d = document.getElementById('AstrosphericContainer');
${screen.width > screen.height ? "d.style.width = '' + width + ' px'; d.style.height = '100%'" : "d.style.width = '100%'; d.style.height = '' + height + ' px"};
console.log(d.style);"
""", arguments: {'width': screen.width, 'height': screen.height});
            await controller.evaluateJavascript(
                source: 'm_AstrosphericEmbed.Create("AstrosphericContainer", '
                    '${position.latitude}, ${position.longitude});');
          },
        ),
        onConsoleMessage: (controller, consoleMessage) =>
            debugPrint(consoleMessage.message),
        initialSettings: InAppWebViewSettings(
          // useShouldOverrideUrlLoading: true,
          allowsInlineMediaPlayback: true,
          sharedCookiesEnabled: true,
          transparentBackground: true,
          verticalScrollBarEnabled: true,
          verticalScrollbarPosition:
              VerticalScrollbarPosition.SCROLLBAR_POSITION_RIGHT,

          applicationNameForUserAgent:
              'Astronomy Logbook (https://github.com/kvedala/astro-logbook)',
        ),
        // onProgressChanged: (controller, progress) => loader.add(progress),
      ),
      //     ),
      //   ),
      // ],
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
