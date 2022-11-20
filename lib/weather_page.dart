import 'package:flutter/material.dart';
import 'package:location/location.dart' as gps;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WeatherPage extends StatelessWidget {
  const WeatherPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder(
        future: getCurrentPosition(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          return InAppWebView(
            initialFile: 'assets/astrospheric.html',
            onLoadStop: (controller, url) async {
              await controller.evaluateJavascript(
                  source:
                      'm_AstrosphericEmbed.Create("AstrosphericContainer", ${snapshot.data!.latitude}, ${snapshot.data!.longitude});');
            },
            initialSettings: InAppWebViewSettings(
              useShouldOverrideUrlLoading: true,
              allowsInlineMediaPlayback: true,
              sharedCookiesEnabled: true,
              userAgent:
                  'Astronomy Logbook (https://github.com/kvedala/astro-logbook)',
            ),
          );
        },
      ),
    );
  }

  /// Get current address from GPS coordinates
  static Future<gps.LocationData> getCurrentPosition() async {
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
